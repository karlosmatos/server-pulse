import Foundation

enum SSHCommandParser {

    static func parseCPU(from output: String) -> Double? {
        let line = output.trimmingCharacters(in: .whitespacesAndNewlines)

        if let idle = extractNumber(from: line, matching: #"(\d+[.,]\d+)\s*id"#) {
            return max(0, min(100, 100 - idle))
        }

        let total = ["us", "sy"].compactMap { extractNumber(from: line, matching: #"(\d+[.,]\d+)\s*\#($0)"#) }.reduce(0, +)
        return total > 0 ? min(total, 100) : nil
    }

    static func parseRAM(from output: String) -> (used: Int, total: Int)? {
        let parts = nonEmptyParts(output)
        guard parts.count >= 3, let total = Int(parts[1]), let used = Int(parts[2]) else { return nil }
        return (used, total)
    }

    static func parseDisk(from output: String) -> (used: String, total: String, percent: Double)? {
        let parts = nonEmptyParts(output)
        guard parts.count >= 5 else { return nil }
        return (parts[2], parts[1], Double(parts[4].replacingOccurrences(of: "%", with: "")) ?? 0)
    }

    static func parseProcesses(from output: String) -> [ServerProcess] {
        output.components(separatedBy: "\n").filter { !$0.isEmpty }.compactMap { line in
            let p = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard p.count >= 11, let pid = Int(p[1]), let cpu = Double(p[2]), let mem = Double(p[3]) else { return nil }
            return ServerProcess(id: pid, user: p[0], cpuPercent: cpu, memPercent: mem, command: p[10...].joined(separator: " "))
        }
    }

    static func parseUptime(from output: String) -> String {
        let line = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let r = line.range(of: #"up\s+[\w ,:]+"#, options: .regularExpression) else { return "Unknown" }
        let raw = String(line[r])
        if let userRange = raw.range(of: #",\s+\d+\s+user"#, options: .regularExpression) {
            return String(raw[..<userRange.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        return raw.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Helpers

    private static func extractNumber(from text: String, matching pattern: String) -> Double? {
        guard let range = text.range(of: pattern, options: .regularExpression) else { return nil }
        let raw = String(text[range]).replacingOccurrences(of: ",", with: ".")
        let digits = raw.unicodeScalars.filter { CharacterSet(charactersIn: "0123456789.").contains($0) }
        return Double(String(digits))
    }

    private static func nonEmptyParts(_ text: String) -> [String] {
        text.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    }
}
