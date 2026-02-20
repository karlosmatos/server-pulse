import Foundation
import UserNotifications

actor NotificationManager {
    private let serverName: String
    private let serverID: UUID
    private var previousStatus: ServerStatus = .unknown
    private var previousPIDs: Set<Int> = []

    init(serverName: String, serverID: UUID) {
        self.serverName = serverName
        self.serverID = serverID
    }

    func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    func evaluate(result: PollResult) async {
        // Server state transitions
        if previousStatus == .online && result.status == .offline {
            await post(title: "\(serverName) Offline",
                       body: "\(serverName) is no longer reachable",
                       id: "server.offline.\(serverID)")
        } else if previousStatus == .offline && result.status == .online {
            await post(title: "\(serverName) Back Online",
                       body: "\(serverName) is reachable again",
                       id: "server.online.\(serverID)")
        }

        // Detect stopped monitored processes
        let currentPIDs = Set(result.processes.map(\.id))
        let stopped = previousPIDs.subtracting(currentPIDs)
        if !stopped.isEmpty && !previousPIDs.isEmpty {
            await post(title: "\(serverName): Process Stopped",
                       body: "\(stopped.count) monitored process(es) stopped running",
                       id: "process.stopped.\(serverID)")
        }

        previousStatus = result.status
        previousPIDs = currentPIDs
    }

    // MARK: - Private

    private func post(title: String, body: String, id: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "\(id).\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}
