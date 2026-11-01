import Sparkle
import SwiftUI

@main
@MainActor
struct ServerPulseApp: App {
    @State private var appEnv = AppEnvironment()
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    var body: some Scene {
        MenuBarExtra {
            PopoverRootView(updater: updaterController.updater)
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
