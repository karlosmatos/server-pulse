import Foundation

/// Read-only hardening audit: one SSH command collects facts, Swift turns them into checks.
enum SecurityAudit {
    /// How often the audit re-runs on its own. A manual refresh also re-runs it.
    static let refreshInterval: TimeInterval = 6 * 60 * 60

    /// Unauthenticated Docker Engine API port.
    private static let dockerAPIPort = 2375

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
    # ufw.conf survives `apt remove ufw`, so also require the binary.
    { [ -x /usr/sbin/ufw ] || command -v ufw >/dev/null 2>&1; } && grep -qs '^ENABLED=yes' /etc/ufw/ufw.conf && echo "firewall ufw"
    systemctl is-active --quiet firewalld 2>/dev/null && echo "firewall firewalld"
    # Only default-deny counts: a rule dropping a few ports is not a firewall.
    if [ "$(id -u)" = 0 ]; then
      echo "fwrules $({ iptables -S INPUT 2>/dev/null; nft list ruleset 2>/dev/null; } | grep -cE '^-P INPUT (DROP|REJECT)|^-A INPUT( -i [^ ]+)? -j (DROP|REJECT)( --reject-with [^ ]+)?$|hook input .*policy drop')"
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
    systemctl is-active --quiet tailscaled 2>/dev/null && echo "vpn tailscale"
    ip -o link show type wireguard 2>/dev/null | head -1 | awk '{ print "vpn wireguard" }'
    [ -r /sys/module/apparmor/parameters/enabled ] && echo "apparmor $(cat /sys/module/apparmor/parameters/enabled)"
    command -v getenforce >/dev/null 2>&1 && echo "selinux $(getenforce 2>/dev/null)"
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
        var vpns: [String] = []
        var appArmor: String?
        var seLinux: String?
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
            case "vpn":
                facts.vpns.append(value)
            case "apparmor":
                facts.appArmor = value
            case "selinux":
                facts.seLinux = value.lowercased()
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
            dockerAPICheck(facts),
            vpnSSHCheck(facts, sshPort: sshPort),
            accessControlCheck(facts),
        ]
        return checks.compactMap { $0 }.sorted { $0.rank > $1.rank }
    }

    private static let sshdUnreadable = "Can't read sshd config as this user"

    private static func rootLoginCheck(_ facts: Facts) -> SecurityCheck {
        let id = "ssh.root", title = "SSH root login"
        guard !facts.sshd.isEmpty else {
            return SecurityCheck(id: id, title: title, status: .unknown, detail: "no access", advice: sshdUnreadable)
        }
        let advice = "Set PermitRootLogin no, use a sudo user"
        let explanation = "Without root login an attacker also needs a username, and admin actions are traceable through sudo. Connect ServerPulse as that user too; root-only checks then show as unknown."
        // OpenSSH default since 7.0 when the option is absent.
        switch facts.sshd["permitrootlogin"] ?? "prohibit-password" {
        case "no":
            return SecurityCheck(id: id, title: title, status: .pass, detail: "disabled")
        case "yes":
            return SecurityCheck(id: id, title: title, status: .fail(.critical), detail: "password allowed", advice: advice, explanation: explanation)
        default:
            return SecurityCheck(id: id, title: title, status: .fail(.warning), detail: "key allowed", advice: advice, explanation: explanation)
        }
    }

    private static func passwordAuthCheck(_ facts: Facts) -> SecurityCheck {
        let id = "ssh.password", title = "SSH password login"
        guard !facts.sshd.isEmpty else {
            return SecurityCheck(id: id, title: title, status: .unknown, detail: "no access", advice: sshdUnreadable)
        }
        let passwordAuth = (facts.sshd["passwordauthentication"] ?? "yes") == "yes"
        // Keyboard-interactive through PAM also accepts passwords. Only flag it when explicit,
        // because the config-file fallback cannot know distro defaults.
        let kbdInteractive = (facts.sshd["kbdinteractiveauthentication"] ?? facts.sshd["challengeresponseauthentication"]) == "yes"
            && facts.sshd["usepam"] == "yes"
        guard passwordAuth || kbdInteractive else {
            return SecurityCheck(id: id, title: title, status: .pass, detail: "keys only")
        }
        return SecurityCheck(
            id: id, title: title, status: .fail(.critical),
            detail: passwordAuth ? "enabled" : "enabled via PAM",
            advice: "Set PasswordAuthentication no",
            explanation: "Also set KbdInteractiveAuthentication no, then reload sshd. Passwords can be brute-forced; keys practically can't."
        )
    }

    private static func firewallCheck(_ facts: Facts) -> SecurityCheck {
        let id = "firewall", title = "Firewall"
        if let name = facts.firewalls.first {
            return SecurityCheck(id: id, title: title, status: .pass, detail: name)
        }
        if let rules = facts.firewallRuleCount, rules > 0 {
            return SecurityCheck(id: id, title: title, status: .pass, detail: "iptables")
        }
        guard facts.uid == 0 else {
            return SecurityCheck(
                id: id, title: title, status: .unknown, detail: "needs root",
                advice: "Connect as root to inspect iptables"
            )
        }
        return SecurityCheck(
            id: id, title: title, status: .fail(.warning), detail: "none",
            advice: "Skip if your provider filters traffic",
            command: "ufw default deny incoming && ufw allow OpenSSH && ufw enable"
        )
    }

    private static func intrusionPreventionCheck(_ facts: Facts) -> SecurityCheck {
        let id = "ips", title = "Brute-force protection"
        if let name = facts.intrusionPrevention.first {
            return SecurityCheck(id: id, title: title, status: .pass, detail: name)
        }
        return SecurityCheck(
            id: id, title: title, status: .fail(.warning), detail: "none",
            advice: "Install fail2ban or CrowdSec",
            command: facts.packageManager.map { "\($0) install fail2ban" }
        )
    }

    private static func automaticUpdatesEnabled(_ facts: Facts) -> Bool {
        switch facts.packageManager {
        case "apt":
            let periodic = facts.unattendedPeriodic ?? "0"
            return facts.unattendedInstalled && periodic != "0" && !periodic.isEmpty
        case "dnf":
            return !facts.dnfAutomaticTimers.isEmpty
        default:
            return false
        }
    }

    private static func automaticUpdatesCheck(_ facts: Facts) -> SecurityCheck? {
        let id = "autoupdates", title = "Automatic updates"
        let enabled = automaticUpdatesEnabled(facts)
        switch facts.packageManager {
        case "apt":
            if enabled {
                return SecurityCheck(id: id, title: title, status: .pass, detail: "enabled")
            }
            return SecurityCheck(
                id: id, title: title, status: .fail(.warning),
                detail: facts.unattendedInstalled ? "disabled" : "not installed",
                command: "apt install unattended-upgrades && dpkg-reconfigure -plow unattended-upgrades"
            )
        case "dnf":
            if enabled {
                return SecurityCheck(id: id, title: title, status: .pass, detail: "enabled")
            }
            return SecurityCheck(
                id: id, title: title, status: .fail(.warning), detail: "disabled",
                command: "dnf install dnf-automatic && systemctl enable --now dnf-automatic-install.timer"
            )
        default:
            return nil
        }
    }

    private static func pendingUpdatesCheck(_ facts: Facts) -> SecurityCheck? {
        guard let updates = facts.pendingUpdates else { return nil }
        let id = "updates", title = "Security updates"
        guard updates.security == 0 else {
            // With automatic updates the backlog is usually just waiting for the next daily run.
            let automatic = automaticUpdatesEnabled(facts)
            return SecurityCheck(
                id: id, title: title,
                status: .fail(automatic ? .warning : .critical),
                detail: "\(updates.security) pending",
                advice: automatic ? "Auto-updates will install these" : "Auto-updates are off",
                explanation: automatic
                    ? "unattended-upgrades should pick these up on its next daily run."
                    : "These stay unpatched until someone installs them.",
                command: "apt update && apt upgrade"
            )
        }
        return SecurityCheck(id: id, title: title, status: .pass, detail: "up to date")
    }

    private static func rebootCheck(_ facts: Facts) -> SecurityCheck? {
        guard let required = facts.rebootRequired else { return nil }
        let id = "reboot", title = "Reboot"
        guard required else {
            return SecurityCheck(id: id, title: title, status: .pass, detail: "not needed")
        }
        return SecurityCheck(
            id: id, title: title, status: .fail(.warning), detail: "required",
            advice: "Reboot to apply installed updates"
        )
    }

    private static func uidZeroCheck(_ facts: Facts) -> SecurityCheck? {
        guard !facts.uidZeroAccounts.isEmpty else { return nil }
        let id = "uid0", title = "Superuser accounts"
        let extra = facts.uidZeroAccounts.filter { $0 != "root" }
        guard !extra.isEmpty else {
            return SecurityCheck(id: id, title: title, status: .pass, detail: "root only")
        }
        return SecurityCheck(
            id: id, title: title, status: .fail(.critical), detail: extra.joined(separator: ", "),
            advice: "Remove them or give them a regular UID",
            explanation: "Any account with UID 0 is a full root account."
        )
    }

    private static func publicPortsCheck(_ facts: Facts, sshPort: Int) -> SecurityCheck? {
        guard facts.hasSS else { return nil }
        let id = "ports", title = "Public ports"
        let allowed = expectedPublicPorts.union([sshPort])
        // The Docker API has its own, critical check.
        let exposed = Set(facts.listenAddresses.compactMap(publicPort))
            .subtracting(allowed)
            .subtracting([dockerAPIPort])
            .sorted()
        guard !exposed.isEmpty else {
            return SecurityCheck(id: id, title: title, status: .pass, detail: "SSH/HTTP only")
        }
        let list = exposed.prefix(4).map { String($0) }.joined(separator: ", ")
        let more = exposed.count > 4 ? " +\(exposed.count - 4)" : ""
        return SecurityCheck(
            id: id, title: title, status: .fail(.warning), detail: "\(list)\(more)",
            advice: "Bind to 127.0.0.1 — Docker ports bypass ufw",
            explanation: "These listen on all interfaces. Publish Docker ports as 127.0.0.1:port:port and put a reverse proxy in front; Docker-published ports skip ufw and INPUT rules."
        )
    }

    private static func dockerAPICheck(_ facts: Facts) -> SecurityCheck? {
        guard facts.listenAddresses.compactMap(publicPort).contains(dockerAPIPort) else { return nil }
        return SecurityCheck(
            id: "docker.api", title: "Docker API", status: .fail(.critical), detail: "\(dockerAPIPort) open",
            advice: "Remove the tcp:// host from dockerd",
            explanation: "The unauthenticated Docker API gives anyone root on this host."
        )
    }

    private static func vpnSSHCheck(_ facts: Facts, sshPort: Int) -> SecurityCheck? {
        guard let vpn = facts.vpns.first, facts.hasSS else { return nil }
        let id = "ssh.vpn", title = "SSH over \(vpn.capitalized)"
        let sshIsPublic = facts.listenAddresses.compactMap(publicPort).contains(sshPort)
        guard sshIsPublic else {
            return SecurityCheck(id: id, title: title, status: .pass, detail: "VPN only")
        }
        let iface = vpn == "tailscale" ? "tailscale0" : "wg0"
        return SecurityCheck(
            id: id, title: title, status: .fail(.warning), detail: "SSH public",
            advice: "Allow SSH only on \(iface)",
            explanation: "\(vpn.capitalized) is running, but SSH also accepts connections from the internet. Point ServerPulse at the VPN address first. Ignore this if your firewall already limits SSH.",
            command: facts.firewalls.contains("ufw")
                ? "ufw allow in on \(iface) to any port \(sshPort) proto tcp && ufw delete allow OpenSSH"
                : nil
        )
    }

    private static func accessControlCheck(_ facts: Facts) -> SecurityCheck? {
        let id = "mac", title = "AppArmor/SELinux"
        if facts.seLinux == "enforcing" {
            return SecurityCheck(id: id, title: title, status: .pass, detail: "SELinux")
        }
        if facts.appArmor == "Y" {
            return SecurityCheck(id: id, title: title, status: .pass, detail: "AppArmor")
        }
        if facts.seLinux == "permissive" {
            return SecurityCheck(
                id: id, title: title, status: .fail(.warning), detail: "permissive",
                advice: "Set SELINUX=enforcing",
                explanation: "Permissive mode only logs violations. Make it permanent in /etc/selinux/config.",
                command: "setenforce 1"
            )
        }
        guard facts.appArmor != nil || facts.seLinux != nil else { return nil }
        return SecurityCheck(
            id: id, title: title, status: .fail(.warning), detail: "disabled",
            advice: "Re-enable AppArmor or SELinux",
            explanation: "Mandatory access control limits what a compromised service can do."
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
