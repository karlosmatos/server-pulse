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

    // MARK: - Process Command Builder

    static func processCommand(count: Int, filter: String) -> String {
        let sanitized = filter.unicodeScalars.filter {
            CharacterSet.alphanumerics.contains($0) || CharacterSet(charactersIn: "-_.").contains($0)
        }
        let clean = String(sanitized)

        if clean.isEmpty {
            return "ps aux --sort=-%cpu | tail -n +2 | head -\(max(1, min(count, 50)))"
        } else {
            return "ps aux | grep -iF '\(clean)' | grep -v grep"
        }
    }

    // MARK: - Docker Parsing

    static func parseDockerOutput(from output: String) -> [DockerContainer] {
        let sections = output.components(separatedBy: "---")
        guard sections.count >= 2 else { return [] }

        // Parse `docker ps`: ID|NAME|IMAGE|STATUS
        var psInfo: [(id: String, name: String, image: String, status: String)] = []
        for line in sections[0].components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let cols = trimmed.components(separatedBy: "|")
            guard cols.count >= 4 else { continue }
            psInfo.append((
                id: cols[0].trimmingCharacters(in: .whitespaces),
                name: cols[1].trimmingCharacters(in: .whitespaces),
                image: cols[2].trimmingCharacters(in: .whitespaces),
                status: cols[3].trimmingCharacters(in: .whitespaces)
            ))
        }

        // Parse `docker stats`: ID|CPU%|MEM%|MEMUSAGE
        var statsMap: [String: (cpu: Double, mem: Double, memUsage: String)] = [:]
        for line in sections[1].components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let cols = trimmed.components(separatedBy: "|")
            guard cols.count >= 4 else { continue }
            let id = cols[0].trimmingCharacters(in: .whitespaces)
            statsMap[id] = (
                cpu: Double(cols[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "%", with: "")) ?? 0,
                mem: Double(cols[2].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "%", with: "")) ?? 0,
                memUsage: cols[3].trimmingCharacters(in: .whitespaces)
            )
        }

        return psInfo.map { info in
            let stats = statsMap[info.id]
            return DockerContainer(
                id: info.id,
                name: info.name,
                image: info.image,
                status: info.status,
                cpuPercent: stats?.cpu ?? 0,
                memPercent: stats?.mem ?? 0,
                memUsage: stats?.memUsage ?? ""
            )
        }
    }

    // MARK: - Systemd Parsing

    static func systemdCommand(services: String) -> String? {
        let names = services.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .filter { name in
                name.unicodeScalars.allSatisfy {
                    CharacterSet.alphanumerics.contains($0) || CharacterSet(charactersIn: "-_.@").contains($0)
                }
            }
        guard !names.isEmpty else { return nil }
        let list = names.joined(separator: " ")
        return "for s in \(list); do echo \"$s:$(systemctl is-active $s)\"; done"
    }

    static func parseSystemdServices(from output: String) -> [SystemdService] {
        output.components(separatedBy: "\n").compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            let parts = trimmed.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { return nil }
            let name = String(parts[0])
            let stateRaw = String(parts[1]).trimmingCharacters(in: .whitespaces)
            let state: SystemdService.State = switch stateRaw {
            case "active":   .active
            case "inactive": .inactive
            case "failed":   .failed
            default:         .unknown
            }
            return SystemdService(id: name, name: name, state: state)
        }
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
