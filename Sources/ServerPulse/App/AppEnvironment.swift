import Foundation

@Observable
@MainActor
final class AppEnvironment {
    // MARK: - Projected state (selected server → flat properties)
    var serverStatus: ServerStatus = .unknown
    var stats: ServerStats?
    var processes: [ServerProcess] = []
    var dockerContainers: [DockerContainer] = []
    var systemdServices: [SystemdService] = []
    var workflows: [N8NWorkflow] = []
    var recentExecutions: [N8NExecution] = []
    var lastUpdated: Date?
    var errorMessage: String?
    var isLoading: Bool = false

    let settings: AppSettings

    // MARK: - Multi-server state

    private(set) var serverStates: [UUID: ServerState] = [:]
    private var pollingServices: [UUID: PollingService] = [:]
    private var pollingTasks: [UUID: Task<Void, Never>] = [:]

    var selectedServerID: UUID? {
        didSet {
            settings.selectedServerID = selectedServerID
            projectSelectedServer()
        }
    }

    var selectedServer: ServerConfig? {
        settings.servers.first { $0.id == selectedServerID }
    }

    /// Worst status across all servers (for menu bar icon).
    var worstStatus: ServerStatus {
        let statuses = serverStates.values.map(\.status)
        if statuses.contains(.offline) { return .offline }
        if statuses.contains(.degraded) { return .degraded }
        if statuses.contains(.online) { return .online }
        return .unknown
    }

    // MARK: - Init

    init() {
        let s = AppSettings()
        settings = s
        migrateIfNeeded()
        selectedServerID = s.selectedServerID ?? s.servers.first?.id

        // didSet doesn't fire during init, so mark loading if we have servers
        if !s.servers.isEmpty {
            isLoading = true
        }

        for server in s.servers {
            startPolling(for: server)
        }
    }

    // MARK: - Server management

    func addServer(_ config: ServerConfig) {
        var list = settings.servers
        list.append(config)
        settings.servers = list

        startPolling(for: config)

        if selectedServerID == nil {
            selectedServerID = config.id
        }
    }

    func updateServer(_ config: ServerConfig) {
        var list = settings.servers
        guard let idx = list.firstIndex(where: { $0.id == config.id }) else { return }
        list[idx] = config
        settings.servers = list

        // Restart polling with new config
        stopPolling(for: config.id)
        startPolling(for: config)

        if selectedServerID == config.id {
            projectSelectedServer()
        }
    }

    func removeServer(_ id: UUID) {
        stopPolling(for: id)
        serverStates.removeValue(forKey: id)

        var list = settings.servers
        list.removeAll { $0.id == id }
        settings.servers = list

        if selectedServerID == id {
            selectedServerID = list.first?.id
        }
    }

    func refreshNow() {
        guard let id = selectedServerID, let config = selectedServer else { return }
        Task { [weak self] in
            await self?.refreshServer(id: id, config: config)
        }
    }

    // MARK: - Polling

    func startPolling(for config: ServerConfig) {
        let service = PollingService(config: config)
        pollingServices[config.id] = service
        serverStates[config.id] = serverStates[config.id] ?? ServerState()

        pollingTasks[config.id]?.cancel()
        pollingTasks[config.id] = Task { [weak self, id = config.id] in
            // Request notification permission on first poll
            await service.notifications.requestPermission()
            while !Task.isCancelled {
                await self?.refreshServer(id: id, config: config)
                let interval = config.pollingInterval
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    // MARK: - Private

    private func stopPolling(for id: UUID) {
        pollingTasks[id]?.cancel()
        pollingTasks.removeValue(forKey: id)
        pollingServices.removeValue(forKey: id)
    }

    private func refreshServer(id: UUID, config: ServerConfig) async {
        guard let service = pollingServices[id] else { return }

        if id == selectedServerID { isLoading = true }
        serverStates[id]?.isLoading = true

        let result = await service.poll()

        var state = serverStates[id] ?? ServerState()
        state.status = result.status
        state.stats = result.stats
        state.processes = result.processes
        state.dockerContainers = result.dockerContainers
        state.systemdServices = result.systemdServices
        state.workflows = result.workflows
        state.recentExecutions = result.recentExecutions
        state.lastUpdated = Date()
        state.errorMessage = result.errorMessage
        state.isLoading = false
        serverStates[id] = state

        if id == selectedServerID {
            projectSelectedServer()
        }
    }

    private func projectSelectedServer() {
        guard let id = selectedServerID, let state = serverStates[id] else {
            serverStatus = .unknown
            stats = nil
            processes = []
            dockerContainers = []
            systemdServices = []
            workflows = []
            recentExecutions = []
            lastUpdated = nil
            errorMessage = nil
            isLoading = false
            return
        }

        serverStatus = state.status
        stats = state.stats
        processes = state.processes
        dockerContainers = state.dockerContainers
        systemdServices = state.systemdServices
        workflows = state.workflows
        recentExecutions = state.recentExecutions
        lastUpdated = state.lastUpdated
        errorMessage = state.errorMessage
        isLoading = state.isLoading
    }

    private func migrateIfNeeded() {
        guard settings.servers.isEmpty else { return }

        // Try legacy UserDefaults first
        if let config = EnvLoader.migrateLegacyDefaults() {
            settings.servers = [config]
            return
        }

        // Try .env file
        if let config = EnvLoader.loadFromEnvFile() {
            settings.servers = [config]
        }
    }
}
