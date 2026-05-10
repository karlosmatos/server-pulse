import Foundation
import OSLog

struct PollResult {
    var status: ServerStatus = .unknown
    var stats: ServerStats?
    var processes: [ServerProcess] = []
    var dockerContainers: [DockerContainer] = []
    var systemdServices: [SystemdService] = []
    var workflows: [N8NWorkflow] = []
    var recentExecutions: [N8NExecution] = []
    var errorMessage: String?
    var didRefreshHeavyData: Bool = false
}

struct PollingService {
    private static let logger = Logger(subsystem: "ServerPulse", category: "Polling")
    let instanceID: UUID
    let config: ServerConfig
    let ssh: SSHClient
    let n8n: N8NClient
    let notifications: NotificationManager
    private let pollOverride: (() async -> PollResult)?

    init(config: ServerConfig, pollOverride: (() async -> PollResult)? = nil) {
        self.instanceID = UUID()
        self.config = config
        self.ssh = SSHClient(config: config)
        self.n8n = N8NClient(config: config)
        self.notifications = NotificationManager(serverName: config.name, serverID: config.id)
        self.pollOverride = pollOverride
    }

    func poll(includeHeavyData: Bool = true) async -> PollResult {
        if let pollOverride {
            return await pollOverride()
        }

        let baseURL = config.n8nBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let scheme = URL(string: baseURL)?.scheme?.lowercased()
        let hasN8NConfig = includeHeavyData && !config.n8nAPIKey.isEmpty && !baseURL.isEmpty
        let shouldPollN8N = hasN8NConfig && scheme == "https"
        let n8nConfigError = hasN8NConfig && scheme != "https" ? "n8n URL must start with https://" : nil
        let snapshotCommand = SSHCommandParser.snapshotCommand(config: config, includeHeavyData: includeHeavyData)

        let pollStart = ProcessInfo.processInfo.systemUptime
        async let snapshotTimed = Self.measure { try? await ssh.run(snapshotCommand) }
        async let workflowsTimed: ([N8NWorkflow]?, TimeInterval) = shouldPollN8N
            ? Self.measure { try? await n8n.fetchWorkflows() }
            : (nil, 0)
        async let executionsTimed: ([N8NExecution]?, TimeInterval) = shouldPollN8N
            ? Self.measure { try? await n8n.fetchRecentExecutions() }
            : (nil, 0)

        let ((snapshot, snapshotDuration), (wf, workflowsDuration), (exec, executionsDuration)) = await (
            snapshotTimed,
            workflowsTimed,
            executionsTimed
        )

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
        if result.errorMessage == nil {
            result.errorMessage = n8nConfigError
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
        result.workflows        = wf   ?? []
        result.recentExecutions = exec ?? []
        result.didRefreshHeavyData = includeHeavyData

        let totalDuration = ProcessInfo.processInfo.systemUptime - pollStart
        logDiagnostics(
            totalDuration: totalDuration,
            snapshotDuration: snapshotDuration,
            workflowsDuration: workflowsDuration,
            executionsDuration: executionsDuration,
            includeHeavyData: includeHeavyData
        )

        await notifications.evaluate(result: result)
        return result
    }

    private func logDiagnostics(
        totalDuration: TimeInterval,
        snapshotDuration: TimeInterval,
        workflowsDuration: TimeInterval,
        executionsDuration: TimeInterval,
        includeHeavyData: Bool
    ) {
        guard totalDuration >= 2 else { return }
        Self.logger.notice(
            "Slow poll for \(self.config.name, privacy: .public): total=\(totalDuration, format: .fixed(precision: 2))s snapshot=\(snapshotDuration, format: .fixed(precision: 2))s workflows=\(workflowsDuration, format: .fixed(precision: 2))s executions=\(executionsDuration, format: .fixed(precision: 2))s heavy=\(includeHeavyData, privacy: .public)"
        )
    }

    private static func measure<T>(_ operation: () async -> T) async -> (T, TimeInterval) {
        let start = ProcessInfo.processInfo.systemUptime
        let value = await operation()
        return (value, ProcessInfo.processInfo.systemUptime - start)
    }
}
