import Foundation

struct ServerConfig: Codable, Identifiable, Sendable {
    var id: UUID
    var name: String

    // SSH
    var sshHost: String
    var sshUser: String
    var sshKeyPath: String
    var sshPort: Int

    // Monitoring
    var pollingInterval: Double
    var processCount: Int
    var processFilter: String
    var dockerEnabled: Bool
    var systemdServices: String

    // Security audit
    var securityAuditEnabled: Bool = true
    var ignoredSecurityChecks: [String] = []

    private enum CodingKeys: String, CodingKey {
        case id, name, sshHost, sshUser, sshKeyPath, sshPort
        case pollingInterval, processCount
        case processFilter, dockerEnabled, systemdServices
        case securityAuditEnabled, ignoredSecurityChecks
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decode(UUID.self,   forKey: .id)
        name             = try c.decode(String.self, forKey: .name)
        sshHost          = try c.decode(String.self, forKey: .sshHost)
        sshUser          = try c.decode(String.self, forKey: .sshUser)
        sshKeyPath       = try c.decode(String.self, forKey: .sshKeyPath)
        sshPort          = try c.decode(Int.self,    forKey: .sshPort)
        pollingInterval  = try c.decode(Double.self, forKey: .pollingInterval)
        processCount     = try c.decode(Int.self,    forKey: .processCount)
        processFilter    = try c.decode(String.self, forKey: .processFilter)
        dockerEnabled    = try c.decode(Bool.self,   forKey: .dockerEnabled)
        systemdServices  = try c.decode(String.self, forKey: .systemdServices)
        securityAuditEnabled = try c.decodeIfPresent(Bool.self, forKey: .securityAuditEnabled) ?? true
        ignoredSecurityChecks = try c.decodeIfPresent([String].self, forKey: .ignoredSecurityChecks) ?? []
    }

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
        self.pollingInterval = pollingInterval
        self.processCount = processCount
        self.processFilter = processFilter
        self.dockerEnabled = dockerEnabled
        self.systemdServices = systemdServices
    }
}
