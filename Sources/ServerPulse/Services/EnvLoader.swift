import Foundation

enum EnvLoader {

    /// Reads a .env file and populates UserDefaults for any keys not already set.
    /// Searches: ~/.config/serverpulse/.env, then CWD/.env
    static func loadIfNeeded() {
        guard let path = locateEnvFile() else { return }
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else { return }

        let mapping: [String: String] = [
            "SSH_HOST":      "ssh.host",
            "SSH_USER":      "ssh.user",
            "SSH_KEY_PATH":  "ssh.keyPath",
            "SSH_PORT":      "ssh.port",
            "N8N_BASE_URL":  "n8n.baseURL",
            "N8N_API_KEY":   "n8n.apiKey",
            "POLL_INTERVAL": "poll.interval",
        ]

        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
            let parts = trimmed.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }

            let envKey = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let value  = String(parts[1]).trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))

            guard let udKey = mapping[envKey] else { continue }

            // Only set if UserDefaults doesn't already have a value
            if UserDefaults.standard.object(forKey: udKey) == nil {
                if udKey == "ssh.port" {
                    UserDefaults.standard.set(Int(value) ?? 22, forKey: udKey)
                } else if udKey == "poll.interval" {
                    UserDefaults.standard.set(Double(value) ?? 30.0, forKey: udKey)
                } else {
                    UserDefaults.standard.set(value, forKey: udKey)
                }
            }
        }
    }

    private static func locateEnvFile() -> String? {
        let candidates = [
            NSString("~/.config/serverpulse/.env").expandingTildeInPath,
            FileManager.default.currentDirectoryPath + "/.env",
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0) }
    }
}
