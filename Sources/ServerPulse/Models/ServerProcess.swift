import Foundation

struct ServerProcess: Identifiable {
    let id: Int         // PID
    let user: String
    let cpuPercent: Double
    let memPercent: Double
    let command: String

    private static let interpreters: Set<String> = ["python", "python3", "node", "ruby", "perl", "java", "php"]

    var displayName: String {
        let parts = command.components(separatedBy: " ").filter { !$0.isEmpty }
        guard let first = parts.first else { return command }

        let binary = (first as NSString).lastPathComponent.lowercased()

        // For interpreters, show binary + script/module argument
        if Self.interpreters.contains(binary) {
            let next = 1
            guard next < parts.count else { return binary }

            // Handle python -m module
            if parts[next] == "-m", next + 1 < parts.count {
                return parts[next + 1]
            }
            // Skip flags (start with -)
            if let argIdx = parts.dropFirst().firstIndex(where: { !$0.hasPrefix("-") }) {
                return (parts[argIdx] as NSString).lastPathComponent
            }
            return binary
        }

        return (first as NSString).lastPathComponent
    }
}
