import SwiftUI

enum Severity: Int, Comparable {
    case ok
    case warning
    case critical

    static func < (lhs: Severity, rhs: Severity) -> Bool { lhs.rawValue < rhs.rawValue }

    var color: Color {
        switch self {
        case .ok:       return .brand
        case .warning:  return .warn
        case .critical: return .down
        }
    }

    var symbol: String {
        switch self {
        case .ok:       return "checkmark.circle.fill"
        case .warning:  return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
}

/// Shared usage thresholds for CPU, RAM, disk and per-process/container usage.
enum MetricThresholds {
    static let warning = 80.0
    static let critical = 90.0

    static func severity(forPercent percent: Double) -> Severity {
        if percent >= critical { return .critical }
        if percent >= warning { return .warning }
        return .ok
    }
}

struct ServerIssue: Identifiable, Equatable {
    let id: String
    let severity: Severity
    let symbol: String
    let message: String
}

enum ServerHealth {
    /// How long a failed n8n execution keeps being reported as an issue.
    static let executionErrorWindow: TimeInterval = 24 * 60 * 60

    /// Issues sorted most severe first.
    static func issues(for state: ServerState, now: Date = Date()) -> [ServerIssue] {
        if state.status == .offline {
            return [ServerIssue(
                id: "offline",
                severity: .critical,
                symbol: "bolt.horizontal.circle",
                message: state.errorMessage ?? "Server is unreachable"
            )]
        }

        var issues: [ServerIssue] = []

        if let stats = state.stats {
            let metrics: [(id: String, label: String, symbol: String, percent: Double)] = [
                ("disk", "Disk", "internaldrive", stats.diskUsagePercent),
                ("ram", "Memory", "memorychip", stats.ramUsagePercent),
                ("cpu", "CPU", "cpu", stats.cpuUsage),
            ]
            for metric in metrics {
                let severity = MetricThresholds.severity(forPercent: metric.percent)
                guard severity > .ok else { continue }
                issues.append(ServerIssue(
                    id: metric.id,
                    severity: severity,
                    symbol: metric.symbol,
                    message: "\(metric.label) at \(Int(min(metric.percent, 100).rounded())) %"
                ))
            }
        }

        let failedServices = state.systemdServices.filter { $0.state == .failed }
        if !failedServices.isEmpty {
            issues.append(ServerIssue(
                id: "services.failed",
                severity: .critical,
                symbol: "gearshape.2",
                message: listMessage(failedServices.map(\.name), verb: "failed")
            ))
        }

        let inactiveServices = state.systemdServices.filter { $0.state == .inactive }
        if !inactiveServices.isEmpty {
            issues.append(ServerIssue(
                id: "services.inactive",
                severity: .warning,
                symbol: "gearshape.2",
                message: listMessage(inactiveServices.map(\.name), verb: "inactive")
            ))
        }

        let stoppedContainers = state.dockerContainers.filter { !$0.isRunning }
        if !stoppedContainers.isEmpty {
            issues.append(ServerIssue(
                id: "docker.stopped",
                severity: .warning,
                symbol: "shippingbox",
                message: listMessage(stoppedContainers.map(\.name), verb: "stopped")
            ))
        }

        let failedExecutions = state.recentExecutions.filter { execution in
            guard execution.status == "error" else { return false }
            guard let started = execution.startedAt else { return true }
            return now.timeIntervalSince(started) <= executionErrorWindow
        }
        if let latest = failedExecutions.first {
            let name = latest.workflowName ?? "Workflow \(latest.id)"
            let extra = failedExecutions.count > 1 ? " (+\(failedExecutions.count - 1) more)" : ""
            issues.append(ServerIssue(
                id: "n8n.failed",
                severity: .warning,
                symbol: "flowchart",
                message: "\(name) failed\(extra)"
            ))
        }

        if issues.isEmpty, state.status == .degraded {
            issues.append(ServerIssue(
                id: "degraded",
                severity: .warning,
                symbol: "exclamationmark.triangle",
                message: state.errorMessage ?? "Some checks are failing"
            ))
        }

        return issues.sorted { $0.severity > $1.severity }
    }

    static func severity(of issues: [ServerIssue]) -> Severity {
        issues.map(\.severity).max() ?? .ok
    }

    private static func listMessage(_ names: [String], verb: String) -> String {
        switch names.count {
        case 1:  return "\(names[0]) \(verb)"
        case 2:  return "\(names[0]) and \(names[1]) \(verb)"
        default: return "\(names[0]) and \(names.count - 1) others \(verb)"
        }
    }
}
