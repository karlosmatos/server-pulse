import Foundation
import ServiceManagement

@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T

    var wrappedValue: T {
        get { UserDefaults.standard.object(forKey: key) as? T ?? defaultValue }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

final class AppSettings: @unchecked Sendable {
    // Global (not per-server)
    @UserDefault(key: "terminal.app", defaultValue: "terminal")
    var terminalApp: String

    // MARK: - Server list (JSON in UserDefaults)

    var servers: [ServerConfig] {
        get {
            guard let data = UserDefaults.standard.data(forKey: "servers.list") else { return [] }
            return (try? JSONDecoder().decode([ServerConfig].self, from: data)) ?? []
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            UserDefaults.standard.set(data, forKey: "servers.list")
        }
    }

    var selectedServerID: UUID? {
        get {
            guard let str = UserDefaults.standard.string(forKey: "servers.selectedID") else { return nil }
            return UUID(uuidString: str)
        }
        set {
            UserDefaults.standard.set(newValue?.uuidString, forKey: "servers.selectedID")
        }
    }

    // MARK: - Launch at Login

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Silently ignore — can fail if app isn't in /Applications
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
