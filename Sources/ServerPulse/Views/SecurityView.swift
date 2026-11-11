import SwiftUI

@MainActor
struct SecurityView: View {
    @Environment(AppEnvironment.self) private var appEnv
    @State private var showPassed = false

    private var checks: [SecurityCheck] { appEnv.securityChecks }
    private var attention: [SecurityCheck] { checks.filter { $0.status != .pass } }
    private var passed: [SecurityCheck] { checks.filter { $0.status == .pass } }

    private var worstSeverity: Severity {
        attention.compactMap { check -> Severity? in
            if case .fail(let severity) = check.status { return severity }
            return nil
        }.max() ?? .ok
    }

    var body: some View {
        SectionCard(icon: "lock.shield", title: "Security", tint: worstSeverity.color) {
            Text("\(passed.count)/\(checks.count) passed")
                .font(.system(size: 11)).monospacedDigit().foregroundStyle(.tertiary)
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(attention) { check in
                    SecurityCheckRow(check: check)
                }

                if !passed.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { showPassed.toggle() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: showPassed ? "chevron.down" : "chevron.right")
                                .font(.system(size: 9, weight: .semibold))
                            Text(attention.isEmpty ? "All \(passed.count) checks passed" : "\(passed.count) passed")
                            Spacer(minLength: 4)
                            if let audited = appEnv.lastSecurityAudit {
                                Text(audited, style: .relative).monospacedDigit()
                            }
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, attention.isEmpty ? 0 : 6)

                    if showPassed {
                        ForEach(passed) { check in
                            DotRow(color: .brand, name: check.title, value: check.detail)
                        }
                    }
                }
            }
        }
    }
}

private struct SecurityCheckRow: View {
    let check: SecurityCheck

    private var color: Color {
        switch check.status {
        case .fail(let severity): return severity.color
        case .unknown:            return .gray
        case .pass:               return .brand
        }
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(check.title)
                    .font(.system(size: 11, weight: .medium))
                Text(check.detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                if let fix = check.fix {
                    Text(fix)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}
