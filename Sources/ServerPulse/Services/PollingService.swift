import Foundation
import OSLog

struct PollResult {
    var status: ServerStatus = .unknown
    var stats: ServerStats?
    var processes: [ServerProcess] = []
    var dockerContainers: [DockerContainer] = []
    var systemdServices: [SystemdService] = []
    var errorMessage: String?
    var didRefreshHeavyData: Bool = false
    /// nil when the audit was not requested or could not run.
    var securityChecks: [SecurityCheck]?
}

struct PollingService {
    private static let logger = Logger(subsystem: "ServerPulse", category: "Polling")
    let instanceID: UUID
    let config: ServerConfig
    let ssh: SSHClient
    let notifications: NotificationManager
    private let pollOverride: (() async -> PollResult)?

    init(config: ServerConfig, pollOverride: (() async -> PollResult)? = nil) {
        self.instanceID = UUID()
        self.config = config
        self.ssh = SSHClient(config: config)
        self.notifications = NotificationManager(serverName: config.name, serverID: config.id)
        self.pollOverride = pollOverride
    }

    func poll(includeHeavyData: Bool = true, includeSecurityAudit: Bool = false) async -> PollResult {
        if let pollOverride {
            return await pollOverride()
        }

        let snapshotCommand = SSHCommandParser.snapshotCommand(config: config, includeHeavyData: includeHeavyData)

        let pollStart = ProcessInfo.processInfo.systemUptime
        let (snapshot, snapshotDuration) = await Self.measure { try? await ssh.run(snapshotCommand) }

        var result = PollResult()
        let sections = snapshot.map(SSHCommandParser.parseSnapshot(from:)) ?? [:]
        let cpu = sections["CPU"]
        let ram = sections["RAM"]
        let disk = sections["DISK"]
        let ps = sections["PROCESS"]
        let uptime = sections["UPTIME"]
        let docker = sections["DOCKER"]
        let systemd = sections["SYSTEMD"]

        // Derive status
        if snapshot == nil {
            let isReachable = await PingChecker().isReachable(host: config.sshHost)
            result.status = isReachable ? .degraded : .offline
            result.errorMessage = isReachable ? "SSH connection failed" : "Unreachable (ping failed)"
        } else {
            result.status = .online
        }

        // Parse stats
        let ramParsed  = ram.flatMap  { SSHCommandParser.parseRAM(from: $0) }
        let diskParsed = disk.flatMap { SSHCommandParser.parseDisk(from: $0) }

        result.stats = ServerStats(
            cpuUsage:         cpu.flatMap { SSHCommandParser.parseCPU(from: $0) } ?? 0,
            ramUsed:          ramParsed?.used    ?? 0,
            ramTotal:         ramParsed?.total   ?? 0,
            diskUsed:         diskParsed?.used   ?? "?",
            diskTotal:        diskParsed?.total  ?? "?",
            diskUsagePercent: diskParsed?.percent ?? 0,
            uptime:           uptime.map { SSHCommandParser.parseUptime(from: $0) } ?? "Unknown"
        )

        result.processes        = ps.map { SSHCommandParser.parseProcesses(from: $0) } ?? []
        result.dockerContainers = docker.map { SSHCommandParser.parseDockerOutput(from: $0) } ?? []
        result.systemdServices  = systemd.map { SSHCommandParser.parseSystemdServices(from: $0) } ?? []
        result.didRefreshHeavyData = includeHeavyData

        // Runs after the snapshot so it reuses the SSH ControlMaster connection.
        if includeSecurityAudit, config.securityAuditEnabled, snapshot != nil,
           let auditOutput = try? await ssh.run(SecurityAudit.command) {
            let facts = SecurityAudit.parseFacts(from: auditOutput)
            let sshProbes = SecurityAudit.needsSSHProbe(facts, sshPort: config.sshPort)
                ? await PortProbe.probeAll(hosts: facts.publicAddresses, port: config.sshPort)
                : []
            result.securityChecks = SecurityAudit.evaluate(facts: facts, sshPort: config.sshPort, sshProbes: sshProbes)
        }

        let totalDuration = ProcessInfo.processInfo.systemUptime - pollStart
        logDiagnostics(
            totalDuration: totalDuration,
            snapshotDuration: snapshotDuration,
            includeHeavyData: includeHeavyData
        )

        await notifications.evaluate(result: result)
        return result
    }

    private func logDiagnostics(
        totalDuration: TimeInterval,
        snapshotDuration: TimeInterval,
        includeHeavyData: Bool
    ) {
        guard totalDuration >= 2 else { return }
        Self.logger.notice(
            "Slow poll for \(self.config.name, privacy: .public): total=\(totalDuration, format: .fixed(precision: 2))s snapshot=\(snapshotDuration, format: .fixed(precision: 2))s heavy=\(includeHeavyData, privacy: .public)"
        )
    }

    private static func measure<T>(_ operation: () async -> T) async -> (T, TimeInterval) {
        let start = ProcessInfo.processInfo.systemUptime
        let value = await operation()
        return (value, ProcessInfo.processInfo.systemUptime - start)
    }
}
