import SwiftUI

struct ServerHeaderView: View {
    @Environment(AppEnvironment.self) private var appEnv

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                PulsingDot(
                    color: appEnv.serverStatus.color,
                    isActive: appEnv.serverStatus == .online
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(appEnv.settings.sshHost.isEmpty ? "Not configured" : appEnv.settings.sshHost)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)

                    HStack(spacing: 4) {
                        Text(appEnv.serverStatus.label)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(appEnv.serverStatus.color)
                        if let stats = appEnv.stats {
                            Text("·")
                                .foregroundStyle(.tertiary)
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(stats.uptime)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()
            }

            if let err = appEnv.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .animation(.easeInOut(duration: 0.3), value: appEnv.serverStatus.label)
    }
}
