import Foundation

struct PollResult {
    var status: ServerStatus = .unknown
    var stats: ServerStats?
    var processes: [ServerProcess] = []
    var dockerContainers: [DockerContainer] = []
    var systemdServices: [SystemdService] = []
    var workflows: [N8NWorkflow] = []
    var recentExecutions: [N8NExecution] = []
    var errorMessage: String?
}

struct PollingService {
    let config: ServerConfig
    let ssh: SSHClient
    let ping: PingChecker
    let n8n: N8NClient
    let notifications: NotificationManager

    init(config: ServerConfig) {
        self.config = config
        self.ssh = SSHClient(config: config)
        self.ping = PingChecker()
        self.n8n = N8NClient(config: config)
        self.notifications = NotificationManager(serverName: config.name, serverID: config.id)
    }

    func poll() async -> PollResult {
        let psCommand = SSHCommandParser.processCommand(count: config.processCount, filter: config.processFilter)

        // All I/O runs concurrently
        async let reachable  = ping.isReachable(host: config.sshHost)
        async let cpuOut     = try? ssh.run("top -bn1 | grep 'Cpu(s)'")
        async let ramOut     = try? ssh.run("free -m | grep '^Mem'")
        async let diskOut    = try? ssh.run("df -h / | tail -1")
        async let psOut      = try? ssh.run(psCommand)
        async let uptimeOut  = try? ssh.run("uptime")
        async let dockerOut  = config.dockerEnabled
            ? try? ssh.run("docker ps --format '{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}' 2>/dev/null; echo '---'; docker stats --no-stream --format '{{.ID}}|{{.CPUPerc}}|{{.MemPerc}}|{{.MemUsage}}' 2>/dev/null")
            : nil
        async let systemdOut: String? = {
            if let cmd = SSHCommandParser.systemdCommand(services: config.systemdServices) {
                return try? await ssh.run(cmd)
            }
            return nil
        }()
        async let workflows  = try? n8n.fetchWorkflows()
        async let executions = try? n8n.fetchRecentExecutions()

        let (isUp, cpu, ram, disk, ps, uptime, docker, systemd, wf, exec) = await (
            reachable, cpuOut, ramOut, diskOut, psOut, uptimeOut, dockerOut, systemdOut, workflows, executions
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

        result.processes        = ps.map { SSHCommandParser.parseProcesses(from: $0) } ?? []
        result.dockerContainers = docker.map { SSHCommandParser.parseDockerOutput(from: $0) } ?? []
        result.systemdServices  = systemd.map { SSHCommandParser.parseSystemdServices(from: $0) } ?? []
        result.workflows        = wf   ?? []
        result.recentExecutions = exec ?? []

        await notifications.evaluate(result: result)
        return result
    }
}
