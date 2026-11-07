import SwiftUI

@MainActor
struct ServerHeaderView: View {
    @Environment(AppEnvironment.self) private var appEnv

    private var status: ServerStatus { appEnv.serverStatus }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                PulsingDot(color: status.color, isActive: status == .online)

                VStack(alignment: .leading, spacing: 4) {
                    Text(appEnv.selectedServer?.name ?? "Not configured")
                        .font(.system(size: 17, weight: .bold))
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(status.label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(status.color)
                            .padding(.horizontal, 8).padding(.vertical, 1)
                            .background(status.color.opacity(0.15), in: Capsule())

                        if let host = appEnv.selectedServer?.sshHost, !host.isEmpty {
                            Text(host).lineLimit(1)
                        }

                        if let stats = appEnv.stats {
                            Image(systemName: "clock").font(.system(size: 10))
                            Text(stats.uptime).lineLimit(1)
                        }
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }

            if let err = appEnv.errorMessage {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color.warn)
                    Text(err).foregroundStyle(.secondary)
                }
                .font(.system(size: 11))
                .padding(.top, 8)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(status.color.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
