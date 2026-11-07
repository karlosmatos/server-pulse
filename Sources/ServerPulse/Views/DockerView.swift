import SwiftUI

@MainActor
struct DockerView: View {
    @Environment(AppEnvironment.self) private var appEnv

    private var containers: [DockerContainer] { appEnv.dockerContainers }
    private var runningCount: Int { containers.reduce(into: 0) { $0 += $1.isRunning ? 1 : 0 } }

    var body: some View {
        SectionCard(icon: "shippingbox", title: "Docker", tint: .accentCyan) {
            Text("\(runningCount)/\(containers.count)")
                .font(.system(size: 11)).monospacedDigit().foregroundStyle(.tertiary)
        } content: {
            VStack(spacing: 0) {
                ForEach(containers) { container in
                    if container.isRunning {
                        DotRow(
                            color: .brand,
                            name: container.name,
                            value: String(format: "%.1f%%", container.cpuPercent),
                            valueColor: container.cpuPercent > 50 ? .warn : .secondary
                        )
                        .help("\(container.image) · CPU \(String(format: "%.1f", container.cpuPercent))% · MEM \(String(format: "%.1f", container.memPercent))%")
                    } else {
                        DotRow(
                            color: .gray.opacity(0.5),
                            name: container.name,
                            value: container.status.components(separatedBy: " ").first?.lowercased() ?? "unknown"
                        )
                        .help(container.image)
                    }
                }
            }
        }
    }
}
