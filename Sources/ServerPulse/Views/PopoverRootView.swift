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
                SettingsView(isPresented: $showSettings)
                    .environment(appEnv)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                mainContent
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            Divider().opacity(0.4)
            footer
        }
        .frame(width: 380)
        .frame(maxHeight: 600)
        .animation(.easeInOut(duration: 0.2), value: showSettings)
        .onChange(of: appEnv.isLoading) { _, loading in
            if loading {
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    spinning = true
                }
            } else {
                spinning = false
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 10) {
                ServerHeaderView()
                GaugesView()

                if !appEnv.processes.isEmpty {
                    ProcessListView()
                }

                if !appEnv.workflows.isEmpty || !appEnv.recentExecutions.isEmpty {
                    N8NView()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            if showSettings {
                Button {
                    showSettings = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.callout)
                        .fontWeight(.medium)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Text("Settings")
                    .font(.headline)
            } else {
                Image(systemName: "server.rack")
                    .foregroundStyle(.blue)
                    .font(.callout)
                    .fontWeight(.medium)
                Text("ServerPulse")
                    .font(.headline)
            }

            Spacer()

            if !showSettings {
                if let t = appEnv.lastUpdated, !appEnv.isLoading {
                    Text(t, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .contentTransition(.numericText())
                }

                Button { appEnv.refreshNow() } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.callout)
                        .fontWeight(.medium)
                        .rotationEffect(.degrees(spinning ? 360 : 0))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Button { showSettings.toggle() } label: {
                Image(systemName: showSettings ? "xmark" : "gearshape")
                    .font(.callout)
                    .fontWeight(.medium)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Spacer()
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit ServerPulse")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
