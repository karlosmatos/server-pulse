import AppKit
import SwiftUI

@MainActor
struct SecurityView: View {
    @Environment(AppEnvironment.self) private var appEnv
    @State private var showPassed = false
    /// At most one expanded row keeps the card short.
    @State private var expandedID: String?

    private var ignoredIDs: Set<String> { Set(appEnv.selectedServer?.ignoredSecurityChecks ?? []) }
    private var active: [SecurityCheck] { appEnv.activeSecurityChecks }
    private var attention: [SecurityCheck] { active.filter { $0.status != .pass } }
    private var passed: [SecurityCheck] { active.filter { $0.status == .pass } }
    private var ignored: [SecurityCheck] { appEnv.securityChecks.filter { ignoredIDs.contains($0.id) } }

    private var worstSeverity: Severity { attention.compactMap(\.severity).max() ?? .ok }

    var body: some View {
        SectionCard(icon: "lock.shield", title: "Security", tint: worstSeverity.color) {
            summary
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(attention) { check in
                    SecurityCheckRow(
                        check: check,
                        isIgnored: false,
                        isExpanded: expandedID == check.id,
                        onToggleExpand: { toggleExpanded(check.id) },
                        onToggleIgnore: { appEnv.setSecurityCheck(check.id, ignored: true) }
                    )
                }

                footer
                    .padding(.top, attention.isEmpty ? 0 : 6)

                if showPassed {
                    ForEach(passed) { check in
                        SecurityCheckRow(check: check, isIgnored: false)
                    }
                    ForEach(ignored) { check in
                        SecurityCheckRow(
                            check: check,
                            isIgnored: true,
                            onToggleIgnore: { appEnv.setSecurityCheck(check.id, ignored: false) }
                        )
                    }
                }
            }
        }
    }

    /// "1 critical · 3 warnings", or "all passed".
    private var summary: some View {
        let critical = attention.filter { $0.severity == .critical }.count
        let warnings = attention.filter { $0.severity == .warning }.count
        let unknown = attention.filter { $0.status == .unknown }.count

        var parts: [Text] = []
        if critical > 0 { parts.append(Text("\(critical) critical").foregroundColor(.down)) }
        if warnings > 0 { parts.append(Text("\(warnings) warning\(warnings == 1 ? "" : "s")").foregroundColor(.warn)) }
        if unknown > 0 { parts.append(Text("\(unknown) unknown")) }
        if parts.isEmpty { parts.append(Text("all passed").foregroundColor(.brand)) }

        let joined = parts.dropFirst().reduce(parts[0]) { $0 + Text(" · ") + $1 }
        return joined
            .font(.system(size: 11)).monospacedDigit()
            .foregroundStyle(.tertiary)
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

    private var collapsedLabel: String {
        var parts: [String] = []
        if !passed.isEmpty { parts.append("\(passed.count) passed") }
        if !ignored.isEmpty { parts.append("\(ignored.count) ignored") }
        return parts.joined(separator: " · ")
    }

    private func toggleExpanded(_ id: String) {
        withAnimation(.easeInOut(duration: 0.15)) {
            expandedID = expandedID == id ? nil : id
        }
    }
}

private struct SecurityCheckRow: View {
    let check: SecurityCheck
    let isIgnored: Bool
    var isExpanded = false
    /// nil makes the row static (passing and ignored checks have nothing to expand).
    var onToggleExpand: (() -> Void)? = nil
    /// nil hides the ignore button.
    var onToggleIgnore: (() -> Void)? = nil
    @State private var isHovering = false

    private var color: Color {
        if isIgnored { return .gray }
        switch check.status {
        case .fail(let severity): return severity.color
        case .unknown:            return .gray
        case .pass:               return .brand
        }
    }

    private var isExpandable: Bool {
        onToggleExpand != nil && (check.advice != nil || check.command != nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            if isExpanded, isExpandable {
                details
                    .padding(.leading, 12)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture { if isExpandable { onToggleExpand?() } }
        .help(isExpanded ? "" : (check.advice ?? ""))
        .contextMenu {
            if let onToggleIgnore {
                Button(isIgnored ? "Stop Ignoring" : "Ignore on This Server", action: onToggleIgnore)
            }
            if let command = check.command {
                Button("Copy Fix Command") { FixCommandView.copy(command) }
            }
        }
    }

    private var header: some View {
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
            if isExpandable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let advice = check.advice {
                Text(advice)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let explanation = check.explanation {
                Text(explanation)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let command = check.command {
                FixCommandView(command: command)
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
