import Foundation

struct PingChecker {

    func isReachable(host: String) async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
        // -c 1: one packet, -W 5000: wait 5000ms, -q: quiet
        process.arguments = ["-c", "1", "-W", "5000", "-q", host]
        process.standardOutput = FileHandle.nullDevice
        process.standardError  = FileHandle.nullDevice

        return await withCheckedContinuation { continuation in
            do {
                try process.run()
            } catch {
                continuation.resume(returning: false)
                return
            }

            let gate = PingContinuationGate(continuation)

            let timeout = DispatchWorkItem {
                process.terminate()
                Task { await gate.resume(false) }
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 8, execute: timeout)

            process.terminationHandler = { proc in
                timeout.cancel()
                Task { await gate.resume(proc.terminationStatus == 0) }
            }
        }
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
