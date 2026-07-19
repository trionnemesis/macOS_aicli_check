import Foundation

/// Bounded availability/authentication probes for supported AI CLIs.
///
/// Subscription usage is deliberately reported as unsupported until a vendor
/// adapter exposes a documented, machine-readable source. Interactive slash
/// commands are never launched by this service.
enum AICLIService {
    private static let timeout: TimeInterval = 5
    private static let outputLimit = 65_536

    static func fetchAll() async -> [ToolUsage] {
        await fetchSelected(
            monitorGemini: true,
            monitorCodex: true,
            monitorClaude: true,
            runner: ProcessRunner.shared,
            locator: SystemExecutableLocator()
        )
    }

    static func fetchSelected(
        monitorGemini: Bool,
        monitorCodex: Bool,
        monitorClaude: Bool,
        runner: any ProcessRunning,
        locator: any ExecutableLocating
    ) async -> [ToolUsage] {
        var tools: [ToolUsage] = []
        if monitorGemini {
            tools.append(await fetchGeminiStatus(runner: runner, locator: locator))
        }
        if monitorCodex {
            tools.append(await fetchCodexStatus(runner: runner, locator: locator))
        }
        if monitorClaude {
            tools.append(await fetchClaudeStatus(runner: runner, locator: locator))
        }
        return tools
    }

    static func fetchGeminiStatus(
        runner: any ProcessRunning = ProcessRunner.shared,
        locator: any ExecutableLocating = SystemExecutableLocator()
    ) async -> ToolUsage {
        await probe(
            toolName: "Gemini CLI",
            executableName: "gemini",
            arguments: ["--version"],
            source: "gemini --version",
            usageSupported: false,
            runner: runner,
            locator: locator
        )
    }

    static func fetchCodexStatus(
        runner: any ProcessRunning = ProcessRunner.shared,
        locator: any ExecutableLocating = SystemExecutableLocator()
    ) async -> ToolUsage {
        await probe(
            toolName: "Codex CLI",
            executableName: "codex",
            arguments: ["login", "status"],
            source: "codex login status",
            usageSupported: false,
            runner: runner,
            locator: locator
        )
    }

    static func fetchClaudeStatus(
        runner: any ProcessRunning = ProcessRunner.shared,
        locator: any ExecutableLocating = SystemExecutableLocator()
    ) async -> ToolUsage {
        await probe(
            toolName: "Claude Code",
            executableName: "claude",
            arguments: ["auth", "status", "--text"],
            source: "claude auth status --text",
            usageSupported: false,
            runner: runner,
            locator: locator
        )
    }

    private static func probe(
        toolName: String,
        executableName: String,
        arguments: [String],
        source: String,
        usageSupported: Bool,
        runner: any ProcessRunning,
        locator: any ExecutableLocating
    ) async -> ToolUsage {
        guard let executableURL = locator.locate(named: executableName) else {
            return ToolUsage(
                toolName: toolName,
                status: "Unavailable",
                usageValue: "Executable not found",
                metric: "Availability",
                dataSource: "Executable lookup"
            )
        }

        let result = await runner.run(
            executableURL: executableURL,
            arguments: arguments,
            timeout: timeout,
            outputLimit: outputLimit
        )

        switch result.outcome {
        case .exited(0):
            return ToolUsage(
                toolName: toolName,
                status: usageSupported ? "Available" : "Unsupported",
                usageValue: summarized(result.output, truncated: result.wasTruncated),
                metric: usageSupported ? "Usage" : "Usage adapter",
                dataSource: source
            )
        case .exited(let status):
            return ToolUsage(
                toolName: toolName,
                status: "Error",
                usageValue: result.output.isEmpty ? "Exit \(status)" : summarized(result.output, truncated: result.wasTruncated),
                metric: "Availability",
                dataSource: source
            )
        case .timedOut:
            return ToolUsage(
                toolName: toolName,
                status: "Timed Out",
                usageValue: "Probe exceeded 5 seconds",
                metric: "Availability",
                dataSource: source
            )
        case .cancelled:
            return ToolUsage(
                toolName: toolName,
                status: "Cancelled",
                usageValue: "Probe cancelled",
                metric: "Availability",
                dataSource: source
            )
        case .launchFailed(let message):
            return ToolUsage(
                toolName: toolName,
                status: "Error",
                usageValue: summarized(message, truncated: false),
                metric: "Availability",
                dataSource: source
            )
        }
    }

    private static func summarized(_ output: String, truncated: Bool) -> String {
        let normalized = output
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let summary = normalized.isEmpty ? "Available" : String(normalized.prefix(120))
        return truncated ? "\(summary)…" : summary
    }
}
