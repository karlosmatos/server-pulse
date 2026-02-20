import SwiftUI

struct ProcessListView: View {
    @Environment(AppEnvironment.self) private var appEnv

    private var title: String {
        let filter = (appEnv.selectedServer?.processFilter ?? "").trimmingCharacters(in: .whitespaces)
        let label = filter.isEmpty ? "Top Processes" : "\(filter.capitalized) Processes"
        return "\(label) (\(appEnv.processes.count))"
    }

    var body: some View {
        SectionCard(icon: "terminal", title: title, tint: .purple) {
            VStack(spacing: 6) {
                ForEach(appEnv.processes) { proc in
                    ProcessRow(proc: proc)
                    if proc.id != appEnv.processes.last?.id {
                        Divider().opacity(0.3)
                    }
                }
            }
        }
    }
}

private struct ProcessRow: View {
    let proc: ServerProcess

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.caption2).foregroundStyle(.purple.opacity(0.7)).frame(width: 14)

            VStack(alignment: .leading, spacing: 2) {
                Text(proc.displayName).font(.caption).fontWeight(.medium).lineLimit(1)
                Text("PID \(proc.id)").font(.caption2).fontDesign(.monospaced).foregroundStyle(.tertiary)
            }
            Spacer()

            HStack(spacing: 12) {
                StatChip(label: "CPU", value: proc.cpuPercent, warn: proc.cpuPercent > 50)
                StatChip(label: "MEM", value: proc.memPercent, warn: proc.memPercent > 70)
            }
        }
        .padding(.vertical, 2)
    }
}

struct StatChip: View {
    let label: String
    let value: Double
    let warn: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%.1f%%", value))
                .font(.caption2).fontDesign(.rounded).monospacedDigit().fontWeight(.medium)
                .foregroundStyle(warn ? .orange : .primary)
            Text(label).font(.system(size: 9)).foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background((warn ? Color.orange : .secondary).opacity(0.08), in: RoundedRectangle(cornerRadius: 5))
    }
}
