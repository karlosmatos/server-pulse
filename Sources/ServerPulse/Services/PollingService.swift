import Foundation

struct PollResult {
    var status: ServerStatus = .unknown
    var stats: ServerStats?
    var processes: [ServerProcess] = []
    var workflows: [N8NWorkflow] = []
    var recentExecutions: [N8NExecution] = []
    var errorMessage: String?
}

struct PollingService {
    let settings: AppSettings
    let ssh: SSHClient
    let ping: PingChecker
    let n8n: N8NClient
    let notifications: NotificationManager

    init(settings: AppSettings) {
        self.settings = settings
        self.ssh = SSHClient(settings: settings)
        self.ping = PingChecker()
        self.n8n = N8NClient(settings: settings)
        self.notifications = NotificationManager()
    }

    func poll() async -> PollResult {
        // All I/O runs concurrently
        async let reachable  = ping.isReachable(host: settings.sshHost)
        async let cpuOut     = try? ssh.run("top -bn1 | grep 'Cpu(s)'")
        async let ramOut     = try? ssh.run("free -m | grep '^Mem'")
        async let diskOut    = try? ssh.run("df -h / | tail -1")
        async let psOut      = try? ssh.run("ps aux | grep -i python | grep -v grep | grep -v '^root'")
        async let uptimeOut  = try? ssh.run("uptime")
        async let workflows  = try? n8n.fetchWorkflows()
        async let executions = try? n8n.fetchRecentExecutions()

        let (isUp, cpu, ram, disk, ps, uptime, wf, exec) = await (
            reachable, cpuOut, ramOut, diskOut, psOut, uptimeOut, workflows, executions
        )

        var result = PollResult()

        // Derive status
        if !isUp {
            result.status = .offline
            result.errorMessage = "Unreachable (ping failed)"
        } else if cpu == nil && ram == nil {
            result.status = .degraded
            result.errorMessage = "SSH connection failed"
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

        result.processes       = ps.map { SSHCommandParser.parseProcesses(from: $0) } ?? []
        result.workflows       = wf   ?? []
        result.recentExecutions = exec ?? []

        await notifications.evaluate(result: result)
        return result
    }
}
