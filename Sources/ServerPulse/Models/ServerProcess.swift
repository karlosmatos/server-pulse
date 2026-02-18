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
        var i = idx + 1
        guard i < parts.count else { return "python" }

        // Handle "python -m module_name [args]"
        if parts[i] == "-m", i + 1 < parts.count {
            i += 1
            let moduleName = parts[i]
            // For runners like uvicorn/gunicorn, append the app argument
            if i + 1 < parts.count, ["uvicorn", "gunicorn", "celery"].contains(moduleName) {
                return "\(moduleName) \(parts[i + 1])"
            }
            return moduleName
        }

        return (parts[i] as NSString).lastPathComponent
    }
}
