import SwiftUI

@main
@MainActor
struct ServerPulseApp: App {
    @State private var appEnv = AppEnvironment()

    var body: some Scene {
        MenuBarExtra {
            PopoverRootView()
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
