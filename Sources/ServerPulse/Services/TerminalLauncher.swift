import Foundation
import AppKit

enum TerminalLauncher {
    static func openSSH(config: ServerConfig, terminalApp: String) {
        guard !config.sshHost.isEmpty, !config.sshUser.isEmpty else { return }

        var parts = ["ssh"]
        parts.append("-i '\(config.resolvedKeyPath)'")
        if config.sshPort != 22 {
            parts.append("-p \(config.sshPort)")
        }
        parts.append("\(config.sshUser)@\(config.sshHost)")

        let sshCommand = parts.joined(separator: " ")

        // Write a temporary .command file and open it — no AppleScript/Automation
        // permission needed; Terminal.app (and iTerm2) open .command files natively.
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("serverpulse-ssh-\(UUID().uuidString).command")

        do {
            try "#!/bin/bash\n\(sshCommand)\n"
                .write(to: scriptURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
        } catch {
            return
        }

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
}
