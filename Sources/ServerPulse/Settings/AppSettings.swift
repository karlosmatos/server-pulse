import Foundation

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
    @UserDefault(key: "ssh.host",      defaultValue: "")
    var sshHost: String

    @UserDefault(key: "ssh.user",      defaultValue: "")
    var sshUser: String

    @UserDefault(key: "ssh.keyPath",   defaultValue: "")
    var sshKeyPath: String

    @UserDefault(key: "ssh.port",      defaultValue: 22)
    var sshPort: Int

    @UserDefault(key: "n8n.baseURL",   defaultValue: "")
    var n8nBaseURL: String

    @UserDefault(key: "n8n.apiKey",    defaultValue: "")
    var n8nAPIKey: String

    @UserDefault(key: "poll.interval", defaultValue: 30.0)
    var pollingInterval: Double

    var resolvedKeyPath: String {
        let path = sshKeyPath.isEmpty ? "~/.ssh/id_ed25519" : sshKeyPath
        return path.hasPrefix("~")
            ? (path as NSString).expandingTildeInPath
            : path
    }
}
