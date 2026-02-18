import Foundation

struct ServerProcess: Identifiable {
    let id: Int         // PID
    let user: String
    let cpuPercent: Double
    let memPercent: Double
    let command: String

    var displayName: String {
        let parts = command.components(separatedBy: " ")
        // Find the python interpreter and return the next argument (the script)
        if let idx = parts.firstIndex(where: { $0.lowercased().contains("python") }),
           idx + 1 < parts.count {
            return (parts[idx + 1] as NSString).lastPathComponent
        }
        return (parts.first ?? command)
    }
}
