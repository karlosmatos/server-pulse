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

            let timeout = DispatchWorkItem {
                process.terminate()
                continuation.resume(returning: false)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 8, execute: timeout)

            process.terminationHandler = { proc in
                timeout.cancel()
                continuation.resume(returning: proc.terminationStatus == 0)
            }
        }
    }
}
