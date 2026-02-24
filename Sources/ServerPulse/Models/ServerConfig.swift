import Foundation

struct ServerConfig: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var name: String = ""

    // SSH
    var sshHost: String = ""
    var sshUser: String = ""
    var sshKeyPath: String = ""
    var sshPort: Int = 22

    // n8n
    var n8nBaseURL: String = ""
    var n8nAPIKey: String = ""

    // Monitoring
    var pollingInterval: Double = 30.0
    var processCount: Int = 10
    var processFilter: String = ""
    var dockerEnabled: Bool = false
    var systemdServices: String = ""

    var resolvedKeyPath: String {
        let path = sshKeyPath.isEmpty ? "~/.ssh/id_ed25519" : sshKeyPath
        return path.hasPrefix("~") ? (path as NSString).expandingTildeInPath : path
    }
}
