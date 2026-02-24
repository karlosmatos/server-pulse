import SwiftUI

struct N8NView: View {
    @Environment(AppEnvironment.self) private var appEnv
    @State private var expanded = false

    var body: some View {
        SectionCard(icon: "flowchart", title: "n8n", tint: .orange) {
            HStack(spacing: 6) {
                CountBadge(count: appEnv.workflows.filter(\.active).count, color: .green)
                CountBadge(count: appEnv.workflows.filter { !$0.active }.count, color: .gray)
            }
        } content: {
            if appEnv.workflows.isEmpty && appEnv.recentExecutions.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    workflowSection
                    executionSection
                }
            }
        }
    }

    private var emptyState: some View {
        HStack(spacing: 6) {
            Image(systemName: "key").foregroundStyle(.tertiary)
            Text("Configure API key in Settings").foregroundStyle(.secondary)
        }
        .font(.caption).frame(maxWidth: .infinity).padding(.vertical, 2)
    }

    @ViewBuilder
    private var workflowSection: some View {
        if !appEnv.workflows.isEmpty {
            let visible = expanded ? appEnv.workflows : Array(appEnv.workflows.prefix(5))
            ForEach(visible) { wf in WorkflowRow(workflow: wf) }

            if appEnv.workflows.count > 5 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8, weight: .semibold))
                        Text(expanded ? "Show less" : "\(appEnv.workflows.count - 5) more workflows…")
                    }
                    .font(.caption).foregroundStyle(.orange)
                }
                .buttonStyle(.plain).frame(maxWidth: .infinity).padding(.top, 2)
            }
        }
    }

    @ViewBuilder
    private var executionSection: some View {
        if !appEnv.recentExecutions.isEmpty {
            Divider().opacity(0.3).padding(.vertical, 2)

            HStack(spacing: 4) {
                Image(systemName: "clock.arrow.circlepath").font(.caption2).foregroundStyle(.tertiary)
                Text("Recent").font(.caption).foregroundStyle(.secondary).fontWeight(.medium)
            }

            ForEach(appEnv.recentExecutions.prefix(5)) { exec in ExecutionRow(execution: exec) }
        }
    }
}

// MARK: - Subviews

private struct WorkflowRow: View {
    let workflow: N8NWorkflow
    private var isActive: Bool { workflow.active }
    private var tint: Color { isActive ? .green : .gray }

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(isActive ? tint : tint.opacity(0.4)).frame(width: 7, height: 7)
            Text(workflow.name).font(.caption).lineLimit(1)
            Spacer()
            Text(isActive ? "Active" : "Inactive")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(tint)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(tint.opacity(0.12), in: Capsule())
        }
    }
}

private struct ExecutionRow: View {
    let execution: N8NExecution

    private var meta: (icon: String, color: Color) {
        switch execution.status {
        case "success": ("checkmark.circle.fill", .green)
        case "error":   ("xmark.circle.fill", .red)
        case "running": ("arrow.clockwise.circle.fill", .blue)
        case "waiting": ("hourglass.circle.fill", .orange)
        default:        ("circle", .secondary)
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: meta.icon).font(.caption2).foregroundStyle(meta.color).frame(width: 14)

            VStack(alignment: .leading, spacing: 1) {
                Text(execution.workflowName ?? "Workflow \(execution.id)").font(.caption).lineLimit(1)
                if let date = execution.startedAt {
                    Text(date, style: .relative).font(.caption2).foregroundStyle(.tertiary)
                }
            }
            Spacer()

            Text(execution.status.capitalized)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(meta.color)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(meta.color.opacity(0.12), in: Capsule())
        }
    }
}
