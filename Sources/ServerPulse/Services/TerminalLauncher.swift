import Foundation
import AppKit
import OSLog

struct TerminalLaunchIssue: Identifiable {
    enum Severity {
        case warning
        case error
    }

    let id = UUID()
    let severity: Severity
    let message: String

    static func warning(_ message: String) -> Self {
        .init(severity: .warning, message: message)
    }

    static func error(_ message: String) -> Self {
        .init(severity: .error, message: message)
    }
}

enum TerminalLauncher {
    private static let logger = Logger(subsystem: "ServerPulse", category: "TerminalLauncher")

    static func displayName(for terminalApp: String) -> String {
        switch terminalApp.lowercased() {
        case "iterm", "iterm2":
            return "iTerm2"
        case "cmux":
            return "cmux"
        case "herdr":
            return "Herdr"
        default:
            return "Terminal.app"
        }
    }

    @discardableResult
    static func openSSH(
        config: ServerConfig,
        terminalApp: String,
        onDeferredIssue: @escaping @MainActor (TerminalLaunchIssue) -> Void = { _ in }
    ) -> TerminalLaunchIssue? {
        guard !config.sshHost.isEmpty, !config.sshUser.isEmpty else {
            let issue = TerminalLaunchIssue.error("SSH host and user are required before opening a terminal session.")
            logger.error("\(issue.message, privacy: .public)")
            return issue
        }
        let arguments: [String]
        do {
            arguments = try sshArguments(for: config)
        } catch {
            let message = error.localizedDescription
            logger.error("\(message, privacy: .public)")
            return TerminalLaunchIssue.error(message)
        }
        let command = arguments.map(shellQuote).joined(separator: " ")

        switch terminalApp.lowercased() {
        case "iterm", "iterm2":
            return openSSHScript(
                command: command,
                appName: "iTerm2",
                bundleIdentifier: "com.googlecode.iterm2",
                onDeferredIssue: onDeferredIssue
            )
        case "cmux":
            return openSSHScript(
                command: command,
                appName: "cmux",
                bundleIdentifier: "com.cmuxterm.app",
                onDeferredIssue: onDeferredIssue
            )
        case "herdr":
            return openSSHInHerdr(config: config, sshArguments: arguments, onDeferredIssue: onDeferredIssue)
        default:
            guard let scriptURL = createScript(command: command) else {
                return TerminalLaunchIssue.error("ServerPulse couldn't create the temporary SSH launcher. Check Console for details.")
            }
            defer { scheduleCleanup(for: scriptURL) }
            guard openScript(scriptURL) else {
                return TerminalLaunchIssue.error("macOS refused to open the temporary SSH launcher. Check Console for details.")
            }
            return nil
        }
    }

    private static func openSSHScript(
        command: String,
        appName: String,
        bundleIdentifier: String,
        onDeferredIssue: @escaping @MainActor (TerminalLaunchIssue) -> Void
    ) -> TerminalLaunchIssue? {
        guard let scriptURL = createScript(command: command) else {
            return TerminalLaunchIssue.error("ServerPulse couldn't create the temporary SSH launcher. Check Console for details.")
        }
        defer { scheduleCleanup(for: scriptURL) }

        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            logger.error("\(appName, privacy: .public) bundle identifier could not be resolved")
            guard openScript(scriptURL) else {
                return TerminalLaunchIssue.error("\(appName) wasn't found, and macOS refused to open the SSH launcher.")
            }
            return TerminalLaunchIssue.warning("\(appName) wasn't found. Opened the SSH script with the default terminal app instead.")
        }

        openScript(scriptURL, withApplicationAt: appURL, appName: appName) { error in
            guard let error else { return }
            onDeferredIssue(
                .error(
                    "ServerPulse couldn't open the SSH launcher in \(appName): \(error.localizedDescription)"
                )
            )
        }
        return nil
    }

    /// Herdr has no file-open handler, so drive its CLI (`Herdr do space.new`) instead.
    /// A server already added as a Herdr machine opens there natively; otherwise a local space runs ssh.
    /// The CLI only talks to an open window, so launch/activate the app first and retry while it starts.
    private static func openSSHInHerdr(
        config: ServerConfig,
        sshArguments: [String],
        onDeferredIssue: @escaping @MainActor (TerminalLaunchIssue) -> Void
    ) -> TerminalLaunchIssue? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "dev.herdr.app"),
              let executableURL = Bundle(url: appURL)?.executableURL else {
            logger.error("Herdr bundle identifier could not be resolved")
            return TerminalLaunchIssue.error("Herdr wasn't found. Install it or pick another terminal app in Settings.")
        }
        let destination = sshArguments.last ?? ""

        let cfg = NSWorkspace.OpenConfiguration()
        cfg.activates = true
        NSWorkspace.shared.openApplication(at: appURL, configuration: cfg) { _, error in
            if let error {
                logger.error("Herdr launch failed: \(error.localizedDescription, privacy: .public)")
                Task { @MainActor in
                    onDeferredIssue(.error("ServerPulse couldn't open Herdr: \(error.localizedDescription)"))
                }
                return
            }
            DispatchQueue.global().async {
                var payload: [String: Any] = ["name": config.name]
                if let machine = herdrMachine(destination: destination, host: config.sshHost) {
                    payload["machine"] = machine
                } else {
                    payload["machine"] = ""
                    payload["argv"] = sshArguments
                }
                guard let failure = runHerdrNewSpace(executableURL: executableURL, payload: payload) else { return }
                logger.error("Herdr space.new failed: \(failure, privacy: .public)")
                Task { @MainActor in
                    onDeferredIssue(.error("ServerPulse couldn't open a Herdr session: \(failure)"))
                }
            }
        }
        return nil
    }

    /// Name of the Herdr machine (`hc machine ls`) that reaches this server, if any.
    private static func herdrMachine(destination: String, host: String) -> String? {
        let coreURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/bin/herdr-core")
        guard FileManager.default.isExecutableFile(atPath: coreURL.path) else { return nil }

        let result = runProcess(coreURL, arguments: ["machine", "ls", "--json"])
        guard result.status == 0,
              let object = try? JSONSerialization.jsonObject(with: result.output) as? [String: Any],
              let machines = object["machines"] as? [[String: Any]] else {
            logger.error("herdr-core machine ls failed: \(result.error, privacy: .public)")
            return nil
        }
        let match = machines.first { machine in
            machine["target"] as? String == destination
                || machine["name"] as? String == host
                || machine["host"] as? String == host
        }
        return match?["name"] as? String
    }

    /// Returns nil on success, otherwise the last error output.
    private static func runHerdrNewSpace(executableURL: URL, payload: [String: Any], attempts: Int = 20) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8) else {
            return "couldn't encode the Herdr command"
        }
        var lastError = "unknown error"
        for attempt in 1...attempts {
            let result = runProcess(executableURL, arguments: ["do", "space.new", json])
            if result.status == 0 { return nil }
            let output = String(data: result.output, encoding: .utf8) ?? ""
            lastError = [result.error, output]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            if attempt < attempts { Thread.sleep(forTimeInterval: 0.5) }
        }
        return lastError
    }

    private static func runProcess(_ url: URL, arguments: [String]) -> (status: Int32, output: Data, error: String) {
        let process = Process()
        process.executableURL = url
        process.arguments = arguments
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        do {
            try process.run()
        } catch {
            return (-1, Data(), error.localizedDescription)
        }
        let output = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, output, String(data: errorOutput, encoding: .utf8) ?? "")
    }

    private static func sshArguments(for config: ServerConfig) throws -> [String] {
        let destination = try SSHConfigValidator.destination(for: config)
        var args = ["ssh", "-i", config.resolvedKeyPath]
        if config.sshPort != 22 { args += ["-p", String(config.sshPort)] }
        args.append("--")
        args.append(destination)
        return args
    }

    private static func createScript(command: String) -> URL? {
        guard let scriptDirectory = prepareScriptDirectory() else {
            logger.error("Failed to prepare SSH script directory")
            return nil
        }
        cleanupStaleScripts(in: scriptDirectory)

        let script = "#!/bin/bash\n\(command)\n"
        let scriptURL = scriptDirectory
            .appendingPathComponent("serverpulse-ssh-\(UUID().uuidString).command")

        let created = FileManager.default.createFile(
            atPath: scriptURL.path,
            contents: Data(script.utf8),
            attributes: [.posixPermissions: 0o700]
        )

        guard created else {
            logger.error("Failed to create temporary SSH script")
            return nil
        }

        return scriptURL
    }

    private static func scheduleCleanup(for scriptURL: URL, after seconds: TimeInterval = 60) {
        DispatchQueue.global().asyncAfter(deadline: .now() + seconds) {
            try? FileManager.default.removeItem(at: scriptURL)
        }
    }

    @discardableResult
    private static func openScript(_ scriptURL: URL) -> Bool {
        let opened = NSWorkspace.shared.open(scriptURL)
        if !opened {
            logger.error("NSWorkspace refused to open temporary SSH script")
        }
        return opened
    }

    private static func openScript(
        _ scriptURL: URL,
        withApplicationAt appURL: URL,
        appName: String,
        completion: @escaping @MainActor (Error?) -> Void = { _ in }
    ) {
        let cfg = NSWorkspace.OpenConfiguration()
        cfg.activates = true
        NSWorkspace.shared.open([scriptURL], withApplicationAt: appURL, configuration: cfg) { _, error in
            if let error {
                logger.error("\(appName, privacy: .public) file-open failed: \(error.localizedDescription, privacy: .public)")
            }
            Task { @MainActor in
                completion(error)
            }
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
            logger.error("Failed to prepare temporary SSH script directory: \(error.localizedDescription, privacy: .public)")
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
