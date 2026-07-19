import Foundation

#if os(macOS)
import Darwin
#endif

enum ProcessOutcome: Equatable, Sendable {
    case exited(Int32)
    case timedOut
    case cancelled
    case launchFailed(String)
}

struct ProcessResult: Equatable, Sendable {
    let outcome: ProcessOutcome
    let output: String
    let wasTruncated: Bool

    var succeeded: Bool {
        outcome == .exited(0)
    }
}

protocol ProcessRunning: Sendable {
    func run(
        executableURL: URL,
        arguments: [String],
        timeout: TimeInterval,
        outputLimit: Int
    ) async -> ProcessResult
}

/// Executes one bounded child process. Output is drained while the process is
/// running, retained up to the configured cap, and the process group is asked
/// to terminate on timeout or task cancellation.
final class ProcessRunner: ProcessRunning, @unchecked Sendable {
    static let shared = ProcessRunner()

    func run(
        executableURL: URL,
        arguments: [String],
        timeout: TimeInterval = 5,
        outputLimit: Int = 65_536
    ) async -> ProcessResult {
        guard !Task.isCancelled else {
            return ProcessResult(outcome: .cancelled, output: "", wasTruncated: false)
        }

        let execution = ProcessExecution(
            executableURL: executableURL,
            arguments: arguments,
            timeout: timeout,
            outputLimit: outputLimit
        )

        return await withTaskCancellationHandler(operation: {
            await execution.start()
        }, onCancel: {
            execution.cancel()
        })
    }
}

private final class ProcessExecution: @unchecked Sendable {
    private let process = Process()
    private let pipe = Pipe()
    private let timeout: TimeInterval
    private let outputLimit: Int
    private let lock = NSLock()

    private var continuation: CheckedContinuation<ProcessResult, Never>?
    private var output = Data()
    private var wasTruncated = false
    private var didFinish = false
    private var didTimeOut = false
    private var wasCancelled = false
    private var timeoutWorkItem: DispatchWorkItem?
    private var processGroupID: Int32?

    init(
        executableURL: URL,
        arguments: [String],
        timeout: TimeInterval,
        outputLimit: Int
    ) {
        self.timeout = timeout
        self.outputLimit = max(0, outputLimit)
        process.executableURL = executableURL
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        process.qualityOfService = .utility
    }

    func start() async -> ProcessResult {
        await withCheckedContinuation { continuation in
            let shouldStart = lock.synchronized {
                self.continuation = continuation
                return !wasCancelled
            }

            guard shouldStart else {
                complete(with: .cancelled)
                return
            }

            pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                if !data.isEmpty {
                    self?.append(data)
                }
            }

            process.terminationHandler = { [weak self] process in
                self?.complete(with: .exited(process.terminationStatus))
            }

            do {
                try process.run()
                establishProcessGroupIfPossible()
                scheduleTimeout()
            } catch {
                complete(with: .launchFailed(error.localizedDescription))
            }
        }
    }

    func cancel() {
        requestTermination(cancelled: true, timedOut: false)
    }

    private func scheduleTimeout() {
        let workItem = DispatchWorkItem { [weak self] in
            self?.requestTermination(cancelled: false, timedOut: true)
        }
        lock.synchronized {
            timeoutWorkItem = workItem
        }
        DispatchQueue.global(qos: .utility).asyncAfter(
            deadline: .now() + timeout,
            execute: workItem
        )
    }

    private func establishProcessGroupIfPossible() {
        #if os(macOS)
        let identifier = process.processIdentifier
        if Darwin.setpgid(identifier, identifier) == 0 {
            lock.synchronized {
                processGroupID = identifier
            }
        }
        #endif
    }

    private func requestTermination(cancelled: Bool, timedOut: Bool) {
        let shouldTerminate: Bool = lock.synchronized {
            guard !didFinish else { return false }
            wasCancelled = wasCancelled || cancelled
            didTimeOut = didTimeOut || timedOut
            return true
        }

        guard shouldTerminate else { return }
        terminate(signal: SIGTERM)

        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, self.process.isRunning else { return }
            self.terminate(signal: SIGKILL)
        }
    }

    private func terminate(signal: Int32) {
        #if os(macOS)
        if let groupID = lock.synchronized({ processGroupID }) {
            if Darwin.kill(-groupID, signal) == 0 {
                return
            }
        }
        #endif

        if process.isRunning {
            process.terminate()
        }
    }

    private func append(_ data: Data) {
        lock.synchronized {
            let remaining = max(0, outputLimit - output.count)
            if remaining > 0 {
                output.append(contentsOf: data.prefix(remaining))
            }
            if data.count > remaining {
                wasTruncated = true
            }
        }
    }

    private func complete(with processOutcome: ProcessOutcome) {
        pipe.fileHandleForReading.readabilityHandler = nil
        try? pipe.fileHandleForWriting.close()
        if let remainingData = try? pipe.fileHandleForReading.readToEnd(),
           !remainingData.isEmpty {
            append(remainingData)
        }

        let completion: (CheckedContinuation<ProcessResult, Never>, ProcessResult)? = lock.synchronized {
            guard !didFinish, let continuation else { return nil }
            didFinish = true
            timeoutWorkItem?.cancel()

            let finalOutcome: ProcessOutcome
            if didTimeOut {
                finalOutcome = .timedOut
            } else if wasCancelled {
                finalOutcome = .cancelled
            } else {
                finalOutcome = processOutcome
            }

            let result = ProcessResult(
                outcome: finalOutcome,
                output: String(data: output, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                wasTruncated: wasTruncated
            )
            self.continuation = nil
            return (continuation, result)
        }

        if let completion {
            completion.0.resume(returning: completion.1)
        }
    }
}

private extension NSLock {
    func synchronized<T>(_ operation: () -> T) -> T {
        lock()
        defer { unlock() }
        return operation()
    }
}
