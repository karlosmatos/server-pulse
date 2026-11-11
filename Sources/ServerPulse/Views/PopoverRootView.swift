import Sparkle
import SwiftUI

@MainActor
struct PopoverRootView: View {
    let updater: SPUUpdater
    @Environment(AppEnvironment.self) private var appEnv
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showSettings = false
    @State private var refreshRotation = 0.0
    @State private var terminalLaunchIssue: TerminalLaunchIssue?
    @State private var terminalLaunchIssueDismissTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            if showSettings {
                settingsHeader
                Divider().opacity(0.4)
            }
            if let issue = terminalLaunchIssue {
                terminalLaunchBanner(issue)
            }

            if showSettings {
                SettingsView().environment(appEnv)
            } else {
                mainContent
            }

            footer
        }
        .frame(width: 420, height: 700)
        .onChange(of: appEnv.isLoading) { _, isLoading in
            guard isLoading else { return }
            triggerRefreshAnimation()
        }
        .onDisappear {
            terminalLaunchIssueDismissTask?.cancel()
        }
    }

    // MARK: - Sections

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 8) {
                if appEnv.servers.count > 1 {
                    serverPicker.padding(.bottom, 2)
                }
                ServerHeaderView()
                GaugesView()
                containersAndServices
                if showsSecurity, hasCriticalSecurityIssue { SecurityView() }
                if !appEnv.processes.isEmpty { ProcessListView() }
                if !appEnv.workflows.isEmpty || !appEnv.recentExecutions.isEmpty { N8NView() }
                // Security changes rarely, so it sits at the bottom unless something is critical.
                if showsSecurity, !hasCriticalSecurityIssue { SecurityView() }
            }
            .padding(12)
        }
    }

    private var showsSecurity: Bool {
        appEnv.selectedServer?.securityAuditEnabled == true && !appEnv.securityChecks.isEmpty
    }

    private var hasCriticalSecurityIssue: Bool {
        appEnv.activeSecurityChecks.contains { $0.severity == .critical }
    }

    /// Docker and systemd sit side by side when both are present, as on the website.
    @ViewBuilder
    private var containersAndServices: some View {
        let hasDocker = !appEnv.dockerContainers.isEmpty
        let hasServices = !appEnv.systemdServices.isEmpty
        if hasDocker && hasServices {
            HStack(alignment: .top, spacing: 8) {
                DockerView()
                SystemdServicesView()
            }
        } else if hasDocker {
            DockerView()
        } else if hasServices {
            SystemdServicesView()
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
                        HStack(spacing: 6) {
                            Circle()
                                .fill((state?.status ?? .unknown).color)
                                .frame(width: 6, height: 6)
                            Text(server.name)
                                .font(.system(size: 11.5, weight: isSelected ? .medium : .regular))
                                .foregroundStyle(isSelected ? .primary : .secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(isSelected ? Color.trackFill : .clear, in: Capsule())
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var settingsHeader: some View {
        HStack(spacing: 8) {
            footerButton("chevron.left", help: "Back") {
                withAnimation(.easeInOut(duration: 0.2)) { showSettings = false }
            }
            Text("Settings").font(.system(size: 13, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button { updater.checkForUpdates() } label: {
                Text("Check for Updates…")
            }
            .buttonStyle(.plain)

            Spacer()

            if !showSettings {
                if let t = appEnv.lastUpdated, !appEnv.isLoading {
                    Text(t, style: .relative)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }

                Button {
                    let wasLoading = appEnv.isLoading
                    appEnv.refreshNow()
                    if wasLoading {
                        triggerRefreshAnimation()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(refreshRotation))
                        .animation(.linear(duration: 0.45), value: refreshRotation)
                }
                .buttonStyle(.plain)
                .help("Refresh now")

                footerButton("apple.terminal", help: "Open SSH session in \(TerminalLauncher.displayName(for: appEnv.settings.terminalApp))") {
                    if let config = appEnv.selectedServer {
                        presentTerminalLaunchIssue(
                            TerminalLauncher.openSSH(
                                config: config,
                                terminalApp: appEnv.settings.terminalApp,
                                onDeferredIssue: { issue in
                                    presentTerminalLaunchIssue(issue)
                                }
                            )
                        )
                    }
                }
                .disabled({
                    guard let s = appEnv.selectedServer else { return true }
                    return s.sshHost.isEmpty || s.sshUser.isEmpty
                }())
            }

            footerButton(showSettings ? "xmark" : "gearshape", help: showSettings ? "Close settings" : "Settings") {
                withAnimation(.easeInOut(duration: 0.2)) { showSettings.toggle() }
            }

            footerButton("power", help: "Quit ServerPulse") {
                NSApplication.shared.terminate(nil)
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    // MARK: - Helpers

    private func footerButton(_ icon: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 12))
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private func triggerRefreshAnimation() {
        guard !reduceMotion else { return }
        refreshRotation += 360
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
        let tint: Color = issue.severity == .error ? .down : .warn
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
