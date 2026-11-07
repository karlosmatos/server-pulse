import SwiftUI

@MainActor
struct GaugesView: View {
    @Environment(AppEnvironment.self) private var appEnv

    var body: some View {
        SectionCard(icon: "gauge.with.dots.needle.33percent", title: "System", tint: .accentBlue) {
            if let s = appEnv.stats {
                VStack(spacing: 10) {
                    GaugeRow(label: "CPU", value: s.cpuUsage / 100,
                             detail: String(format: "%.1f%%", s.cpuUsage))
                    GaugeRow(label: "Memory", value: s.ramUsagePercent / 100,
                             detail: formatMemory(used: s.ramUsed, total: s.ramTotal))
                    GaugeRow(label: "Disk", value: s.diskUsagePercent / 100,
                             detail: "\(s.diskUsed) / \(s.diskTotal)")
                }
            } else {
                HStack(spacing: 8) {
                    if appEnv.isLoading {
                        ProgressView().controlSize(.mini)
                        Text("Fetching metrics…")
                    } else {
                        Image(systemName: "chart.bar.xaxis.ascending").foregroundStyle(.tertiary)
                        Text("Stats unavailable")
                    }
                }
                .font(.system(size: 12)).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity).padding(.vertical, 4)
            }
        }
    }

    private func formatMemory(used: Int, total: Int) -> String {
        guard total >= 1024 else { return "\(used) / \(total) MB" }
        return String(format: "%.1f / %.1f GB", Double(used) / 1024, Double(total) / 1024)
    }
}

private struct GaugeRow: View {
    let label: String
    let value: Double
    let detail: String

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label).foregroundStyle(.secondary)
                Spacer()
                Text(detail).fontWeight(.medium).monospacedDigit()
                    .foregroundStyle(value >= 0.60 ? Color.usage(value) : .primary)
            }
            .font(.system(size: 12))
            GaugeBar(value: value)
        }
    }
}
