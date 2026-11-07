import SwiftUI

@MainActor
struct ProcessListView: View {
    @Environment(AppEnvironment.self) private var appEnv

    private var title: String {
        let filter = (appEnv.selectedServer?.processFilter ?? "").trimmingCharacters(in: .whitespaces)
        return filter.isEmpty ? "Top Processes" : "\(filter.capitalized) Processes"
    }

    var body: some View {
        SectionCard(icon: "line.3.horizontal", title: title, tint: .brand) {
            Text("\(appEnv.processes.count)")
                .font(.system(size: 11)).monospacedDigit().foregroundStyle(.tertiary)
        } content: {
            VStack(spacing: 0) {
                ProcessTableRow(pid: "PID", name: "NAME", cpu: "CPU", mem: "MEM", isHeader: true)
                    .padding(.bottom, 4)
                ForEach(appEnv.processes) { proc in
                    ProcessTableRow(
                        pid: "\(proc.id)",
                        name: proc.displayName,
                        cpu: String(format: "%.1f", proc.cpuPercent),
                        mem: String(format: "%.1f", proc.memPercent),
                        cpuWarn: proc.cpuPercent > 50,
                        memWarn: proc.memPercent > 70
                    )
                }
            }
        }
    }
}

private struct ProcessTableRow: View {
    let pid: String
    let name: String
    let cpu: String
    let mem: String
    var cpuWarn = false
    var memWarn = false
    var isHeader = false

    var body: some View {
        HStack(spacing: 8) {
            Text(pid).frame(width: 52, alignment: .leading).foregroundStyle(.tertiary)
            Text(name)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(isHeader ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.primary.opacity(0.75)))
                .lineLimit(1).truncationMode(.middle)
            Text(cpu).frame(width: 40, alignment: .trailing)
                .foregroundStyle(cpuWarn ? AnyShapeStyle(Color.warn) : AnyShapeStyle(isHeader ? .tertiary : .secondary))
            Text(mem).frame(width: 40, alignment: .trailing)
                .foregroundStyle(memWarn ? AnyShapeStyle(Color.warn) : AnyShapeStyle(isHeader ? .tertiary : .secondary))
        }
        .font(.system(size: isHeader ? 10 : 11, design: .monospaced))
        .monospacedDigit()
        .padding(.vertical, isHeader ? 0 : 3)
    }
}
