import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var appEnv

    @State private var editingServer: ServerConfig?
    @State private var serverToDelete: ServerConfig?
    @State private var terminalApp = "terminal"

    var body: some View {
        if let editing = editingServer {
            ServerEditView(config: editing) { updated in
                if let updated {
                    if appEnv.settings.servers.contains(where: { $0.id == updated.id }) {
                        appEnv.updateServer(updated)
                    } else {
                        appEnv.addServer(updated)
                    }
                }
                editingServer = nil
            }
        } else {
            serverList
        }
    }

    // MARK: - Server list + global settings

    private var serverList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionCard(icon: "server.rack", title: "Servers", tint: .blue) {
                    VStack(spacing: 6) {
                        ForEach(appEnv.settings.servers) { server in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill((appEnv.serverStates[server.id]?.status ?? .unknown).color)
                                    .frame(width: 8, height: 8)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(server.name).font(.caption).fontWeight(.medium)
                                    Text(server.sshHost).font(.caption2).foregroundStyle(.tertiary)
                                }

                                Spacer()

                                Button {
                                    editingServer = server
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    serverToDelete = server
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption2).foregroundStyle(.red.opacity(0.7))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)

                            if server.id != appEnv.settings.servers.last?.id {
                                Divider().opacity(0.3)
                            }
                        }

                        Button {
                            editingServer = ServerConfig()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill").font(.caption)
                                Text("Add Server").font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.accentColor)
                    }
                }

                SectionCard(icon: "terminal.fill", title: "Terminal", tint: .green) {
                    Picker("App", selection: $terminalApp) {
                        Text("Terminal.app").tag("terminal")
                        Text("iTerm2").tag("iterm")
                    }
                    .pickerStyle(.segmented)
                    .font(.caption)
                    .onChange(of: terminalApp) { _, val in
                        appEnv.settings.terminalApp = val
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .onAppear {
            terminalApp = appEnv.settings.terminalApp
        }
        .confirmationDialog(
            "Remove \"\(serverToDelete?.name ?? "")\"?",
            isPresented: Binding(get: { serverToDelete != nil }, set: { if !$0 { serverToDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let id = serverToDelete?.id { appEnv.removeServer(id) }
                serverToDelete = nil
            }
            Button("Cancel", role: .cancel) { serverToDelete = nil }
        }
    }
}
