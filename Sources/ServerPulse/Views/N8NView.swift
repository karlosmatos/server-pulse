import SwiftUI

struct N8NView: View {
    @Environment(AppEnvironment.self) private var appEnv

    var body: some View {
        SectionCard(icon: "flowchart", title: "n8n", tint: .orange) {
            if appEnv.workflows.isEmpty && appEnv.recentExecutions.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "key")
                        .foregroundStyle(.tertiary)
                    Text("Configure API key in Settings")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    // Workflows
                    if !appEnv.workflows.isEmpty {
                        ForEach(appEnv.workflows) { wf in
                            WorkflowRow(workflow: wf)
                        }
                    }

                    // Executions
                    if !appEnv.recentExecutions.isEmpty {
                        Divider().opacity(0.3).padding(.vertical, 2)

                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text("Recent")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fontWeight(.medium)
                        }

                        ForEach(appEnv.recentExecutions.prefix(5)) { exec in
                            ExecutionRow(execution: exec)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Workflow Row

private struct WorkflowRow: View {
    let workflow: N8NWorkflow

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(workflow.active ? Color.green : Color.gray.opacity(0.4))
                .frame(width: 7, height: 7)

            Text(workflow.name)
                .font(.caption)
                .lineLimit(1)

            Spacer()

            Text(workflow.active ? "Active" : "Inactive")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(workflow.active ? Color.green : Color.gray)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    (workflow.active ? Color.green : Color.gray).opacity(0.12),
                    in: Capsule()
                )
        }
    }
}

// MARK: - Execution Row

private struct ExecutionRow: View {
    let execution: N8NExecution

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
                .frame(width: 14)

            VStack(alignment: .leading, spacing: 1) {
                Text(execution.workflowName ?? "Workflow \(execution.id)")
                    .font(.caption)
                    .lineLimit(1)
                if let date = execution.startedAt {
                    Text(date, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Text(execution.status.capitalized)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.12), in: Capsule())
        }
    }

    private var icon: String {
        switch execution.status {
        case "success": return "checkmark.circle.fill"
        case "error":   return "xmark.circle.fill"
        case "running": return "arrow.clockwise.circle.fill"
        case "waiting": return "hourglass.circle.fill"
        default:        return "circle"
        }
    }

    private var color: Color {
        switch execution.status {
        case "success": return .green
        case "error":   return .red
        case "running": return .blue
        case "waiting": return .orange
        default:        return .secondary
        }
    }
}
