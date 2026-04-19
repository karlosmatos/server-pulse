import SwiftUI

@MainActor
struct PopoverRootView: View {
    @Environment(AppEnvironment.self) private var appEnv
    @State private var showSettings = false
    @State private var spinning = false
    @State private var terminalLaunchIssue: TerminalLaunchIssue?
    @State private var terminalLaunchIssueDismissTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.4)
            if let issue = terminalLaunchIssue {
                terminalLaunchBanner(issue)
            }

            if showSettings {
                SettingsView().environment(appEnv)
            } else {
                mainContent
            }

            Divider().opacity(0.4)
            footer
        }
        .frame(width: 420, height: 700)
        .onChange(of: appEnv.isLoading) { _, val in spinning = val }
        .onDisappear {
            terminalLaunchIssueDismissTask?.cancel()
        }
    }

    // MARK: - Sections

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 10) {
                if appEnv.servers.count > 1 {
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
                ForEach(appEnv.servers) { server in
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
                    Text(t, style: .relative).font(.caption2).foregroundStyle(.tertiary)
                        .contentTransition(.numericText())
                }
                headerButton("terminal.fill") {
                    if let config = appEnv.selectedServer {
                        presentTerminalLaunchIssue(
                            TerminalLauncher.openSSH(config: config, terminalApp: appEnv.settings.terminalApp)
                        )
                    }
                }
                .help("Open SSH session in \(appEnv.settings.terminalApp == "iterm" ? "iTerm2" : "Terminal.app")")
                .disabled({
                    guard let s = appEnv.selectedServer else { return true }
                    return s.sshHost.isEmpty || s.sshUser.isEmpty
                }())

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

    private func presentTerminalLaunchIssue(_ issue: TerminalLaunchIssue?) {
        terminalLaunchIssueDismissTask?.cancel()
        withAnimation(.easeInOut(duration: 0.18)) {
            terminalLaunchIssue = issue
        }

        guard issue != nil else { return }
        terminalLaunchIssueDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.18)) {
                terminalLaunchIssue = nil
            }
        }
    }

    private func dismissTerminalLaunchIssue() {
        terminalLaunchIssueDismissTask?.cancel()
        withAnimation(.easeInOut(duration: 0.18)) {
            terminalLaunchIssue = nil
        }
    }

    private func terminalLaunchBanner(_ issue: TerminalLaunchIssue) -> some View {
        let tint: Color = issue.severity == .error ? .red : .orange
        let icon = issue.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill"

        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(tint)
                .padding(.top, 2)

            Text(issue.message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                dismissTerminalLaunchIssue()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(tint.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(tint.opacity(0.22), lineWidth: 1)
                )
        )
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
