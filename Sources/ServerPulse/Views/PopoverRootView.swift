import SwiftUI

struct PopoverRootView: View {
    @Environment(AppEnvironment.self) private var appEnv
    @State private var showSettings = false
    @State private var spinning = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.4)

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

            Divider().opacity(0.4)
            footer
        }
        .frame(width: 380)
        .frame(maxHeight: 600)
        .sheet(isPresented: $showSettings) {
            SettingsView().environment(appEnv)
        }
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

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "server.rack")
                .foregroundStyle(.blue)
                .font(.callout)
                .fontWeight(.medium)
            Text("ServerPulse")
                .font(.headline)

            Spacer()

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

            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
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
