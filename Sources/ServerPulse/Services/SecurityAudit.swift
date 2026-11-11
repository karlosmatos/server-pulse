import Foundation

/// Read-only hardening audit: one SSH command collects facts, Swift turns them into checks.
enum SecurityAudit {
    /// How often the audit re-runs on its own. A manual refresh also re-runs it.
    static let refreshInterval: TimeInterval = 6 * 60 * 60

    /// Ports that are expected to be reachable from the internet.
    private static let expectedPublicPorts: Set<Int> = [22, 80, 443]

    /// Emits one `key value` line per fact. Never uses sudo: failed `sudo -n` attempts
    /// end up in auth logs, so facts that need root are simply missing for other users.
    static let command = #"""
    echo "uid $(id -u)"
    sp_sshd=$(sshd -T 2>/dev/null)
    if [ -n "$sp_sshd" ]; then
      printf '%s\n' "$sp_sshd" | sed 's/^/sshd /'
    else
      cat /etc/ssh/sshd_config.d/*.conf /etc/ssh/sshd_config 2>/dev/null | sed -n '/^[[:space:]]*[Mm]atch[[:space:]]/q;s/^[[:space:]]*//;/^#/d;/^$/d;s/^/sshd /p'
    fi
    grep -qs '^ENABLED=yes' /etc/ufw/ufw.conf && echo "firewall ufw"
    systemctl is-active --quiet firewalld 2>/dev/null && echo "firewall firewalld"
    if [ "$(id -u)" = 0 ]; then
      echo "fwrules $({ iptables -S INPUT 2>/dev/null; nft list ruleset 2>/dev/null; } | grep -cE '^-P INPUT (DROP|REJECT)|^-A INPUT .*-j (DROP|REJECT)|hook input .*policy drop')"
    fi
    for s in fail2ban crowdsec; do systemctl is-active --quiet "$s" 2>/dev/null && echo "ips $s"; done
    if command -v apt-get >/dev/null 2>&1; then
      echo "pkg apt"
      dpkg-query -W -f='${Status}\n' unattended-upgrades 2>/dev/null | grep -q 'install ok installed' && echo "uu installed"
      apt-config dump 2>/dev/null | sed -n 's/^APT::Periodic::Unattended-Upgrade "\(.*\)";$/uu periodic \1/p'
      apt-get -s -o Debug::NoLocking=1 dist-upgrade 2>/dev/null | awk '/^Inst /{t++; if (/-security/) s++} END{print "updates " t+0 " " s+0}'
      if [ -f /var/run/reboot-required ]; then echo "reboot yes"; else echo "reboot no"; fi
    elif command -v dnf >/dev/null 2>&1; then
      echo "pkg dnf"
      for t in dnf-automatic.timer dnf-automatic-install.timer dnf5-automatic.timer; do systemctl is-enabled --quiet "$t" 2>/dev/null && echo "dnfauto $t"; done
    fi
    awk -F: '$3 == 0 { print "uid0 " $1 }' /etc/passwd 2>/dev/null
    if command -v ss >/dev/null 2>&1; then
      echo "ss ok"
      ss -Htln 2>/dev/null | awk '{ print "listen " $4 }'
    fi
    true
    """#

    // MARK: - Facts

    struct Facts {
        var uid: Int?
        /// Lowercased sshd option -> lowercased first value; first occurrence wins, like sshd.
        var sshd: [String: String] = [:]
        var firewalls: [String] = []
        var firewallRuleCount: Int?
        var intrusionPrevention: [String] = []
        var packageManager: String?
        var unattendedInstalled = false
        var unattendedPeriodic: String?
        var pendingUpdates: (total: Int, security: Int)?
        var rebootRequired: Bool?
        var dnfAutomaticTimers: [String] = []
        var uidZeroAccounts: [String] = []
        var hasSS = false
        var listenAddresses: [String] = []
    }

    static func parseFacts(from output: String) -> Facts {
        var facts = Facts()
        for rawLine in output.split(separator: "\n") {
            let (key, value) = splitFirstWord(String(rawLine))
            switch key {
            case "uid":
                facts.uid = Int(value)
            case "sshd":
                let (option, optionValue) = splitFirstWord(value)
                let name = option.lowercased()
                let firstValue = splitFirstWord(optionValue).0.lowercased()
                if !name.isEmpty, !firstValue.isEmpty, facts.sshd[name] == nil {
                    facts.sshd[name] = firstValue
                }
            case "firewall":
                facts.firewalls.append(value)
            case "fwrules":
                facts.firewallRuleCount = Int(value)
            case "ips":
                facts.intrusionPrevention.append(value)
            case "pkg":
                facts.packageManager = value
            case "uu":
                let (kind, setting) = splitFirstWord(value)
                if kind == "installed" { facts.unattendedInstalled = true }
                if kind == "periodic" { facts.unattendedPeriodic = setting }
            case "updates":
                let counts = value.split(separator: " ").compactMap { Int($0) }
                if counts.count == 2 { facts.pendingUpdates = (counts[0], counts[1]) }
            case "reboot":
                facts.rebootRequired = value == "yes"
            case "dnfauto":
                facts.dnfAutomaticTimers.append(value)
            case "uid0":
                facts.uidZeroAccounts.append(value)
            case "ss":
                facts.hasSS = true
            case "listen":
                facts.listenAddresses.append(value)
            default:
                continue
            }
        }
        return facts
    }

    // MARK: - Checks

    static func evaluate(output: String, sshPort: Int) -> [SecurityCheck] {
        evaluate(facts: parseFacts(from: output), sshPort: sshPort)
    }

    static func evaluate(facts: Facts, sshPort: Int) -> [SecurityCheck] {
        let checks: [SecurityCheck?] = [
            rootLoginCheck(facts),
            passwordAuthCheck(facts),
            firewallCheck(facts),
            intrusionPreventionCheck(facts),
            automaticUpdatesCheck(facts),
            pendingUpdatesCheck(facts),
            rebootCheck(facts),
            uidZeroCheck(facts),
            publicPortsCheck(facts, sshPort: sshPort),
        ]
        return checks.compactMap { $0 }.sorted { $0.rank > $1.rank }
    }

    private static func rootLoginCheck(_ facts: Facts) -> SecurityCheck {
        let title = "SSH root login"
        guard !facts.sshd.isEmpty else {
            return SecurityCheck(id: "ssh.root", title: title, status: .unknown, detail: "Cannot read sshd config")
        }
        // OpenSSH default since 7.0 when the option is absent.
        switch facts.sshd["permitrootlogin"] ?? "prohibit-password" {
        case "no":
            return SecurityCheck(id: "ssh.root", title: title, status: .pass, detail: "Disabled")
        case "yes":
            return SecurityCheck(
                id: "ssh.root", title: title, status: .fail(.critical),
                detail: "Root can log in with a password",
                fix: "Set PermitRootLogin no in sshd_config and use a sudo user"
            )
        default:
            return SecurityCheck(
                id: "ssh.root", title: title, status: .fail(.warning),
                detail: "Root can log in with a key",
                fix: "Set PermitRootLogin no in sshd_config and use a sudo user"
            )
        }
    }

    private static func passwordAuthCheck(_ facts: Facts) -> SecurityCheck {
        let title = "SSH password login"
        guard !facts.sshd.isEmpty else {
            return SecurityCheck(id: "ssh.password", title: title, status: .unknown, detail: "Cannot read sshd config")
        }
        let passwordAuth = (facts.sshd["passwordauthentication"] ?? "yes") == "yes"
        // Keyboard-interactive through PAM also accepts passwords. Only flag it when explicit,
        // because the config-file fallback cannot know distro defaults.
        let kbdInteractive = (facts.sshd["kbdinteractiveauthentication"] ?? facts.sshd["challengeresponseauthentication"]) == "yes"
            && facts.sshd["usepam"] == "yes"
        guard passwordAuth || kbdInteractive else {
            return SecurityCheck(id: "ssh.password", title: title, status: .pass, detail: "Keys only")
        }
        return SecurityCheck(
            id: "ssh.password", title: title, status: .fail(.critical),
            detail: passwordAuth ? "Password authentication enabled" : "Keyboard-interactive (PAM) login enabled",
            fix: "Set PasswordAuthentication no and KbdInteractiveAuthentication no, then reload sshd"
        )
    }

    private static func firewallCheck(_ facts: Facts) -> SecurityCheck {
        let title = "Firewall"
        if let name = facts.firewalls.first {
            return SecurityCheck(id: "firewall", title: title, status: .pass, detail: "\(name) active")
        }
        if let rules = facts.firewallRuleCount, rules > 0 {
            return SecurityCheck(id: "firewall", title: title, status: .pass, detail: "iptables/nftables filtering")
        }
        guard facts.uid == 0 else {
            return SecurityCheck(id: "firewall", title: title, status: .unknown, detail: "Connect as root to inspect iptables/nftables")
        }
        return SecurityCheck(
            id: "firewall", title: title, status: .fail(.warning),
            detail: "No host firewall (fine if your provider filters traffic)",
            fix: "ufw default deny incoming && ufw allow OpenSSH && ufw enable"
        )
    }

    private static func intrusionPreventionCheck(_ facts: Facts) -> SecurityCheck {
        let title = "Brute-force protection"
        if let name = facts.intrusionPrevention.first {
            return SecurityCheck(id: "ips", title: title, status: .pass, detail: "\(name) running")
        }
        return SecurityCheck(
            id: "ips", title: title, status: .fail(.warning),
            detail: "No fail2ban or CrowdSec running",
            fix: "Install fail2ban (apt install fail2ban) or CrowdSec"
        )
    }

    private static func automaticUpdatesCheck(_ facts: Facts) -> SecurityCheck? {
        let title = "Automatic security updates"
        switch facts.packageManager {
        case "apt":
            let periodic = facts.unattendedPeriodic ?? "0"
            if facts.unattendedInstalled, periodic != "0", !periodic.isEmpty {
                return SecurityCheck(id: "autoupdates", title: title, status: .pass, detail: "unattended-upgrades enabled")
            }
            return SecurityCheck(
                id: "autoupdates", title: title, status: .fail(.warning),
                detail: facts.unattendedInstalled ? "unattended-upgrades is disabled" : "unattended-upgrades not installed",
                fix: "apt install unattended-upgrades && dpkg-reconfigure -plow unattended-upgrades"
            )
        case "dnf":
            if let timer = facts.dnfAutomaticTimers.first {
                return SecurityCheck(id: "autoupdates", title: title, status: .pass, detail: "\(timer) enabled")
            }
            return SecurityCheck(
                id: "autoupdates", title: title, status: .fail(.warning),
                detail: "dnf-automatic not enabled",
                fix: "dnf install dnf-automatic && systemctl enable --now dnf-automatic-install.timer"
            )
        default:
            return nil
        }
    }

    private static func pendingUpdatesCheck(_ facts: Facts) -> SecurityCheck? {
        guard let updates = facts.pendingUpdates else { return nil }
        let title = "Security updates"
        if updates.security > 0 {
            return SecurityCheck(
                id: "updates", title: title, status: .fail(.critical),
                detail: "\(updates.security) security update\(updates.security == 1 ? "" : "s") pending",
                fix: "apt update && apt upgrade"
            )
        }
        let other = updates.total > 0 ? " (\(updates.total) other pending)" : ""
        return SecurityCheck(id: "updates", title: title, status: .pass, detail: "Up to date\(other)")
    }

    private static func rebootCheck(_ facts: Facts) -> SecurityCheck? {
        guard let required = facts.rebootRequired else { return nil }
        let title = "Reboot"
        guard required else {
            return SecurityCheck(id: "reboot", title: title, status: .pass, detail: "Not required")
        }
        return SecurityCheck(
            id: "reboot", title: title, status: .fail(.warning),
            detail: "Reboot required to apply updates",
            fix: "Reboot the server in a quiet window"
        )
    }

    private static func uidZeroCheck(_ facts: Facts) -> SecurityCheck? {
        guard !facts.uidZeroAccounts.isEmpty else { return nil }
        let title = "Superuser accounts"
        let extra = facts.uidZeroAccounts.filter { $0 != "root" }
        guard !extra.isEmpty else {
            return SecurityCheck(id: "uid0", title: title, status: .pass, detail: "Only root has UID 0")
        }
        return SecurityCheck(
            id: "uid0", title: title, status: .fail(.critical),
            detail: "UID 0 besides root: \(extra.joined(separator: ", "))",
            fix: "Remove these accounts or give them a regular UID"
        )
    }

    private static func publicPortsCheck(_ facts: Facts, sshPort: Int) -> SecurityCheck? {
        guard facts.hasSS else { return nil }
        let title = "Public ports"
        let allowed = expectedPublicPorts.union([sshPort])
        let exposed = Set(facts.listenAddresses.compactMap(publicPort)).subtracting(allowed).sorted()
        guard !exposed.isEmpty else {
            return SecurityCheck(id: "ports", title: title, status: .pass, detail: "Only SSH/HTTP(S) listen publicly")
        }
        let list = exposed.prefix(6).map { String($0) }.joined(separator: ", ")
        let more = exposed.count > 6 ? " +\(exposed.count - 6)" : ""
        return SecurityCheck(
            id: "ports", title: title, status: .fail(.warning),
            detail: "Listening on all interfaces: \(list)\(more)",
            fix: "Bind to 127.0.0.1 or block in the firewall (Docker-published ports bypass ufw)"
        )
    }

    // MARK: - Helpers

    /// Port of an `ss` local address bound to every interface (`0.0.0.0:5432`, `[::]:80`, `*:22`), else nil.
    static func publicPort(fromListenAddress address: String) -> Int? {
        guard let colon = address.lastIndex(of: ":"),
              let port = Int(address[address.index(after: colon)...]) else { return nil }
        let host = address[..<colon]
        return ["0.0.0.0", "*", "[::]", "::"].contains(String(host)) ? port : nil
    }

    private static func splitFirstWord(_ text: String) -> (String, String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard let space = trimmed.firstIndex(where: { $0 == " " || $0 == "\t" }) else { return (trimmed, "") }
        return (String(trimmed[..<space]), trimmed[space...].trimmingCharacters(in: .whitespaces))
    }
}
