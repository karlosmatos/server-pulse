import SwiftUI

struct GaugesView: View {
    @Environment(AppEnvironment.self) private var appEnv

    var body: some View {
        SectionCard(icon: "gauge.with.dots.needle.33percent", title: "System", tint: .blue) {
            if let s = appEnv.stats {
                VStack(spacing: 10) {
                    GaugeRow(icon: "cpu", label: "CPU", value: s.cpuUsage / 100,
                             detail: String(format: "%.1f%%", s.cpuUsage))
                    GaugeRow(icon: "memorychip", label: "Memory", value: s.ramUsagePercent / 100,
                             detail: formatMemory(used: s.ramUsed, total: s.ramTotal))
                    GaugeRow(icon: "internaldrive", label: "Disk", value: s.diskUsagePercent / 100,
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
                .font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.vertical, 4)
            }
        }
    }

    private func formatMemory(used: Int, total: Int) -> String {
        guard total >= 1024 else { return "\(used) / \(total) MB" }
        return String(format: "%.1f / %.1f GB", Double(used) / 1024, Double(total) / 1024)
    }
}

private struct GaugeRow: View {
    let icon: String
    let label: String
    let value: Double
    let detail: String

    private var color: Color {
        if value >= 0.85 { return .red }
        if value >= 0.60 { return .orange }
        return .primary
    }

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption2).foregroundStyle(.secondary).frame(width: 14)
                Text(label).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(detail).font(.caption).fontDesign(.rounded).monospacedDigit().fontWeight(.medium)
                    .foregroundStyle(color)
            }
            GaugeBar(value: value)
        }
    }
}
