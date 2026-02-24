import SwiftUI

struct PopoverRootView: View {
    @Environment(AppEnvironment.self) private var appEnv
    @State private var showSettings = false

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
    }

    // MARK: - Sections

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 10) {
                if appEnv.settings.servers.count > 1 {
                    serverPicker
                }
                ServerHeaderView()
                GaugesView()
                if !appEnv.processes.isEmpty { ProcessListView() }
                if !appEnv.dockerContainers.isEmpty { DockerView() }
                if !appEnv.systemdServices.isEmpty { SystemdServicesView() }
                if !appEnv.workflows.isEmpty || !appEnv.recentExecutions.isEmpty { N8NView() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    private var serverPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(appEnv.settings.servers) { server in
                    let isSelected = server.id == appEnv.selectedServerID
                    let state = appEnv.serverStates[server.id]

                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            appEnv.selectedServerID = server.id
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Circle()
                                .fill((state?.status ?? .unknown).color)
                                .frame(width: 6, height: 6)
                            Text(server.name)
                                .font(.caption)
                                .fontWeight(isSelected ? .semibold : .regular)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule().strokeBorder(isSelected ? Color.accentColor.opacity(0.4) : .clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
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
                    Text(t, format: .dateTime.hour().minute()).font(.caption2).foregroundStyle(.tertiary)
                }
                headerButton("terminal.fill") {
                    if let config = appEnv.selectedServer {
                        TerminalLauncher.openSSH(config: config, terminalApp: appEnv.settings.terminalApp)
                    }
                }
                .help("Open SSH session in Terminal")
                .disabled(appEnv.selectedServer.map { $0.sshHost.isEmpty || $0.sshUser.isEmpty } ?? true)

                if appEnv.isLoading {
                    ProgressView().controlSize(.small).frame(width: 20)
                } else {
                    Button { appEnv.refreshNow() } label: {
                        Image(systemName: "arrow.clockwise").font(.callout).fontWeight(.medium)
                    }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
                }
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
