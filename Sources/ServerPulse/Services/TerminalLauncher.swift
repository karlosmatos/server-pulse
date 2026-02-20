import Foundation

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

        let source: String
        switch terminalApp.lowercased() {
        case "iterm", "iterm2":
            source = """
            tell application "iTerm"
                activate
                set newWindow to (create window with default profile)
                tell current session of newWindow
                    write text "\(sshCommand)"
                end tell
            end tell
            """
        default:
            source = """
            tell application "Terminal"
                activate
                do script "\(sshCommand)"
            end tell
            """
        }

        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
    }
}
