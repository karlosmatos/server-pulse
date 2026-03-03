import Foundation

@Observable
@MainActor
final class AppEnvironment {
    // MARK: - Projected state (selected server -> flat properties)
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
    var settingsErrorMessage: String?

    let settings: AppSettings

    // MARK: - Multi-server state

    private(set) var servers: [ServerConfig] = []
    private(set) var serverStates: [UUID: ServerState] = [:]
    private var pollingServices: [UUID: PollingService] = [:]
    private var pollingTasks: [UUID: Task<Void, Never>] = [:]
    private var didRequestNotificationPermission = false
    private let pollingServiceFactory: (ServerConfig) -> PollingService
    private let notificationPermissionRequester: @Sendable () async -> Void

    var selectedServerID: UUID? {
        didSet {
            settings.selectedServerID = selectedServerID
            projectSelectedServer()
        }
    }

    var selectedServer: ServerConfig? {
        servers.first { $0.id == selectedServerID }
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

    init(
        settings: AppSettings = AppSettings(),
        pollingServiceFactory: @escaping (ServerConfig) -> PollingService = { PollingService(config: $0) },
        notificationPermissionRequester: @escaping @Sendable () async -> Void = { await NotificationManager.requestPermission() },
        autoStartPolling: Bool = true
    ) {
        self.settings = settings
        self.pollingServiceFactory = pollingServiceFactory
        self.notificationPermissionRequester = notificationPermissionRequester

        servers = settings.loadServers()
        migrateIfNeeded()
        servers = settings.loadServers()

        let savedID = settings.selectedServerID
        selectedServerID = (savedID != nil && servers.contains(where: { $0.id == savedID }))
            ? savedID
            : servers.first?.id

        if !servers.isEmpty {
            isLoading = true
        }

        guard autoStartPolling else { return }
        for server in servers {
            startPolling(for: server)
        }
    }

    // MARK: - Server management

    func addServer(_ config: ServerConfig) {
        var list = servers
        list.append(config)
        guard persistServers(list) else { return }

        startPolling(for: config)

        if selectedServerID == nil {
            selectedServerID = config.id
        }
    }

    func updateServer(_ config: ServerConfig) {
        var list = servers
        guard let idx = list.firstIndex(where: { $0.id == config.id }) else { return }
        list[idx] = config
        guard persistServers(list) else { return }

        stopPolling(for: config.id)
        startPolling(for: config)

        if selectedServerID == config.id {
            projectSelectedServer()
        }
    }

    func removeServer(_ id: UUID) {
        stopPolling(for: id)
        serverStates.removeValue(forKey: id)

        var list = servers
        list.removeAll { $0.id == id }
        guard persistServers(list) else { return }

        if selectedServerID == id {
            selectedServerID = list.first?.id
        }
    }

    func refreshNow() {
        guard let id = selectedServerID,
              let serviceID = pollingServices[id]?.instanceID else { return }
        Task { [weak self] in
            await self?.refreshServer(id: id, expectedServiceID: serviceID)
        }
    }

    // MARK: - Polling

    func startPolling(for config: ServerConfig) {
        Task { [weak self] in
            await self?.requestNotificationPermissionIfNeeded()
        }

        let service = pollingServiceFactory(config)
        pollingServices[config.id] = service
        serverStates[config.id] = serverStates[config.id] ?? ServerState()

        pollingTasks[config.id]?.cancel()
        pollingTasks[config.id] = Task { [weak self, id = config.id, serviceID = service.instanceID] in
            while !Task.isCancelled {
                await self?.refreshServer(id: id, expectedServiceID: serviceID)
                let rawInterval = config.pollingInterval
                let safeInterval = rawInterval.isFinite ? rawInterval : 30.0
                let clampedInterval = max(10.0, min(safeInterval, 3_600.0))
                let nanos = min(clampedInterval * 1_000_000_000, Double(UInt64.max))
                try? await Task.sleep(nanoseconds: UInt64(nanos))
            }
        }
    }

    // MARK: - Private

    private func requestNotificationPermissionIfNeeded() async {
        guard !didRequestNotificationPermission else { return }
        didRequestNotificationPermission = true
        await notificationPermissionRequester()
    }

    @discardableResult
    private func persistServers(_ newServers: [ServerConfig]) -> Bool {
        guard settings.saveServers(newServers) else {
            settingsErrorMessage = "Failed to save settings. Please check Console logs for details."
            return false
        }

        settingsErrorMessage = nil
        servers = newServers
        return true
    }

    private func stopPolling(for id: UUID) {
        pollingTasks[id]?.cancel()
        pollingTasks.removeValue(forKey: id)
        pollingServices.removeValue(forKey: id)
    }

    private func refreshServer(id: UUID, expectedServiceID: UUID) async {
        guard let service = pollingServices[id], service.instanceID == expectedServiceID else { return }

        if id == selectedServerID { isLoading = true }
        serverStates[id]?.isLoading = true

        let result = await service.poll()

        guard !Task.isCancelled,
              let activeService = pollingServices[id],
              activeService.instanceID == expectedServiceID else { return }

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
        guard servers.isEmpty else { return }

        if let config = EnvLoader.migrateLegacyDefaults() {
            _ = persistServers([config])
            return
        }

        if let config = EnvLoader.loadFromEnvFile() {
            _ = persistServers([config])
        }
    }
}
