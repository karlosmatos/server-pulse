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
    nonisolated private let pollingTaskBag = PollingTaskBag()
    private let pollLimiter: PollConcurrencyLimiter
    private var refreshingServerIDs = Set<UUID>()
    private var pendingRefreshServerIDs = Set<UUID>()
    private var forcedHeavyRefreshServerIDs = Set<UUID>()
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
        maxConcurrentPolls: Int = 3,
        autoStartPolling: Bool = true
    ) {
        self.settings = settings
        self.pollingServiceFactory = pollingServiceFactory
        self.notificationPermissionRequester = notificationPermissionRequester
        self.pollLimiter = PollConcurrencyLimiter(maxConcurrentPolls: maxConcurrentPolls)

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
        var staggerIndex = 0
        for server in servers {
            let initialDelay: TimeInterval
            if server.id == selectedServerID {
                initialDelay = 0
            } else {
                initialDelay = Self.startupStaggerDelay(
                    index: staggerIndex,
                    total: max(servers.count - 1, 1),
                    interval: server.pollingInterval
                )
                staggerIndex += 1
            }
            startPolling(for: server, initialDelay: initialDelay)
        }
    }

    deinit {
        pollingTaskBag.cancelAll()
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
        forcedHeavyRefreshServerIDs.insert(id)
        Task { [weak self] in
            await self?.refreshServer(id: id, expectedServiceID: serviceID)
        }
    }

    // MARK: - Polling

    func startPolling(for config: ServerConfig, initialDelay: TimeInterval = 0) {
        Task { [weak self] in
            await self?.requestNotificationPermissionIfNeeded()
        }

        let service = pollingServiceFactory(config)
        pollingServices[config.id] = service
        serverStates[config.id] = serverStates[config.id] ?? ServerState()

        let task = Task { [weak self, id = config.id, serviceID = service.instanceID] in
            if initialDelay > 0 {
                try? await Task.sleep(nanoseconds: Self.sleepNanoseconds(for: initialDelay))
            }

            while !Task.isCancelled {
                await self?.refreshServer(id: id, expectedServiceID: serviceID)
                try? await Task.sleep(nanoseconds: Self.sleepNanoseconds(for: Self.clampedPollingInterval(config.pollingInterval)))
            }
        }
        pollingTaskBag.set(task, for: config.id)
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
        pollingTaskBag.cancel(for: id)
        pollingServices.removeValue(forKey: id)
    }

    private func refreshServer(id: UUID, expectedServiceID: UUID) async {
        guard let service = pollingServices[id], service.instanceID == expectedServiceID else { return }
        guard !refreshingServerIDs.contains(id) else {
            pendingRefreshServerIDs.insert(id)
            return
        }

        refreshingServerIDs.insert(id)
        defer {
            refreshingServerIDs.remove(id)
        }

        if id == selectedServerID { isLoading = true }
        serverStates[id]?.isLoading = true

        guard let pollPermit = await pollLimiter.acquire() else {
            serverStates[id]?.isLoading = false
            if id == selectedServerID { isLoading = false }
            return
        }
        defer {
            pollPermit.release()
        }
        guard !Task.isCancelled else {
            serverStates[id]?.isLoading = false
            if id == selectedServerID { isLoading = false }
            return
        }

        let includeHeavyData = forcedHeavyRefreshServerIDs.remove(id) != nil || shouldRefreshHeavyData(for: id)
        let result = await service.poll(includeHeavyData: includeHeavyData)

        guard !Task.isCancelled,
              let activeService = pollingServices[id],
              activeService.instanceID == expectedServiceID else {
            serverStates[id]?.isLoading = false
            if id == selectedServerID { isLoading = false }
            return
        }

        var state = serverStates[id] ?? ServerState()
        state.status = result.status
        state.stats = result.stats
        state.processes = result.processes
        if result.didRefreshHeavyData {
            state.dockerContainers = result.dockerContainers
            state.systemdServices = result.systemdServices
            state.workflows = result.workflows
            state.recentExecutions = result.recentExecutions
            state.lastHeavyRefresh = Date()
        }
        state.lastUpdated = Date()
        state.errorMessage = result.errorMessage
        state.isLoading = false
        serverStates[id] = state

        if id == selectedServerID {
            projectSelectedServer()
        }

        if pendingRefreshServerIDs.remove(id) != nil {
            await refreshServer(id: id, expectedServiceID: expectedServiceID)
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

    private func shouldRefreshHeavyData(for id: UUID) -> Bool {
        guard let config = servers.first(where: { $0.id == id }) else { return true }
        guard let state = serverStates[id] else { return true }
        guard let lastHeavyRefresh = state.lastHeavyRefresh else { return true }

        let minimumHeavyRefreshInterval = max(60.0, Self.clampedPollingInterval(config.pollingInterval))
        return Date().timeIntervalSince(lastHeavyRefresh) >= minimumHeavyRefreshInterval
    }

    private static func clampedPollingInterval(_ rawInterval: Double) -> TimeInterval {
        let safeInterval = rawInterval.isFinite ? rawInterval : 30.0
        return max(10.0, min(safeInterval, 3_600.0))
    }

    private static func sleepNanoseconds(for interval: TimeInterval) -> UInt64 {
        let nanos = min(interval * 1_000_000_000, Double(UInt64.max))
        return UInt64(nanos)
    }

    private static func startupStaggerDelay(index: Int, total: Int, interval: TimeInterval) -> TimeInterval {
        guard total > 0 else { return 0 }
        let window = min(clampedPollingInterval(interval) * 0.8, 30.0)
        return window * Double(index + 1) / Double(total + 1)
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

private final class PollingTaskBag: @unchecked Sendable {
    private let lock = NSLock()
    private var tasks: [UUID: Task<Void, Never>] = [:]

    func set(_ task: Task<Void, Never>, for id: UUID) {
        let previous: Task<Void, Never>?
        lock.lock()
        previous = tasks.updateValue(task, forKey: id)
        lock.unlock()

        previous?.cancel()
    }

    func cancel(for id: UUID) {
        let task: Task<Void, Never>?
        lock.lock()
        task = tasks.removeValue(forKey: id)
        lock.unlock()

        task?.cancel()
    }

    func cancelAll() {
        let allTasks: [Task<Void, Never>]
        lock.lock()
        allTasks = Array(tasks.values)
        tasks.removeAll()
        lock.unlock()

        allTasks.forEach { $0.cancel() }
    }
}

private actor PollConcurrencyLimiter {
    private let maxConcurrentPolls: Int
    private var availablePermits: Int
    private var waiters: [(id: UUID, continuation: CheckedContinuation<PollPermit?, Never>)] = []

    init(maxConcurrentPolls: Int) {
        let safeLimit = max(1, maxConcurrentPolls)
        self.maxConcurrentPolls = safeLimit
        self.availablePermits = safeLimit
    }

    func acquire() async -> PollPermit? {
        guard !Task.isCancelled else { return nil }

        if availablePermits > 0 {
            availablePermits -= 1
            return makePermit()
        }

        let id = UUID()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                waiters.append((id, continuation))
            }
        } onCancel: {
            Task {
                await self.cancelWaiter(id: id)
            }
        }
    }

    private func release() {
        guard !waiters.isEmpty else {
            availablePermits = min(availablePermits + 1, maxConcurrentPolls)
            return
        }

        let waiter = waiters.removeFirst()
        waiter.continuation.resume(returning: makePermit())
    }

    private func cancelWaiter(id: UUID) {
        guard let index = waiters.firstIndex(where: { $0.id == id }) else { return }
        let waiter = waiters.remove(at: index)
        waiter.continuation.resume(returning: nil)
    }

    private func makePermit() -> PollPermit {
        PollPermit {
            Task {
                await self.release()
            }
        }
    }
}

private final class PollPermit: @unchecked Sendable {
    private let lock = NSLock()
    private let releaseHandler: @Sendable () -> Void
    private var didRelease = false

    init(releaseHandler: @escaping @Sendable () -> Void) {
        self.releaseHandler = releaseHandler
    }

    deinit {
        release()
    }

    func release() {
        lock.lock()
        guard !didRelease else {
            lock.unlock()
            return
        }
        didRelease = true
        lock.unlock()

        releaseHandler()
    }
}
