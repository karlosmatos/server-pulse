import Foundation

struct DockerContainer: Identifiable {
    let id: String
    let name: String
    let image: String
    let status: String
    let cpuPercent: Double
    let memPercent: Double
    let memUsage: String

    var isRunning: Bool {
        status.lowercased().hasPrefix("up")
    }
}
