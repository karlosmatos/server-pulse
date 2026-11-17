import Sparkle
import SwiftUI

@main
@MainActor
struct ServerPulseApp: App {
    @State private var appEnv = AppEnvironment()
    private let updateReminder: UpdateReminder
    private let updaterController: SPUStandardUpdaterController

    init() {
        let reminder = UpdateReminder()
        updateReminder = reminder
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: reminder
        )
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverRootView(updater: updaterController.updater, updateReminder: updateReminder)
                .environment(appEnv)
        } label: {
            MenuBarLabel(
                status: appEnv.worstStatus,
                severity: appEnv.worstSeverity,
                attentionCount: appEnv.attentionCount
            )
        }
        .menuBarExtraStyle(.window)
    }
}
