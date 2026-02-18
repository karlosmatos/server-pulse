import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var appEnv
    @Environment(\.dismiss) private var dismiss

    @State private var sshHost      = ""
    @State private var sshUser      = ""
    @State private var sshKeyPath   = ""
    @State private var sshPort      = ""
    @State private var n8nBaseURL   = ""
    @State private var n8nAPIKey    = ""
    @State private var pollInterval = 30.0

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(.secondary)
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    save()
                    dismiss()
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()

            Divider()

            Form {
                Section {
                    LabeledContent("Host") {
                        TextField("IP or hostname", text: $sshHost)
                            .textFieldStyle(.roundedBorder)
                    }
                    LabeledContent("User") {
                        TextField("root", text: $sshUser)
                            .textFieldStyle(.roundedBorder)
                    }
                    LabeledContent("Port") {
                        TextField("22", text: $sshPort)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                    LabeledContent("SSH Key") {
                        TextField("~/.ssh/id_ed25519", text: $sshKeyPath)
                            .textFieldStyle(.roundedBorder)
                    }
                } header: {
                    Label("SSH Connection", systemImage: "lock.shield")
                }

                Section {
                    LabeledContent("Base URL") {
                        TextField("http://host:5678", text: $n8nBaseURL)
                            .textFieldStyle(.roundedBorder)
                    }
                    LabeledContent("API Key") {
                        SecureField("Paste n8n API key", text: $n8nAPIKey)
                            .textFieldStyle(.roundedBorder)
                    }
                } header: {
                    Label("n8n API", systemImage: "flowchart")
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Slider(value: $pollInterval, in: 10...300, step: 5) {
                            Text("Poll interval")
                        }
                        Text("Every \(Int(pollInterval)) seconds")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("Polling", systemImage: "clock.arrow.2.circlepath")
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 420, height: 480)
        .onAppear(perform: load)
    }

    private func load() {
        let s = appEnv.settings
        sshHost      = s.sshHost
        sshUser      = s.sshUser
        sshKeyPath   = s.sshKeyPath
        sshPort      = String(s.sshPort)
        n8nBaseURL   = s.n8nBaseURL
        n8nAPIKey    = s.n8nAPIKey
        pollInterval = s.pollingInterval
    }

    private func save() {
        let s = appEnv.settings
        s.sshHost         = sshHost
        s.sshUser         = sshUser
        s.sshKeyPath      = sshKeyPath
        s.sshPort         = Int(sshPort) ?? 22
        s.n8nBaseURL      = n8nBaseURL
        s.n8nAPIKey       = n8nAPIKey
        s.pollingInterval = pollInterval
        appEnv.startPolling()
    }
}
