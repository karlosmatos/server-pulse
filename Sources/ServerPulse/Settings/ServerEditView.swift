import SwiftUI

struct ServerEditView: View {
    let config: ServerConfig
    let onDone: (ServerConfig?) -> Void

    @State private var name = ""
    @State private var sshHost = ""
    @State private var sshUser = ""
    @State private var sshKeyPath = ""
    @State private var sshPort = ""
    @State private var n8nBaseURL = ""
    @State private var n8nAPIKey = ""
    @State private var pollInterval = 30.0
    @State private var processCount = "10"
    @State private var processFilter = ""
    @State private var dockerEnabled = false
    @State private var systemdServices = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionCard(icon: "tag", title: "Name", tint: .blue) {
                    field("Name", $name, "Production, Staging, ...")
                }

                SectionCard(icon: "lock.shield", title: "SSH Connection", tint: .blue) {
                    VStack(spacing: 10) {
                        field("Host", $sshHost, "IP or hostname")
                        field("User", $sshUser, "root")
                        field("Port", $sshPort, "22")
                        field("SSH Key", $sshKeyPath, "~/.ssh/id_ed25519")
                    }
                }

                SectionCard(icon: "terminal", title: "Processes", tint: .purple) {
                    VStack(spacing: 10) {
                        field("Count", $processCount, "10")
                        field("Filter", $processFilter, "Leave empty for top by CPU")
                    }
                }

                SectionCard(icon: "shippingbox", title: "Docker", tint: .cyan) {
                    Toggle("Enable Docker monitoring", isOn: $dockerEnabled)
                        .font(.caption)
                }

                SectionCard(icon: "gearshape.2", title: "Systemd Services", tint: .indigo) {
                    VStack(spacing: 6) {
                        field("Services", $systemdServices, "nginx, redis, postgresql")
                        Text("Comma-separated service names")
                            .font(.caption2).foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 64)
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

                HStack(spacing: 10) {
                    Button { onDone(nil) } label: {
                        Text("Cancel").font(.subheadline).fontWeight(.medium).frame(maxWidth: .infinity).padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)

                    Button { save() } label: {
                        Text("Save").font(.subheadline).fontWeight(.medium).frame(maxWidth: .infinity).padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .onAppear {
            name = config.name
            sshHost = config.sshHost
            sshUser = config.sshUser
            sshKeyPath = config.sshKeyPath
            sshPort = config.sshPort == 22 && config.sshHost.isEmpty ? "" : String(config.sshPort)
            n8nBaseURL = config.n8nBaseURL
            n8nAPIKey = config.n8nAPIKey
            pollInterval = config.pollingInterval
            processCount = String(config.processCount)
            processFilter = config.processFilter
            dockerEnabled = config.dockerEnabled
            systemdServices = config.systemdServices
        }
    }

    private func field(_ label: String, _ text: Binding<String>, _ placeholder: String) -> some View {
        HStack(spacing: 8) {
            Text(label).font(.caption).foregroundStyle(.secondary).frame(width: 56, alignment: .trailing)
            TextField(placeholder, text: text).textFieldStyle(.roundedBorder).font(.caption)
        }
    }

    private func save() {
        var updated = config
        updated.name = name.isEmpty ? sshHost : name
        updated.sshHost = sshHost
        updated.sshUser = sshUser
        updated.sshKeyPath = sshKeyPath
        updated.sshPort = Int(sshPort) ?? 22
        updated.n8nBaseURL = n8nBaseURL
        updated.n8nAPIKey = n8nAPIKey
        updated.pollingInterval = pollInterval
        updated.processCount = Int(processCount) ?? 10
        updated.processFilter = processFilter
        updated.dockerEnabled = dockerEnabled
        updated.systemdServices = systemdServices
        onDone(updated)
    }
}
