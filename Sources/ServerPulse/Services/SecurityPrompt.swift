import Foundation

/// Builds a Markdown prompt that asks a coding agent (Claude Code, Codex, …) to plan fixes
/// for the failing security checks of one server.
enum SecurityPrompt {
    static func build(server: ServerConfig, issues: [SecurityCheck], passed: [SecurityCheck]) -> String {
        var lines: [String] = [
            "I run a Linux server \"\(server.name)\" and a read-only security audit flagged the issues below.",
            "Propose a safe remediation plan for each one.",
            "",
            "Server access: `\(sshCommand(for: server))`",
            "",
            "## Findings",
        ]

        for check in issues {
            lines.append("")
            lines.append("### \(check.title) — \(label(for: check.status)): \(check.detail)")
            if let advice = check.advice { lines.append("- Advice: \(advice)") }
            if let explanation = check.explanation { lines.append("- Context: \(explanation)") }
            if let command = check.command { lines.append("- Suggested fix: `\(command)`") }
            lines.append("- Check id: `\(check.id)`")
        }

        if !passed.isEmpty {
            lines.append("")
            lines.append("Already OK: " + passed.map { "\($0.title) (\($0.detail))" }.joined(separator: ", ") + ".")
        }

        lines += [
            "",
            "## How to help",
            "1. First inspect the server read-only (OS version, running services, current config) and confirm each finding; say if one is a false positive.",
            "2. For each confirmed issue give exact commands or config changes, why they matter, and the risk of applying them.",
            "3. Never lock me out: keep my current SSH access working (test a second session or keep the old one open before restarting sshd or enabling a firewall), and keep services I depend on reachable.",
            "4. Order the steps from most to least critical, and give a command to verify each fix.",
            "5. Do not change anything on the server until I approve the plan.",
        ]
        return lines.joined(separator: "\n")
    }

    private static func sshCommand(for server: ServerConfig) -> String {
        let port = server.sshPort == 22 ? "" : "-p \(server.sshPort) "
        return "ssh \(port)\(server.sshUser)@\(server.sshHost)"
    }

    private static func label(for status: SecurityCheck.Status) -> String {
        switch status {
        case .fail(.critical): return "critical"
        case .fail:            return "warning"
        case .unknown:         return "unknown (audit ran without root)"
        case .pass:            return "ok"
        }
    }
}
