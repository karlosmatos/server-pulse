import Foundation
import AppKit

enum TerminalLauncher {
    static func openSSH(config: ServerConfig, terminalApp: String) {
        guard !config.sshHost.isEmpty, !config.sshUser.isEmpty else { return }
        guard let scriptDirectory = prepareScriptDirectory() else {
            print("Failed to prepare SSH script directory")
            return
        }
        cleanupStaleScripts(in: scriptDirectory)

        var args = ["ssh", "-i", shellQuote(config.resolvedKeyPath)]
        if config.sshPort != 22 { args += ["-p", String(config.sshPort)] }
        args.append(shellQuote("\(config.sshUser)@\(config.sshHost)"))
        let script = "#!/bin/bash\n\(args.joined(separator: " "))\n"

        let scriptURL = scriptDirectory
            .appendingPathComponent("serverpulse-ssh-\(UUID().uuidString).command")

        let created = FileManager.default.createFile(
            atPath: scriptURL.path,
            contents: Data(script.utf8),
            attributes: [.posixPermissions: 0o700]
        )
        guard created else {
            print("Failed to create temporary SSH script at \(scriptURL.path)")
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

        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            try? FileManager.default.removeItem(at: scriptURL)
        }
    }

    private static func shellQuote(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func prepareScriptDirectory() -> URL? {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("serverpulse-ssh-scripts", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: dir.path)
            return dir
        } catch {
            print("Failed to prepare temporary SSH script directory: \(error)")
            return nil
        }
    }

    private static func cleanupStaleScripts(in directory: URL, olderThan seconds: TimeInterval = 60 * 60) {
        let fileManager = FileManager.default
        guard let urls = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        let cutoff = Date().addingTimeInterval(-seconds)
        for url in urls where url.pathExtension == "command" {
            let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
            let modified = values?.contentModificationDate ?? .distantPast
            if modified < cutoff {
                try? fileManager.removeItem(at: url)
            }
        }
    }
}
