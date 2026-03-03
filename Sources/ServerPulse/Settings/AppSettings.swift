import Foundation
import ServiceManagement

protocol KeychainStoring {
    @discardableResult
    func set(_ value: String, account: String) -> Bool

    @discardableResult
    func delete(account: String) -> Bool

    func get(account: String) -> String?
}

struct SystemKeychainStore: KeychainStoring {
    @discardableResult
    func set(_ value: String, account: String) -> Bool {
        KeychainHelper.set(value, account: account)
    }

    @discardableResult
    func delete(account: String) -> Bool {
        KeychainHelper.delete(account: account)
    }

    func get(account: String) -> String? {
        KeychainHelper.get(account: account)
    }
}

final class AppSettings {
    private let userDefaults: UserDefaults
    private let keychain: any KeychainStoring
    private var cachedServers: [ServerConfig]?

    init(userDefaults: UserDefaults = .standard, keychain: any KeychainStoring = SystemKeychainStore()) {
        self.userDefaults = userDefaults
        self.keychain = keychain
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

        var configs = (try? JSONDecoder().decode([ServerConfig].self, from: data)) ?? []
        migrateLegacyN8NKeysIfNeeded(&configs)
        cachedServers = configs
        return configs
    }

    @discardableResult
    func saveServers(_ newValue: [ServerConfig]) -> Bool {
        let previous = cachedServers ?? loadServers()
        let previousIDs = Set(previous.map(\.id))
        let newIDs = Set(newValue.map(\.id))

        for removedID in previousIDs.subtracting(newIDs) {
            _ = keychain.delete(account: removedID.uuidString)
        }

        for server in newValue {
            if !keychain.set(server.n8nAPIKey, account: server.id.uuidString) {
                print("Failed to persist n8n API key for server: \(server.id.uuidString)")
                return false
            }
        }

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

    private func migrateLegacyN8NKeysIfNeeded(_ configs: inout [ServerConfig]) {
        var needsResave = false

        for i in configs.indices {
            let account = configs[i].id.uuidString
            if let keychainKey = keychain.get(account: account), !keychainKey.isEmpty {
                configs[i].n8nAPIKey = keychainKey
                continue
            }

            let legacyKey = configs[i].n8nAPIKey
            if !legacyKey.isEmpty {
                if keychain.set(legacyKey, account: account) {
                    needsResave = true
                    configs[i].n8nAPIKey = legacyKey
                }
                continue
            }

            configs[i].n8nAPIKey = ""
        }

        if needsResave, let clean = try? JSONEncoder().encode(configs) {
            userDefaults.set(clean, forKey: "servers.list")
        }
    }
}
