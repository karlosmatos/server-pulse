import Foundation
import Network

/// Tries a TCP connection from this Mac, to learn whether a server port is reachable from the internet.
enum PortProbe {
    static func probeAll(hosts: [String], port: Int, timeout: TimeInterval = 3) async -> [SecurityAudit.SSHProbe] {
        await withTaskGroup(of: SecurityAudit.SSHProbe.self) { group in
            for host in hosts {
                group.addTask { await probe(host: host, port: port, timeout: timeout) }
            }
            return await group.reduce(into: []) { $0.append($1) }
        }
    }

    static func probe(host: String, port: Int, timeout: TimeInterval = 3) async -> SecurityAudit.SSHProbe {
        guard let nwPort = NWEndpoint.Port(rawValue: UInt16(clamping: port)) else { return .inconclusive }
        let connection = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: .tcp)
        let queue = DispatchQueue(label: "PortProbe")

        return await withCheckedContinuation { continuation in
            let once = ProbeOnce(connection: connection, continuation: continuation)
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    once.finish(.open)
                case .waiting(let error), .failed(let error):
                    once.finish(classify(error))
                default:
                    break
                }
            }
            connection.start(queue: queue)
            // A firewall that drops packets never answers, so silence means blocked.
            queue.asyncAfter(deadline: .now() + timeout) { once.finish(.blocked) }
        }
    }

    static func classify(_ error: NWError) -> SecurityAudit.SSHProbe {
        if case .posix(let code) = error, code == .ECONNREFUSED || code == .ETIMEDOUT {
            return .blocked
        }
        // No route, no network, DNS: this Mac could not try, which says nothing about the server.
        return .inconclusive
    }
}

/// Resumes the continuation exactly once and closes the connection.
private final class ProbeOnce: @unchecked Sendable {
    private let lock = NSLock()
    private let connection: NWConnection
    private var continuation: CheckedContinuation<SecurityAudit.SSHProbe, Never>?

    init(connection: NWConnection, continuation: CheckedContinuation<SecurityAudit.SSHProbe, Never>) {
        self.connection = connection
        self.continuation = continuation
    }

    func finish(_ result: SecurityAudit.SSHProbe) {
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
