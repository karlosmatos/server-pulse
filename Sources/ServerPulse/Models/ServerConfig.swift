import Foundation

struct ServerConfig: Codable, Identifiable, Sendable {
    var id: UUID
    var name: String

    // SSH
    var sshHost: String
    var sshUser: String
    var sshKeyPath: String
    var sshPort: Int

    // n8n
    var n8nBaseURL: String
    var n8nAPIKey: String

    // Monitoring
    var pollingInterval: Double
    var processCount: Int
    var processFilter: String
    var dockerEnabled: Bool
    var systemdServices: String

    var resolvedKeyPath: String {
        let path = sshKeyPath.isEmpty ? "~/.ssh/id_ed25519" : sshKeyPath
        return path.hasPrefix("~")
            ? (path as NSString).expandingTildeInPath
            : path
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        sshHost: String = "",
        sshUser: String = "",
        sshKeyPath: String = "",
        sshPort: Int = 22,
        n8nBaseURL: String = "",
        n8nAPIKey: String = "",
        pollingInterval: Double = 30.0,
        processCount: Int = 10,
        processFilter: String = "",
        dockerEnabled: Bool = false,
        systemdServices: String = ""
    ) {
        self.id = id
        self.name = name
        self.sshHost = sshHost
        self.sshUser = sshUser
        self.sshKeyPath = sshKeyPath
        self.sshPort = sshPort
        self.n8nBaseURL = n8nBaseURL
        self.n8nAPIKey = n8nAPIKey
        self.pollingInterval = pollingInterval
        self.processCount = processCount
        self.processFilter = processFilter
        self.dockerEnabled = dockerEnabled
        self.systemdServices = systemdServices
    }
}
