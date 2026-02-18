import Foundation

@Observable
@MainActor
final class AppEnvironment {
    var serverStatus: ServerStatus = .unknown
    var stats: ServerStats?
    var processes: [ServerProcess] = []
    var workflows: [N8NWorkflow] = []
    var recentExecutions: [N8NExecution] = []
    var lastUpdated: Date?
    var errorMessage: String?
    var isLoading: Bool = false

    let settings: AppSettings

    private let pollingService: PollingService
    private var pollingTask: Task<Void, Never>?

    init() {
        EnvLoader.loadIfNeeded()
        let s = AppSettings()
        settings = s
        pollingService = PollingService(settings: s)
        startPolling()
    }

    func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.refresh()
                let interval = self.settings.pollingInterval
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    func refreshNow() {
        Task { [weak self] in
            await self?.refresh()
        }
    }

    // MARK: - Private

    private func refresh() async {
        isLoading = true
        let result = await pollingService.poll()
        serverStatus        = result.status
        stats               = result.stats
        processes           = result.processes
        workflows           = result.workflows
        recentExecutions    = result.recentExecutions
        lastUpdated         = Date()
        errorMessage        = result.errorMessage
        isLoading           = false
    }
}
