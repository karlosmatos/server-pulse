import Foundation
import ServiceManagement

final class AppSettings {
    private let userDefaults: UserDefaults
    private var cachedServers: [ServerConfig]?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // Global (not per-server)
    var terminalApp: String {
        get { userDefaults.string(forKey: "terminal.app") ?? "terminal" }
        set { userDefaults.set(newValue, forKey: "terminal.app") }
    }

    // MARK: - Server list (JSON in UserDefaults)

    var servers: [ServerConfig] {
        get { loadServers() }
        set { _ = saveServers(newValue) }
    }

    func loadServers() -> [ServerConfig] {
        if let cachedServers {
            return cachedServers
        }

        guard let data = userDefaults.data(forKey: "servers.list") else {
            cachedServers = []
            return []
        }

        let configs = (try? JSONDecoder().decode([ServerConfig].self, from: data)) ?? []
        cachedServers = configs
        return configs
    }

    @discardableResult
    func saveServers(_ newValue: [ServerConfig]) -> Bool {
        guard let data = try? JSONEncoder().encode(newValue) else {
            print("Failed to encode servers list")
            return false
        }

        userDefaults.set(data, forKey: "servers.list")
        cachedServers = newValue
        return true
    }

    var selectedServerID: UUID? {
        get {
            guard let str = userDefaults.string(forKey: "servers.selectedID") else { return nil }
            return UUID(uuidString: str)
        }
        set {
            userDefaults.set(newValue?.uuidString, forKey: "servers.selectedID")
        }
    }

    // MARK: - Launch at Login

    var launchAtLogin: Bool {
        get {
            let status = SMAppService.mainApp.status
            return status == .enabled || status == .requiresApproval
        }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
#if DEBUG
                print("SMAppService \(newValue ? "register" : "unregister") failed: \(error)")
#endif
            }
        }
    }

    // MARK: - Legacy keys (for migration)

    static let legacyKeys = [
        "ssh.host", "ssh.user", "ssh.keyPath", "ssh.port",
        "n8n.baseURL", "n8n.apiKey",
        "poll.interval", "process.count", "process.filter",
        "docker.enabled", "systemd.services",
    ]
}
