import SwiftUI

@main
struct ServerPulseApp: App {
    @State private var appEnv = AppEnvironment()

    var body: some Scene {
        MenuBarExtra {
            PopoverRootView()
                .environment(appEnv)
        } label: {
            MenuBarLabel(status: appEnv.worstStatus)
        }
        .menuBarExtraStyle(.window)
    }
}
