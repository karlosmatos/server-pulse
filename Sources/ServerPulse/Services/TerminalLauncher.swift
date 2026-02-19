import Foundation

enum TerminalLauncher {
    static func openSSH(settings: AppSettings) {
        guard !settings.sshHost.isEmpty, !settings.sshUser.isEmpty else { return }

        var parts = ["ssh"]
        parts.append("-i '\(settings.resolvedKeyPath)'")
        if settings.sshPort != 22 {
            parts.append("-p \(settings.sshPort)")
        }
        parts.append("\(settings.sshUser)@\(settings.sshHost)")

        let sshCommand = parts.joined(separator: " ")

        let source = """
        tell application "Terminal"
            activate
            do script "\(sshCommand)"
        end tell
        """

        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
    }
}
