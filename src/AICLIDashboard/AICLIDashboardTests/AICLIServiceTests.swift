import Foundation
import XCTest
@testable import AICLIDashboard

final class AICLIServiceTests: XCTestCase {
    func testUnavailableExecutableDoesNotStartProcess() async {
        let runner = RecordingRunner(result: successfulResult("unused"))
        let result = await AICLIService.fetchGeminiStatus(
            runner: runner,
            locator: StubLocator(executables: [:])
        )

        let calls = await runner.recordedCalls()
        XCTAssertEqual(result.status, "Unavailable")
        XCTAssertEqual(calls.count, 0)
    }

    func testGeminiUsesBoundedVersionProbeInsteadOfSlashCommand() async {
        let runner = RecordingRunner(result: successfulResult("1.2.3"))
        let locator = StubLocator(executables: [
            "gemini": URL(fileURLWithPath: "/test/bin/gemini")
        ])

        let result = await AICLIService.fetchGeminiStatus(
            runner: runner,
            locator: locator
        )
        let calls = await runner.recordedCalls()

        XCTAssertEqual(result.status, "Unsupported")
        XCTAssertEqual(result.usageValue, "1.2.3")
        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(calls.first?.arguments, ["--version"])
        XCTAssertFalse(calls.first?.arguments.contains("/status") ?? true)
    }

    func testTimeoutIsNotReportedAsSuccess() async {
        let runner = RecordingRunner(result: ProcessResult(
            outcome: .timedOut,
            output: "",
            wasTruncated: false
        ))
        let locator = StubLocator(executables: [
            "codex": URL(fileURLWithPath: "/test/bin/codex")
        ])

        let result = await AICLIService.fetchCodexStatus(
            runner: runner,
            locator: locator
        )

        XCTAssertEqual(result.status, "Timed Out")
        XCTAssertEqual(result.metric, "Availability")
    }

    func testDisabledToolsAreNotProbed() async {
        let runner = RecordingRunner(result: successfulResult("authenticated"))
        let locator = StubLocator(executables: [
            "gemini": URL(fileURLWithPath: "/test/bin/gemini"),
            "codex": URL(fileURLWithPath: "/test/bin/codex"),
            "claude": URL(fileURLWithPath: "/test/bin/claude")
        ])

        let tools = await AICLIService.fetchSelected(
            monitorGemini: false,
            monitorCodex: true,
            monitorClaude: false,
            runner: runner,
            locator: locator
        )
        let calls = await runner.recordedCalls()

        XCTAssertEqual(tools.map(\.toolName), ["Codex CLI"])
        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(calls.first?.arguments, ["login", "status"])
    }
}

final class MCPServiceTests: XCTestCase {
    func testReadsConfiguredServersWithoutClaimingConnected() async throws {
        let fixtureDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: fixtureDirectory,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: fixtureDirectory) }

        let fixtureURL = fixtureDirectory.appendingPathComponent("settings.json")
        try Data(#"{"mcpServers":{"filesystem":{},"calculator":{}}}"#.utf8)
            .write(to: fixtureURL)

        let connections = await MCPService.fetchAllConnections(configURLs: [fixtureURL])

        XCTAssertEqual(connections.map(\.serverName), ["calculator", "filesystem"])
        XCTAssertTrue(connections.allSatisfy { $0.status == .configured })
        XCTAssertFalse(connections.contains { $0.status.rawValue == "Connected" })
    }

    func testReadsQuotedAndUnquotedCodexTOMLServerNames() async throws {
        let fixtureDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: fixtureDirectory,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: fixtureDirectory) }

        let fixtureURL = fixtureDirectory.appendingPathComponent("config.toml")
        try Data("[mcp_servers.filesystem]\n[mcp_servers.\"remote api\"]\n".utf8)
            .write(to: fixtureURL)

        let connections = await MCPService.fetchAllConnections(configURLs: [fixtureURL])

        XCTAssertEqual(connections.map(\.serverName), ["filesystem", "remote api"])
    }
}

final class StableIdentityTests: XCTestCase {
    func testDomainKeysProvideStableIdentity() {
        let firstTool = ToolUsage(
            toolName: "Codex CLI",
            status: "Unsupported",
            usageValue: "v1",
            metric: "Usage adapter"
        )
        let secondTool = ToolUsage(
            toolName: "Codex CLI",
            status: "Unsupported",
            usageValue: "v2",
            metric: "Usage adapter"
        )

        XCTAssertEqual(firstTool.id, secondTool.id)
        XCTAssertEqual(
            MCPConnection(serverName: "filesystem", status: .configured).id,
            MCPConnection(serverName: "filesystem", status: .error).id
        )
        XCTAssertEqual(
            LimitMetric(name: "Daily", value: 10, detail: "first").id,
            LimitMetric(name: "Daily", value: 20, detail: "second").id
        )
    }
}

@MainActor
final class DashboardViewModelTests: XCTestCase {
    func testHiddenDashboardDoesNotRefreshUntilShown() async throws {
        let defaults = makeDefaults()
        let probe = RefreshProbe(delayNanoseconds: 10_000_000)
        let viewModel = DashboardViewModel(
            defaults: defaults,
            toolFetcher: { _, _, _ in await probe.fetchTools() },
            mcpFetcher: { [] }
        )

        try await Task.sleep(nanoseconds: 30_000_000)
        let hiddenSnapshot = await probe.snapshot()
        XCTAssertEqual(hiddenSnapshot.calls, 0)

        viewModel.setWindowVisible(true)
        try await Task.sleep(nanoseconds: 50_000_000)
        let visibleSnapshot = await probe.snapshot()
        XCTAssertEqual(visibleSnapshot.calls, 1)
        viewModel.setWindowVisible(false)
    }

    func testOverlappingRequestsAreCoalescedAndNeverConcurrent() async throws {
        let defaults = makeDefaults()
        let probe = RefreshProbe(delayNanoseconds: 80_000_000)
        let viewModel = DashboardViewModel(
            defaults: defaults,
            toolFetcher: { _, _, _ in await probe.fetchTools() },
            mcpFetcher: { [] }
        )

        viewModel.setWindowVisible(true)
        viewModel.requestRefresh()
        viewModel.requestRefresh()
        try await Task.sleep(nanoseconds: 220_000_000)

        let snapshot = await probe.snapshot()
        XCTAssertEqual(snapshot.calls, 2)
        XCTAssertEqual(snapshot.maximumConcurrency, 1)
        viewModel.setWindowVisible(false)
    }

    func testHidingDashboardCancelsInFlightRefresh() async throws {
        let defaults = makeDefaults()
        let probe = CancellationProbe()
        let viewModel = DashboardViewModel(
            defaults: defaults,
            toolFetcher: { _, _, _ in await probe.fetchTools() },
            mcpFetcher: { [] }
        )

        viewModel.setWindowVisible(true)
        try await waitUntil { await probe.hasStarted() }
        viewModel.setWindowVisible(false)
        try await waitUntil { await probe.wasCancelled() }

        let cancelled = await probe.wasCancelled()
        XCTAssertTrue(cancelled)
    }

    func testReshowDuringCancellationRunsExactlyOnePendingRefresh() async throws {
        let defaults = makeDefaults()
        let probe = CancellationProbe()
        let viewModel = DashboardViewModel(
            defaults: defaults,
            toolFetcher: { _, _, _ in await probe.fetchTools() },
            mcpFetcher: { [] }
        )

        viewModel.setWindowVisible(true)
        try await waitUntil { await probe.callCount() == 1 }
        viewModel.setWindowVisible(false)
        viewModel.setWindowVisible(true)
        try await waitUntil { await probe.callCount() == 2 }

        let calls = await probe.callCount()
        XCTAssertEqual(calls, 2)
        viewModel.setWindowVisible(false)
    }

    func testChangingIntervalRestartsSchedulerWithoutRestartingViewModel() async throws {
        let defaults = makeDefaults()
        defaults.set(true, forKey: "autoRefreshEnabled")
        defaults.set(120.0, forKey: "refreshInterval")
        let recorder = SchedulerIntervalRecorder()
        let viewModel = DashboardViewModel(
            defaults: defaults,
            toolFetcher: { _, _, _ in [] },
            mcpFetcher: { [] },
            schedulerSleep: { interval in
                try await recorder.recordAndWait(interval)
            }
        )

        viewModel.setWindowVisible(true)
        try await waitUntil { await recorder.intervals().contains(120) }
        defaults.set(300.0, forKey: "refreshInterval")
        try await waitUntil { await recorder.intervals().contains(300) }

        let intervals = await recorder.intervals()
        XCTAssertEqual(Array(intervals.suffix(2)), [120, 300])
        viewModel.setWindowVisible(false)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "AICLIDashboardTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set(false, forKey: "autoRefreshEnabled")
        return defaults
    }

    private func waitUntil(
        timeoutNanoseconds: UInt64 = 1_000_000_000,
        condition: @escaping () async -> Bool
    ) async throws {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while !(await condition()) {
            if DispatchTime.now().uptimeNanoseconds >= deadline {
                XCTFail("Condition was not met before timeout")
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}

#if os(macOS)
final class ProcessRunnerIntegrationTests: XCTestCase {
    func testSuccessfulAndNonZeroExitCodesArePreserved() async {
        let success = await ProcessRunner.shared.run(
            executableURL: URL(fileURLWithPath: "/usr/bin/true"),
            arguments: [],
            timeout: 1,
            outputLimit: 1024
        )
        let failure = await ProcessRunner.shared.run(
            executableURL: URL(fileURLWithPath: "/usr/bin/false"),
            arguments: [],
            timeout: 1,
            outputLimit: 1024
        )

        XCTAssertEqual(success.outcome, .exited(0))
        XCTAssertEqual(failure.outcome, .exited(1))
    }

    func testTimeoutTerminatesLongRunningProcess() async {
        let result = await ProcessRunner.shared.run(
            executableURL: URL(fileURLWithPath: "/bin/sleep"),
            arguments: ["10"],
            timeout: 0.1,
            outputLimit: 1024
        )

        XCTAssertEqual(result.outcome, .timedOut)
    }

    func testCancellationTerminatesLongRunningProcess() async throws {
        let task = Task {
            await ProcessRunner.shared.run(
                executableURL: URL(fileURLWithPath: "/bin/sleep"),
                arguments: ["10"],
                timeout: 5,
                outputLimit: 1024
            )
        }

        try await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()
        let result = await task.value

        XCTAssertEqual(result.outcome, .cancelled)
    }

    func testOutputIsCappedAndMarkedTruncated() async {
        let output = String(repeating: "x", count: 8_192)
        let result = await ProcessRunner.shared.run(
            executableURL: URL(fileURLWithPath: "/usr/bin/printf"),
            arguments: ["%s", output],
            timeout: 5,
            outputLimit: 1_024
        )

        XCTAssertEqual(result.outcome, .exited(0))
        XCTAssertEqual(result.output.utf8.count, 1_024)
        XCTAssertTrue(result.wasTruncated)
    }
}
#endif

private struct StubLocator: ExecutableLocating {
    let executables: [String: URL]

    func locate(named executableName: String) -> URL? {
        executables[executableName]
    }
}

private actor RecordingRunner: ProcessRunning {
    struct Call: Equatable, Sendable {
        let executableURL: URL
        let arguments: [String]
        let timeout: TimeInterval
        let outputLimit: Int
    }

    private let result: ProcessResult
    private var calls: [Call] = []

    init(result: ProcessResult) {
        self.result = result
    }

    func run(
        executableURL: URL,
        arguments: [String],
        timeout: TimeInterval,
        outputLimit: Int
    ) async -> ProcessResult {
        calls.append(Call(
            executableURL: executableURL,
            arguments: arguments,
            timeout: timeout,
            outputLimit: outputLimit
        ))
        return result
    }

    func recordedCalls() -> [Call] {
        calls
    }
}

private actor RefreshProbe {
    private let delayNanoseconds: UInt64
    private var calls = 0
    private var active = 0
    private var maximumConcurrency = 0

    init(delayNanoseconds: UInt64) {
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchTools() async -> [ToolUsage] {
        calls += 1
        active += 1
        maximumConcurrency = max(maximumConcurrency, active)
        try? await Task.sleep(nanoseconds: delayNanoseconds)
        active -= 1
        return []
    }

    func snapshot() -> (calls: Int, maximumConcurrency: Int) {
        (calls, maximumConcurrency)
    }
}

private actor CancellationProbe {
    private var started = false
    private var cancelled = false
    private var calls = 0

    func fetchTools() async -> [ToolUsage] {
        calls += 1
        started = true
        do {
            try await Task.sleep(nanoseconds: UInt64.max)
        } catch {
            cancelled = true
        }
        return []
    }

    func hasStarted() -> Bool {
        started
    }

    func wasCancelled() -> Bool {
        cancelled
    }

    func callCount() -> Int {
        calls
    }
}

private actor SchedulerIntervalRecorder {
    private var recordedIntervals: [TimeInterval] = []

    func recordAndWait(_ interval: TimeInterval) async throws {
        recordedIntervals.append(interval)
        try await Task.sleep(nanoseconds: UInt64.max)
    }

    func intervals() -> [TimeInterval] {
        recordedIntervals
    }
}

private func successfulResult(_ output: String) -> ProcessResult {
    ProcessResult(outcome: .exited(0), output: output, wasTruncated: false)
}
