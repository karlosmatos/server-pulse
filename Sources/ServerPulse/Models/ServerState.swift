import Foundation

struct ServerState {
    var status: ServerStatus = .unknown
    var stats: ServerStats?
    var processes: [ServerProcess] = []
    var dockerContainers: [DockerContainer] = []
    var systemdServices: [SystemdService] = []
    var workflows: [N8NWorkflow] = []
    var recentExecutions: [N8NExecution] = []
    var lastUpdated: Date?
    var errorMessage: String?
    var isLoading: Bool = false
}
