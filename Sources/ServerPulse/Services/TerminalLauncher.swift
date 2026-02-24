import Foundation
import AppKit

enum TerminalLauncher {
    static func openSSH(config: ServerConfig, terminalApp: String) {
        guard !config.sshHost.isEmpty, !config.sshUser.isEmpty else { return }

        // Build args with each component shell-quoted so special characters in
        // the host/username/key path cannot inject commands into the bash script.
        var args = ["ssh", "-i", shellQuote(config.resolvedKeyPath)]
        if config.sshPort != 22 { args += ["-p", String(config.sshPort)] }
        args.append(shellQuote("\(config.sshUser)@\(config.sshHost)"))

        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("serverpulse-ssh-\(UUID().uuidString).command")

        do {
            try "#!/bin/bash\n\(args.joined(separator: " "))\n"
                .write(to: scriptURL, atomically: true, encoding: .utf8)
            // 0o700: owner-only — no other user should read or execute this script
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o700], ofItemAtPath: scriptURL.path)
        } catch { return }

        switch terminalApp.lowercased() {
        case "iterm", "iterm2":
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.googlecode.iterm2") {
                let cfg = NSWorkspace.OpenConfiguration()
                cfg.activates = true
                NSWorkspace.shared.open([scriptURL], withApplicationAt: appURL, configuration: cfg)
            } else {
                NSWorkspace.shared.open(scriptURL)
            }
        default:
            NSWorkspace.shared.open(scriptURL)
        }
    }

    /// Wraps a string in single quotes and escapes any embedded single quotes.
    private static func shellQuote(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
