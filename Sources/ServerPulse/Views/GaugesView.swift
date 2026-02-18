import SwiftUI

struct GaugesView: View {
    @Environment(AppEnvironment.self) private var appEnv

    var body: some View {
        SectionCard(icon: "gauge.with.dots.needle.33percent", title: "System", tint: .blue) {
            if let s = appEnv.stats {
                VStack(spacing: 10) {
                    GaugeRow(
                        icon: "cpu",
                        label: "CPU",
                        value: s.cpuUsage / 100,
                        detail: String(format: "%.1f%%", s.cpuUsage)
                    )
                    GaugeRow(
                        icon: "memorychip",
                        label: "Memory",
                        value: s.ramUsagePercent / 100,
                        detail: formatMemory(used: s.ramUsed, total: s.ramTotal)
                    )
                    GaugeRow(
                        icon: "internaldrive",
                        label: "Disk",
                        value: s.diskUsagePercent / 100,
                        detail: "\(s.diskUsed) / \(s.diskTotal)"
                    )
                }
            } else {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        HStack(spacing: 8) {
            if appEnv.isLoading {
                ProgressView().controlSize(.mini)
                Text("Fetching metrics…")
            } else {
                Image(systemName: "chart.bar.xaxis.ascending")
                    .foregroundStyle(.tertiary)
                Text("Stats unavailable")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func formatMemory(used: Int, total: Int) -> String {
        if total >= 1024 {
            let u = String(format: "%.1f", Double(used) / 1024)
            let t = String(format: "%.1f", Double(total) / 1024)
            return "\(u) / \(t) GB"
        }
        return "\(used) / \(total) MB"
    }
}

// MARK: - GaugeRow

private struct GaugeRow: View {
    let icon: String
    let label: String
    let value: Double   // 0–1
    let detail: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 14)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(detail)
                    .font(.caption)
                    .fontDesign(.rounded)
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
            GaugeBar(value: value)
        }
    }
}
