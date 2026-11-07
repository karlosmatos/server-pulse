import SwiftUI

@MainActor
struct N8NView: View {
    @Environment(AppEnvironment.self) private var appEnv
    @State private var expanded = false

    private var workflows: [N8NWorkflow] { appEnv.workflows }
    private var limit: Int { 5 }
    private var activeCount: Int { workflows.reduce(into: 0) { $0 += $1.active ? 1 : 0 } }
    private var visibleWorkflows: [N8NWorkflow] { expanded ? workflows : Array(workflows.prefix(limit)) }
    private var recentExecutions: ArraySlice<N8NExecution> { appEnv.recentExecutions.prefix(5) }

    var body: some View {
        SectionCard(icon: "point.3.connected.trianglepath.dotted", title: "n8n", tint: .brand) {
            Text("\(activeCount)/\(workflows.count) active")
                .font(.system(size: 11)).monospacedDigit().foregroundStyle(.tertiary)
        } content: {
            if workflows.isEmpty && appEnv.recentExecutions.isEmpty {
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
        .font(.system(size: 12)).frame(maxWidth: .infinity).padding(.vertical, 2)
    }

    @ViewBuilder
    private var workflowSection: some View {
        if !workflows.isEmpty {
            VStack(spacing: 0) {
                ForEach(visibleWorkflows) { wf in WorkflowRow(workflow: wf) }
            }

            if workflows.count > limit {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8, weight: .semibold))
                        Text(expanded ? "Show less" : "\(workflows.count - limit) more workflows…")
                    }
                    .font(.system(size: 11)).foregroundStyle(Color.brand)
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
                Text("Recent runs").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                ForEach(recentExecutions) { exec in ExecutionRow(execution: exec) }
            }
        }
    }
}

// MARK: - Subviews

private struct WorkflowRow: View {
    let workflow: N8NWorkflow

    var body: some View {
        DotRow(
            color: workflow.active ? .brand : .gray.opacity(0.5),
            name: workflow.name,
            value: workflow.active ? "active" : "inactive",
            valueColor: workflow.active ? .secondary : Color.secondary.opacity(0.6)
        )
    }
}

private struct ExecutionRow: View {
    let execution: N8NExecution

    private var color: Color {
        switch execution.status {
        case "success": .brand
        case "error", "crashed": .down
        case "running": .accentBlue
        case "waiting": .warn
        default: .gray
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(execution.workflowName ?? "Workflow \(execution.id)")
                .font(.system(size: 12)).lineLimit(1)
            Spacer(minLength: 4)
            Text(execution.status)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(color)
                .padding(.horizontal, 6).padding(.vertical, 1)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            if let date = execution.startedAt {
                Text(date, style: .relative)
                    .font(.system(size: 11)).monospacedDigit().foregroundStyle(.tertiary)
                    .frame(width: 64, alignment: .trailing)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
    }
}
