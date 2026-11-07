import Foundation

struct PingChecker {

    func isReachable(host: String) async -> Bool {
        let host = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard SSHConfigValidator.isValidHost(host) else { return false }

        let process = Process()
        let processHandle = PingProcessHandle(process: process)
        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
        // -c 1: one packet, -W 5000: wait 5000ms, -q: quiet
        process.arguments = ["-c", "1", "-W", "5000", "-q", host]
        process.standardOutput = FileHandle.nullDevice
        process.standardError  = FileHandle.nullDevice

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                let gate = PingContinuationGate(continuation)

                let timeout = DispatchWorkItem {
                    processHandle.terminate()
                    Task { await gate.resume(false) }
                }

                process.terminationHandler = { proc in
                    timeout.cancel()
                    Task { await gate.resume(proc.terminationStatus == 0) }
                }

                guard !Task.isCancelled else {
                    Task { await gate.resume(false) }
                    return
                }

                do {
                    try process.run()
                    processHandle.markStarted()
                    DispatchQueue.global().asyncAfter(deadline: .now() + 8, execute: timeout)
                } catch {
                    timeout.cancel()
                    Task { await gate.resume(false) }
                }
            }
        } onCancel: {
            processHandle.terminate()
        }
    }
}

private final class PingProcessHandle: @unchecked Sendable {
    private let process: Process
    private let lock = NSLock()
    private var started = false
    private var shouldTerminate = false

    init(process: Process) {
        self.process = process
    }

    func markStarted() {
        lock.lock()
        started = true
        let terminateNow = shouldTerminate && process.isRunning
        lock.unlock()

        guard terminateNow else { return }
        process.terminate()
    }

    func terminate() {
        lock.lock()
        shouldTerminate = true
        let terminateNow = started && process.isRunning
        lock.unlock()

        guard terminateNow else { return }
        process.terminate()
    }
}

actor PingContinuationGate {
    private var fired = false
    private let continuation: CheckedContinuation<Bool, Never>

    init(_ continuation: CheckedContinuation<Bool, Never>) {
        self.continuation = continuation
    }

    func resume(_ value: Bool) {
        guard !fired else { return }
        fired = true
        continuation.resume(returning: value)
    }
}
