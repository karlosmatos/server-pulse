import Foundation
import UserNotifications

actor NotificationManager {
    private var previousStatus: ServerStatus = .unknown
    private var previousPIDs: Set<Int> = []

    func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    func evaluate(result: PollResult) async {
        // Server state transitions
        if previousStatus == .online && result.status == .offline {
            await post(title: "Server Offline",
                       body: "Your server is no longer reachable",
                       id: "server.offline")
        } else if previousStatus == .offline && result.status == .online {
            await post(title: "Server Back Online",
                       body: "Your server is reachable again",
                       id: "server.online")
        }

        // Detect stopped Python processes
        let currentPIDs = Set(result.processes.map(\.id))
        let stopped = previousPIDs.subtracting(currentPIDs)
        if !stopped.isEmpty && !previousPIDs.isEmpty {
            await post(title: "Process Stopped",
                       body: "\(stopped.count) Python process(es) stopped running",
                       id: "process.stopped")
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
