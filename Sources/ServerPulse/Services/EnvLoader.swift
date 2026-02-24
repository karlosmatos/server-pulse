import Foundation

enum EnvLoader {

    /// Reads old per-server UserDefaults keys and returns a ServerConfig if any SSH fields are set.
    /// Removes legacy keys after migration.
    static func migrateLegacyDefaults() -> ServerConfig? {
        let ud = UserDefaults.standard
        let host = ud.string(forKey: "ssh.host") ?? ""
        let user = ud.string(forKey: "ssh.user") ?? ""
        guard !host.isEmpty || !user.isEmpty else {
            // Nothing to migrate — clean up just in case
            cleanLegacyKeys()
            return nil
        }

        let config = ServerConfig(
            name: host.isEmpty ? "My Server" : host,
            sshHost: host,
            sshUser: user,
            sshKeyPath: ud.string(forKey: "ssh.keyPath") ?? "",
            sshPort: ud.object(forKey: "ssh.port") as? Int ?? 22,
            n8nBaseURL: ud.string(forKey: "n8n.baseURL") ?? "",
            n8nAPIKey: ud.string(forKey: "n8n.apiKey") ?? "",
            pollingInterval: ud.object(forKey: "poll.interval") as? Double ?? 30.0,
            processCount: ud.object(forKey: "process.count") as? Int ?? 10,
            processFilter: ud.string(forKey: "process.filter") ?? "",
            dockerEnabled: ud.bool(forKey: "docker.enabled"),
            systemdServices: ud.string(forKey: "systemd.services") ?? ""
        )

        cleanLegacyKeys()
        return config
    }

    /// Reads a .env file and returns a ServerConfig (no UserDefaults writes).
    static func loadFromEnvFile() -> ServerConfig? {
        guard let path = locateEnvFile() else { return nil }
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }

        var values: [String: String] = [:]
        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
            let parts = trimmed.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let val = String(parts[1]).trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            values[key] = val
        }

        let host = values["SSH_HOST"] ?? ""
        guard !host.isEmpty else { return nil }

        // terminal.app is global — write it to UserDefaults if present
        if let terminal = values["TERMINAL_APP"] {
            UserDefaults.standard.set(terminal, forKey: "terminal.app")
        }

        return ServerConfig(
            name: host,
            sshHost: host,
            sshUser: values["SSH_USER"] ?? "",
            sshKeyPath: values["SSH_KEY_PATH"] ?? "",
            sshPort: Int(values["SSH_PORT"] ?? "") ?? 22,
            n8nBaseURL: values["N8N_BASE_URL"] ?? "",
            n8nAPIKey: values["N8N_API_KEY"] ?? "",
            pollingInterval: Double(values["POLL_INTERVAL"] ?? "") ?? 30.0,
            processCount: Int(values["PROCESS_COUNT"] ?? "") ?? 10,
            processFilter: values["PROCESS_FILTER"] ?? "",
            dockerEnabled: values["DOCKER_ENABLED"] == "true" || values["DOCKER_ENABLED"] == "1",
            systemdServices: values["SYSTEMD_SERVICES"] ?? ""
        )
    }

    // MARK: - Private

    private static func locateEnvFile() -> String? {
        let candidates = [
            NSString("~/.config/serverpulse/.env").expandingTildeInPath,
            FileManager.default.currentDirectoryPath + "/.env",
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0) }
    }

    private static func cleanLegacyKeys() {
        for key in AppSettings.legacyKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
