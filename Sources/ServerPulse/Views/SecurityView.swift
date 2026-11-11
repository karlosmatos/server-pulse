import AppKit
import SwiftUI

@MainActor
struct SecurityView: View {
    @Environment(AppEnvironment.self) private var appEnv
    @State private var showPassed = false

    private var ignoredIDs: Set<String> { Set(appEnv.selectedServer?.ignoredSecurityChecks ?? []) }
    private var active: [SecurityCheck] { appEnv.securityChecks.filter { !ignoredIDs.contains($0.id) } }
    private var attention: [SecurityCheck] { active.filter { $0.status != .pass } }
    private var passed: [SecurityCheck] { active.filter { $0.status == .pass } }
    private var ignored: [SecurityCheck] { appEnv.securityChecks.filter { ignoredIDs.contains($0.id) } }

    private var worstSeverity: Severity {
        attention.compactMap { check -> Severity? in
            if case .fail(let severity) = check.status { return severity }
            return nil
        }.max() ?? .ok
    }

    private var collapsedLabel: String {
        var parts: [String] = []
        if !passed.isEmpty {
            parts.append(attention.isEmpty ? "All \(passed.count) checks passed" : "\(passed.count) passed")
        }
        if !ignored.isEmpty { parts.append("\(ignored.count) ignored") }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        SectionCard(icon: "lock.shield", title: "Security", tint: worstSeverity.color) {
            Text("\(passed.count)/\(active.count) passed")
                .font(.system(size: 11)).monospacedDigit().foregroundStyle(.tertiary)
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(attention) { check in
                    SecurityCheckRow(check: check, isIgnored: false) {
                        appEnv.setSecurityCheck(check.id, ignored: true)
                    }
                }

                footer
                    .padding(.top, attention.isEmpty ? 0 : 6)

                if showPassed {
                    ForEach(passed) { check in
                        SecurityCheckRow(check: check, isIgnored: false, onToggleIgnore: nil)
                    }
                    ForEach(ignored) { check in
                        SecurityCheckRow(check: check, isIgnored: true) {
                            appEnv.setSecurityCheck(check.id, ignored: false)
                        }
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 4) {
            if !passed.isEmpty || !ignored.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { showPassed.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showPassed ? "chevron.down" : "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                        Text(collapsedLabel)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 4)
            if let audited = appEnv.lastSecurityAudit {
                // Formatted once per render, so it does not tick every second.
                // English locale to match the rest of the (unlocalized) UI.
                Text("checked \(audited.formatted(.relative(presentation: .named).locale(Locale(identifier: "en_US"))))")
                    .foregroundStyle(.tertiary)
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
    }
}

private struct SecurityCheckRow: View {
    let check: SecurityCheck
    let isIgnored: Bool
    /// nil hides the ignore button (passing checks have nothing to ignore).
    let onToggleIgnore: (() -> Void)?
    @State private var isHovering = false

    private var color: Color {
        if isIgnored { return .gray }
        switch check.status {
        case .fail(let severity): return severity.color
        case .unknown:            return .gray
        case .pass:               return .brand
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(check.title)
                    .font(.system(size: 11, weight: check.status == .pass || isIgnored ? .regular : .medium))
                    .foregroundStyle(isIgnored ? .secondary : .primary)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if let onToggleIgnore, isHovering {
                    Button(action: onToggleIgnore) {
                        Image(systemName: isIgnored ? "eye" : "eye.slash")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(isIgnored ? "Stop ignoring this check" : "Ignore this check on this server")
                }
                Text(isIgnored ? "ignored" : check.detail)
                    .font(.system(size: 11)).monospacedDigit()
                    .foregroundStyle(isIgnored || check.status == .pass ? Color.secondary : color)
                    .lineLimit(1)
            }

            if !isIgnored, check.status != .pass {
                VStack(alignment: .leading, spacing: 3) {
                    if let advice = check.advice {
                        Text(advice)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let command = check.command {
                        FixCommandView(command: command)
                    }
                }
                .padding(.leading, 12)
            }
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .contextMenu {
            if let onToggleIgnore {
                Button(isIgnored ? "Stop Ignoring" : "Ignore on This Server", action: onToggleIgnore)
            }
            if let command = check.command {
                Button("Copy Fix Command") { FixCommandView.copy(command) }
            }
        }
    }
}

private struct FixCommandView: View {
    let command: String
    @State private var didCopy = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(command)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button {
                Self.copy(command)
                didCopy = true
                Task {
                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                    didCopy = false
                }
            } label: {
                Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 10))
                    .foregroundStyle(didCopy ? Color.brand : .secondary)
            }
            .buttonStyle(.plain)
            .help("Copy command")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.trackFill.opacity(0.6), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    static func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
