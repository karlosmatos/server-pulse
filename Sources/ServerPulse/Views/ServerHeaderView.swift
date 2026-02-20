import SwiftUI

struct ServerHeaderView: View {
    @Environment(AppEnvironment.self) private var appEnv

    private var status: ServerStatus { appEnv.serverStatus }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                PulsingDot(color: status.color, isActive: status == .online)

                VStack(alignment: .leading, spacing: 4) {
                    Text(appEnv.selectedServer?.name ?? "Not configured")
                        .font(.title2).fontWeight(.bold).fontDesign(.rounded)

                    HStack(spacing: 6) {
                        Text(status.label)
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(status.color)
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(status.color.opacity(0.15), in: Capsule())

                        if let host = appEnv.selectedServer?.sshHost, !host.isEmpty {
                            Text(host).font(.caption).foregroundStyle(.secondary)
                        }

                        if let stats = appEnv.stats {
                            Image(systemName: "clock").font(.caption2).foregroundStyle(.tertiary)
                            Text(stats.uptime).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
            }

            if let err = appEnv.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.caption2).foregroundStyle(.orange)
                    Text(err).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary.opacity(0.5))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(status.color.opacity(0.06))
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
