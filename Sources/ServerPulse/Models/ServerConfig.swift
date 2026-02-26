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
    /// Not persisted via Codable — stored in Keychain keyed by `id`.
    var n8nAPIKey: String = ""

    // Monitoring
    var pollingInterval: Double
    var processCount: Int
    var processFilter: String
    var dockerEnabled: Bool
    var systemdServices: String

    private enum CodingKeys: String, CodingKey {
        case id, name, sshHost, sshUser, sshKeyPath, sshPort
        case n8nBaseURL, pollingInterval, processCount
        case processFilter, dockerEnabled, systemdServices
        // n8nAPIKey intentionally omitted from encoding — stored in Keychain
    }

    // Custom decoder: reads legacy n8nAPIKey from JSON if present, so
    // data saved by older builds can be migrated to Keychain on first load.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decode(UUID.self,   forKey: .id)
        name             = try c.decode(String.self, forKey: .name)
        sshHost          = try c.decode(String.self, forKey: .sshHost)
        sshUser          = try c.decode(String.self, forKey: .sshUser)
        sshKeyPath       = try c.decode(String.self, forKey: .sshKeyPath)
        sshPort          = try c.decode(Int.self,    forKey: .sshPort)
        n8nBaseURL       = try c.decode(String.self, forKey: .n8nBaseURL)
        pollingInterval  = try c.decode(Double.self, forKey: .pollingInterval)
        processCount     = try c.decode(Int.self,    forKey: .processCount)
        processFilter    = try c.decode(String.self, forKey: .processFilter)
        dockerEnabled    = try c.decode(Bool.self,   forKey: .dockerEnabled)
        systemdServices  = try c.decode(String.self, forKey: .systemdServices)

        // Legacy field — read if present so old data can be migrated to Keychain.
        enum LegacyKey: String, CodingKey { case n8nAPIKey }
        let legacy = try? decoder.container(keyedBy: LegacyKey.self)
        n8nAPIKey = (try? legacy?.decodeIfPresent(String.self, forKey: .n8nAPIKey)) ?? ""
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
