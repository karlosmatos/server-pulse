import Foundation
import Network

/// Tries a TCP connection from this Mac, to learn whether a server port is reachable from the internet.
enum PortProbe {
    /// What one connection attempt saw, before deciding what it says about the server.
    enum Outcome: Equatable {
        /// Connected and the peer greeted with "SSH-".
        case sshBanner
        /// Connected but no SSH greeting: a VPN or proxy on this Mac may have accepted it locally.
        case silent
        case refused
        case timedOut
        /// No route, no network, DNS: this Mac could not try.
        case unreachable

        var probe: SecurityAudit.SSHProbe {
            switch self {
            case .sshBanner: return .open
            case .refused, .timedOut: return .blocked
            case .silent, .unreachable: return .inconclusive
            }
        }
    }

    /// TEST-NET-1 (RFC 5737) is never routed, so on an honest network a connect to it can only time out
    /// or fail. Any other answer means something on this Mac (e.g. a VPN app) fakes TCP connects.
    static let canaryHost = "192.0.2.1"

    static func probeAll(hosts: [String], port: Int, timeout: TimeInterval = 3) async -> [SecurityAudit.SSHProbe] {
        guard !hosts.isEmpty else { return [] }
        async let canary = outcome(host: canaryHost, port: port, timeout: timeout)
        let outcomes = await withTaskGroup(of: Outcome.self) { group in
            for host in hosts {
                group.addTask { await outcome(host: host, port: port, timeout: timeout) }
            }
            return await group.reduce(into: []) { $0.append($1) }
        }
        return verdicts(outcomes, canary: await canary)
    }

    static func verdicts(_ outcomes: [Outcome], canary: Outcome) -> [SecurityAudit.SSHProbe] {
        let networkIsHonest = canary == .timedOut || canary == .unreachable
        return outcomes.map { networkIsHonest ? $0.probe : .inconclusive }
    }

    static func probe(host: String, port: Int, timeout: TimeInterval = 3) async -> SecurityAudit.SSHProbe {
        await outcome(host: host, port: port, timeout: timeout).probe
    }

    static func outcome(host: String, port: Int, timeout: TimeInterval = 3) async -> Outcome {
        guard let nwPort = NWEndpoint.Port(rawValue: UInt16(clamping: port)) else { return .unreachable }
        let connection = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: .tcp)
        let queue = DispatchQueue(label: "PortProbe")

        return await withCheckedContinuation { continuation in
            let once = ProbeOnce(connection: connection, continuation: continuation)
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    // sshd greets right away; a local proxy that accepted the connect has nothing to say.
                    connection.receive(minimumIncompleteLength: 1, maximumLength: 64) { data, _, _, _ in
                        let greeting = data.map { String(decoding: $0, as: UTF8.self) } ?? ""
                        once.finish(greeting.hasPrefix("SSH-") ? .sshBanner : .silent)
                    }
                case .waiting(let error), .failed(let error):
                    once.finish(classify(error))
                default:
                    break
                }
            }
            connection.start(queue: queue)
            // A firewall that drops packets never answers, so silence means blocked.
            queue.asyncAfter(deadline: .now() + timeout) {
                once.finish(connection.state == .ready ? .silent : .timedOut)
            }
        }
    }

    static func classify(_ error: NWError) -> Outcome {
        guard case .posix(let code) = error else { return .unreachable }
        switch code {
        case .ECONNREFUSED: return .refused
        case .ETIMEDOUT: return .timedOut
        default: return .unreachable
        }
    }
}

/// Resumes the continuation exactly once and closes the connection.
private final class ProbeOnce: @unchecked Sendable {
    private let lock = NSLock()
    private let connection: NWConnection
    private var continuation: CheckedContinuation<PortProbe.Outcome, Never>?

    init(connection: NWConnection, continuation: CheckedContinuation<PortProbe.Outcome, Never>) {
        self.connection = connection
        self.continuation = continuation
    }

    func finish(_ result: PortProbe.Outcome) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        guard let pending else { return }
        connection.stateUpdateHandler = nil
        connection.cancel()
        pending.resume(returning: result)
    }
}
