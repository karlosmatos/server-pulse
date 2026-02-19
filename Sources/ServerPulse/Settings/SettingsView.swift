import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var appEnv
    @Binding var isPresented: Bool

    @State private var sshHost = ""
    @State private var sshUser = ""
    @State private var sshKeyPath = ""
    @State private var sshPort = ""
    @State private var n8nBaseURL = ""
    @State private var n8nAPIKey = ""
    @State private var pollInterval = 30.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionCard(icon: "lock.shield", title: "SSH Connection", tint: .blue) {
                    VStack(spacing: 10) {
                        field("Host", $sshHost, "IP or hostname")
                        field("User", $sshUser, "root")
                        field("Port", $sshPort, "22")
                        field("SSH Key", $sshKeyPath, "~/.ssh/id_ed25519")
                    }
                }

                SectionCard(icon: "flowchart", title: "n8n API", tint: .orange) {
                    VStack(spacing: 10) {
                        field("Base URL", $n8nBaseURL, "http://host:5678")
                        HStack(spacing: 8) {
                            Text("API Key").font(.caption).foregroundStyle(.secondary).frame(width: 56, alignment: .trailing)
                            SecureField("Paste n8n API key", text: $n8nAPIKey).textFieldStyle(.roundedBorder).font(.caption)
                        }
                    }
                }

                SectionCard(icon: "clock.arrow.2.circlepath", title: "Polling", tint: .green) {
                    VStack(spacing: 6) {
                        Slider(value: $pollInterval, in: 10...300, step: 5)
                        Text("Every \(Int(pollInterval)) seconds")
                            .font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .center)
                    }
                }

                Button { save() } label: {
                    Text("Save").font(.subheadline).fontWeight(.medium).frame(maxWidth: .infinity).padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .onAppear {
            let s = appEnv.settings
            sshHost = s.sshHost; sshUser = s.sshUser; sshKeyPath = s.sshKeyPath
            sshPort = String(s.sshPort); n8nBaseURL = s.n8nBaseURL; n8nAPIKey = s.n8nAPIKey
            pollInterval = s.pollingInterval
        }
    }

    private func field(_ label: String, _ text: Binding<String>, _ placeholder: String) -> some View {
        HStack(spacing: 8) {
            Text(label).font(.caption).foregroundStyle(.secondary).frame(width: 56, alignment: .trailing)
            TextField(placeholder, text: text).textFieldStyle(.roundedBorder).font(.caption)
        }
    }

    private func save() {
        let s = appEnv.settings
        s.sshHost = sshHost; s.sshUser = sshUser; s.sshKeyPath = sshKeyPath
        s.sshPort = Int(sshPort) ?? 22; s.n8nBaseURL = n8nBaseURL; s.n8nAPIKey = n8nAPIKey
        s.pollingInterval = pollInterval
        appEnv.startPolling()
        isPresented = false
    }
}
