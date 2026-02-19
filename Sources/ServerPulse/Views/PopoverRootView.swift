import SwiftUI

struct PopoverRootView: View {
    @Environment(AppEnvironment.self) private var appEnv
    @State private var showSettings = false
    @State private var spinning = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.4)

            if showSettings {
                SettingsView(isPresented: $showSettings).environment(appEnv)
            } else {
                mainContent
            }

            Divider().opacity(0.4)
            footer
        }
        .frame(width: 420, height: 700)
        .onChange(of: appEnv.isLoading) { _, val in spinning = val }
    }

    // MARK: - Sections

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 10) {
                ServerHeaderView()
                GaugesView()
                if !appEnv.processes.isEmpty { ProcessListView() }
                if !appEnv.workflows.isEmpty || !appEnv.recentExecutions.isEmpty { N8NView() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            if showSettings {
                headerButton("chevron.left") {
                    withAnimation(.easeInOut(duration: 0.2)) { showSettings = false }
                }
                Text("Settings").font(.headline)
            } else {
                Image(systemName: "server.rack").foregroundStyle(.blue).font(.callout).fontWeight(.medium)
                Text("ServerPulse").font(.headline)
            }

            Spacer()

            if !showSettings {
                if let t = appEnv.lastUpdated, !appEnv.isLoading {
                    Text(t, style: .relative).font(.caption2).foregroundStyle(.tertiary)
                        .contentTransition(.numericText())
                }
                headerButton("terminal.fill") { TerminalLauncher.openSSH(settings: appEnv.settings) }
                    .help("Open SSH session in Terminal")
                    .disabled(appEnv.settings.sshHost.isEmpty)

                Button { appEnv.refreshNow() } label: {
                    Image(systemName: "arrow.clockwise").font(.callout).fontWeight(.medium)
                        .rotationEffect(.degrees(spinning ? 360 : 0))
                        .animation(spinning ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: spinning)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
            }

            headerButton(showSettings ? "xmark" : "gearshape") {
                withAnimation(.easeInOut(duration: 0.2)) { showSettings.toggle() }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button { NSApplication.shared.terminate(nil) } label: {
                Text("Quit ServerPulse").font(.caption).foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func headerButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.callout).fontWeight(.medium)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }
}
