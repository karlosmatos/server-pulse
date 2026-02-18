import Foundation

enum SSHError: Error, LocalizedError {
    case timeout
    case commandFailed(code: Int32, stderr: String)

    var errorDescription: String? {
        switch self {
        case .timeout:
            return "SSH connection timed out"
        case .commandFailed(let code, let stderr):
            return "SSH failed (exit \(code)): \(stderr.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
    }
}

struct SSHClient {
    let settings: AppSettings

    func run(_ command: String) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")

        var args = [
            "-i", settings.resolvedKeyPath,
            "-o", "BatchMode=yes",
            "-o", "StrictHostKeyChecking=no",
            "-o", "ConnectTimeout=10",
            "-o", "ServerAliveInterval=5",
            "-o", "ServerAliveCountMax=1",
        ]
        if settings.sshPort != 22 {
            args += ["-p", String(settings.sshPort)]
        }
        args += ["\(settings.sshUser)@\(settings.sshHost)", command]
        process.arguments = args

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
                return
            }

            // Hard 15s deadline in case terminationHandler never fires
            let timeout = DispatchWorkItem {
                process.terminate()
                continuation.resume(throwing: SSHError.timeout)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 15, execute: timeout)

            process.terminationHandler = { proc in
                timeout.cancel()
                let outData = stdout.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outData, encoding: .utf8) ?? ""
                if proc.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    let errData = stderr.fileHandleForReading.readDataToEndOfFile()
                    let errMsg = String(data: errData, encoding: .utf8) ?? ""
                    continuation.resume(throwing: SSHError.commandFailed(code: proc.terminationStatus, stderr: errMsg))
                }
            }
        }
    }
}
