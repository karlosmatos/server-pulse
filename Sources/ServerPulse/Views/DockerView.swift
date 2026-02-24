import SwiftUI

struct DockerView: View {
    @Environment(AppEnvironment.self) private var appEnv

    private var containers: [DockerContainer] { appEnv.dockerContainers }

    var body: some View {
        SectionCard(icon: "shippingbox", title: "Docker", tint: .cyan) {
            HStack(spacing: 6) {
                CountBadge(count: containers.filter(\.isRunning).count, color: .green)
                CountBadge(count: containers.filter { !$0.isRunning }.count, color: .gray)
            }
        } content: {
            VStack(spacing: 6) {
                ForEach(containers) { container in
                    ContainerRow(container: container)
                    if container.id != containers.last?.id {
                        Divider().opacity(0.3)
                    }
                }
            }
        }
    }
}

private struct ContainerRow: View {
    let container: DockerContainer

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: container.isRunning ? "shippingbox.fill" : "shippingbox")
                .font(.caption2)
                .foregroundStyle(container.isRunning ? .cyan.opacity(0.7) : .gray.opacity(0.5))
                .frame(width: 14)

            VStack(alignment: .leading, spacing: 2) {
                Text(container.name).font(.caption).fontWeight(.medium).lineLimit(1)
                Text(container.image).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
            }
            Spacer()

            if container.isRunning {
                HStack(spacing: 12) {
                    StatChip(label: "CPU", value: container.cpuPercent, warn: container.cpuPercent > 50)
                    StatChip(label: "MEM", value: container.memPercent, warn: container.memPercent > 70)
                }
            } else {
                Text(container.status.capitalized)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.gray.opacity(0.12), in: Capsule())
            }
        }
        .padding(.vertical, 2)
    }
}
