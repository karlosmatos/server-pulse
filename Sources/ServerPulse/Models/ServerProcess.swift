import Foundation

struct ServerProcess: Identifiable {
    let id: Int         // PID
    let user: String
    let cpuPercent: Double
    let memPercent: Double
    let command: String

    var displayName: String {
        let parts = command.components(separatedBy: " ")
        guard let idx = parts.firstIndex(where: { $0.lowercased().contains("python") }) else {
            return parts.last ?? command
        }
        let next = idx + 1
        guard next < parts.count else { return "python" }

        if parts[next] == "-m", next + 1 < parts.count {
            let module = parts[next + 1]
            let hasAppArg = next + 2 < parts.count && ["uvicorn", "gunicorn", "celery"].contains(module)
            return hasAppArg ? "\(module) \(parts[next + 2])" : module
        }
        return (parts[next] as NSString).lastPathComponent
    }
}
