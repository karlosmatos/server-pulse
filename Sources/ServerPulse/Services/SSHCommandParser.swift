import Foundation

enum SSHCommandParser {

    // Input: "top -bn1 | grep 'Cpu(s)'" output
    // Example: "%Cpu(s):  3.2 us,  0.8 sy,  0.0 ni, 95.5 id, ..."
    static func parseCPU(from output: String) -> Double? {
        let line = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // Preferred: subtract idle from 100
        if let range = line.range(of: #"(\d+[.,]\d+)\s*id"#, options: .regularExpression) {
            let raw = String(line[range])
                .replacingOccurrences(of: ",", with: ".")
            if let idVal = Double(raw.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()) {
                return max(0, min(100, 100 - idVal))
            }
        }

        // Fallback: us + sy
        var total = 0.0
        for pattern in [#"(\d+[.,]\d+)\s*us"#, #"(\d+[.,]\d+)\s*sy"#] {
            if let range = line.range(of: pattern, options: .regularExpression) {
                let raw = String(line[range])
                    .replacingOccurrences(of: ",", with: ".")
                if let val = Double(raw.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()) {
                    total += val
                }
            }
        }
        return total > 0 ? min(total, 100) : nil
    }

    // Input: "free -m | grep '^Mem'" output
    // Example: "Mem:           7820        2341        1234          88        2245        5157"
    static func parseRAM(from output: String) -> (used: Int, total: Int)? {
        let parts = output.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        // Mem: total used free shared buff/cache available
        guard parts.count >= 3,
              let total = Int(parts[1]),
              let used = Int(parts[2]) else { return nil }
        return (used, total)
    }

    // Input: "df -h / | tail -1" output
    // Example: "/dev/sda1        50G   12G   38G  24% /"
    static func parseDisk(from output: String) -> (used: String, total: String, percent: Double)? {
        let parts = output.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        // filesystem size used avail use% mountpoint
        guard parts.count >= 5 else { return nil }
        let total = parts[1]
        let used = parts[2]
        let percent = Double(parts[4].replacingOccurrences(of: "%", with: "")) ?? 0
        return (used, total, percent)
    }

    // Input: "ps aux | grep -i python | grep -v grep" output
    static func parseProcesses(from output: String) -> [ServerProcess] {
        output.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .compactMap { line -> ServerProcess? in
                let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                guard parts.count >= 11,
                      let pid = Int(parts[1]),
                      let cpu = Double(parts[2]),
                      let mem = Double(parts[3]) else { return nil }
                let command = parts[10...].joined(separator: " ")
                return ServerProcess(id: pid, user: parts[0], cpuPercent: cpu, memPercent: mem, command: command)
            }
    }

    // Input: "uptime" output
    // Example: " 14:23:45 up 12 days,  3:21,  1 user,  load average: 0.15, 0.12, 0.10"
    static func parseUptime(from output: String) -> String {
        let line = output.trimmingCharacters(in: .whitespacesAndNewlines)
        // Grab "up X days, H:MM" or "up X min"
        if let r = line.range(of: #"up\s+[\w ,:]+"#, options: .regularExpression) {
            let raw = String(line[r])
            // Trim trailing ", N user" portion
            if let userRange = raw.range(of: #",\s+\d+\s+user"#, options: .regularExpression) {
                return String(raw[..<userRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            }
            return raw.trimmingCharacters(in: .whitespaces)
        }
        return "Unknown"
    }
}
