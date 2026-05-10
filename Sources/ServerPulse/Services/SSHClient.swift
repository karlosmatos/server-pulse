import Foundation
import Darwin

enum SSHError: Error, LocalizedError {
    case timeout
    case commandFailed(code: Int32, stderr: String)
    case outputTooLarge(limitBytes: Int)

    var errorDescription: String? {
        switch self {
        case .timeout:
            return "SSH connection timed out"
        case .commandFailed(let code, let stderr):
            return "SSH failed (exit \(code)): \(stderr.trimmingCharacters(in: .whitespacesAndNewlines))"
        case .outputTooLarge(let limitBytes):
            return "SSH output exceeded \(limitBytes) bytes"
        }
    }
}

struct SSHClient {
    let config: ServerConfig
    private static let controlPath: String = {
        let dir = prepareSSHDirectory()
        return "\(dir.path)/sp_ctl_%C"
    }()

    func run(_ command: String) async throws -> String {
        let process = Process()
        let processHandle = SSHProcessHandle(process: process)

        return try await withTaskCancellationHandler {
            try await run(command, process: process, processHandle: processHandle)
        } onCancel: {
            processHandle.terminate(reason: .cancelled)
        }
    }

    private func run(_ command: String, process: Process, processHandle: SSHProcessHandle) async throws -> String {
        let destination = try SSHConfigValidator.destination(for: config)

        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        var args = [
            "-i", config.resolvedKeyPath,
            "-o", "BatchMode=yes",
            "-o", "StrictHostKeyChecking=accept-new",
            "-o", "ConnectTimeout=10",
            "-o", "ServerAliveInterval=30",
            "-o", "ServerAliveCountMax=2",
            "-o", "ControlMaster=auto",
            "-o", "ControlPath=\(Self.controlPath)",
            "-o", "ControlPersist=120",
        ]
        if config.sshPort != 22 {
            args += ["-p", String(config.sshPort)]
        }
        args += ["--", destination, command]
        process.arguments = args

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        let termination = TerminationState()
        let timeout = DispatchWorkItem {
            processHandle.terminate(reason: .timeout)
        }
        process.terminationHandler = { proc in
            timeout.cancel()
            switch processHandle.terminationReason {
            case .cancelled:
                termination.finish(with: .failure(CancellationError()))
            case .outputLimit:
                termination.finish(with: .failure(SSHError.outputTooLarge(limitBytes: Self.outputLimitBytes)))
            case .timeout:
                termination.finish(with: .failure(SSHError.timeout))
            case nil:
                termination.finish(with: .success(proc.terminationStatus))
            }
        }

        try Task.checkCancellation()
        try process.run()
        processHandle.markStarted()
        DispatchQueue.global().asyncAfter(deadline: .now() + 15, execute: timeout)

        let stdoutTask = Task.detached {
            try ProcessOutputReader.read(
                from: stdout.fileHandleForReading,
                limit: Self.outputLimitBytes,
                processHandle: processHandle
            )
        }
        let stderrTask = Task.detached {
            try ProcessOutputReader.read(
                from: stderr.fileHandleForReading,
                limit: Self.outputLimitBytes,
                processHandle: processHandle
            )
        }

        let status = try await termination.wait()
        let output = try await stdoutTask.value
        let errMsg = try await stderrTask.value
        if status == 0 {
            return output
        }
        throw SSHError.commandFailed(code: status, stderr: errMsg)
    }

    private static let outputLimitBytes = 1_048_576

    private enum ProcessOutputReader {
        static func read(from fileHandle: FileHandle, limit: Int, processHandle: SSHProcessHandle) throws -> String {
            var data = Data()
            while true {
                let chunk = try fileHandle.read(upToCount: 16 * 1_024) ?? Data()
                guard !chunk.isEmpty else { break }
                guard data.count + chunk.count <= limit else {
                    processHandle.terminate(reason: .outputLimit)
                    throw SSHError.outputTooLarge(limitBytes: limit)
                }
                data.append(chunk)
            }
            return String(decoding: data, as: UTF8.self)
        }
    }

    private static func prepareSSHDirectory() -> URL {
        let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: dir.path)
        } catch {
            print("Failed to prepare ~/.ssh directory: \(error)")
        }
        return dir
    }
}

private enum SSHProcessTerminationReason {
    case cancelled
    case outputLimit
    case timeout
}

private final class SSHProcessHandle: @unchecked Sendable {
    private let process: Process
    private let lock = NSLock()
    private var started = false
    private var reason: SSHProcessTerminationReason?

    init(process: Process) {
        self.process = process
    }

    var terminationReason: SSHProcessTerminationReason? {
        lock.lock()
        defer { lock.unlock() }
        return reason
    }

    func markStarted() {
        lock.lock()
        started = true
        let shouldTerminate = reason != nil && process.isRunning
        lock.unlock()

        guard shouldTerminate else { return }
        terminateRunningProcess()
    }

    func terminate(reason newReason: SSHProcessTerminationReason) {
        lock.lock()
        if reason == nil {
            reason = newReason
        }
        let shouldTerminate = started && process.isRunning
        lock.unlock()

        guard shouldTerminate else { return }
        terminateRunningProcess()
    }

    private func terminateRunningProcess() {
        process.terminate()
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [process] in
            guard process.isRunning else { return }
            kill(process.processIdentifier, SIGKILL)
        }
    }
}

private final class TerminationState: @unchecked Sendable {
    private let lock = NSLock()
    private var result: Result<Int32, Error>?
    private var continuation: CheckedContinuation<Int32, Error>?

    func wait() async throws -> Int32 {
        try await withCheckedThrowingContinuation { continuation in
            let resultToResume: Result<Int32, Error>?
            lock.lock()
            if let result {
                resultToResume = result
            } else {
                self.continuation = continuation
                resultToResume = nil
            }
            lock.unlock()

            if let resultToResume {
                resume(continuation, with: resultToResume)
            }
        }
    }

    func finish(with result: Result<Int32, Error>) {
        let continuationToResume: CheckedContinuation<Int32, Error>?
        lock.lock()
        guard self.result == nil else {
            lock.unlock()
            return
        }
        self.result = result
        continuationToResume = continuation
        continuation = nil
        lock.unlock()

        if let continuationToResume {
            resume(continuationToResume, with: result)
        }
    }

    private func resume(_ continuation: CheckedContinuation<Int32, Error>, with result: Result<Int32, Error>) {
        switch result {
        case .success(let status):
            continuation.resume(returning: status)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}
