import Foundation

/// Service to fetch usage data from the supported AI CLI tools with retry logic.
enum AICLIService {
    
    private static let maxRetries = 3
    private static var cache: [String: (data: ToolUsage, timestamp: Date)] = [:]
    private static let cacheValiditySeconds: TimeInterval = 5
    
    // MARK: - Gemini CLI
    
    /// Fetches Gemini CLI status with retry logic.
    static func fetchGeminiStatus() async -> ToolUsage {
        return await fetchWithRetry(cacheKey: "gemini") {
            parseGeminiOutput(ShellService.run("gemini /status 2>/dev/null"))
        }
    }
    
    private static func parseGeminiOutput(_ output: String?) -> ToolUsage {
        guard let output = output, !output.isEmpty else {
            return ToolUsage(toolName: "Gemini CLI", status: "未連線", usageValue: "—", metric: "Status")
        }
        
        if output.lowercased().contains("error") {
            LoggingService.shared.log("Gemini CLI error: \(output)", level: .warning)
            return ToolUsage(toolName: "Gemini CLI", status: "Error", usageValue: String(output.prefix(40)), metric: "Status")
        }
        
        if let match = extractFirst(pattern: "Tokens?:?\\s*([\\d,]+)", from: output) {
            return ToolUsage(toolName: "Gemini CLI", status: "OK", usageValue: match, metric: "Tokens")
        }
        
        return ToolUsage(toolName: "Gemini CLI", status: "OK", usageValue: String(output.prefix(50)), metric: "Status")
    }
    
    // MARK: - Codex CLI
    
    /// Fetches Codex CLI status with retry logic.
    static func fetchCodexStatus() async -> ToolUsage {
        return await fetchWithRetry(cacheKey: "codex") {
            parseCodexOutput(ShellService.run("codex /status 2>/dev/null"))
        }
    }
    
    private static func parseCodexOutput(_ output: String?) -> ToolUsage {
        guard let output = output, !output.isEmpty else {
            return ToolUsage(toolName: "Codex CLI", status: "未連線", usageValue: "—", metric: "Status")
        }
        
        if output.lowercased().contains("error") {
            LoggingService.shared.log("Codex CLI error: \(output)", level: .warning)
            return ToolUsage(toolName: "Codex CLI", status: "Error", usageValue: String(output.prefix(40)), metric: "Status")
        }
        
        var limits: [LimitMetric] = []
        
        // Pattern for "5h limit: [###] 86% left (resets 01:32)"
        let limitPattern = "([\\d\\w\\s]+limit):\\s*\\[[^\\]]*\\]\\s*(\\d+)%\\s*left\\s*\\(resets\\s+([\\d:]+)\\)"
        
        if let regex = try? NSRegularExpression(pattern: limitPattern, options: []) {
            let range = NSRange(output.startIndex..., in: output)
            let matches = regex.matches(in: output, options: [], range: range)
            
            for match in matches {
                if match.numberOfRanges == 4,
                   let nameRange = Range(match.range(at: 1), in: output),
                   let percentRange = Range(match.range(at: 2), in: output),
                   let resetRange = Range(match.range(at: 3), in: output) {
                    
                    let name = String(output[nameRange]).trimmingCharacters(in: .whitespaces)
                    let percent = Double(output[percentRange]) ?? 0
                    let reset = String(output[resetRange])
                    
                    limits.append(LimitMetric(
                        name: name,
                        value: percent / 100.0,
                        detail: "\(Int(percent))% left (resets \(reset))"
                    ))
                }
            }
        }
        
        // Fallback or summary value
        let summaryValue = limits.first?.detail ?? "Connected"
        
        return ToolUsage(
            toolName: "Codex CLI",
            status: "OK",
            usageValue: summaryValue,
            metric: "Limits",
            limits: limits
        )
    }
    
    // MARK: - Claude Code
    
    /// Fetches Claude Code usage with retry logic.
    static func fetchClaudeUsage() async -> ToolUsage {
        return await fetchWithRetry(cacheKey: "claude") {
            parseClaudeOutput(ShellService.run("claude /usage 2>/dev/null"))
        }
    }
    
    private static func parseClaudeOutput(_ output: String?) -> ToolUsage {
        guard let output = output, !output.isEmpty else {
            return ToolUsage(toolName: "Claude Code", status: "未連線", usageValue: "—", metric: "Usage")
        }
        
        if output.lowercased().contains("error") {
            LoggingService.shared.log("Claude Code error: \(output)", level: .warning)
            return ToolUsage(toolName: "Claude Code", status: "Error", usageValue: String(output.prefix(40)), metric: "Usage")
        }
        
        if let match = extractFirst(pattern: "\\$[\\d,.]+", from: output) {
            return ToolUsage(toolName: "Claude Code", status: "OK", usageValue: match, metric: "Cost")
        }
        
        if let match = extractFirst(pattern: "([\\d,]+)\\s*tokens?", from: output) {
            return ToolUsage(toolName: "Claude Code", status: "OK", usageValue: match + " tokens", metric: "Tokens")
        }
        
        return ToolUsage(toolName: "Claude Code", status: "OK", usageValue: String(output.prefix(50)), metric: "Usage")
    }
    
    // MARK: - Retry Logic
    
    private static func fetchWithRetry(cacheKey: String, fetch: @escaping () -> ToolUsage) async -> ToolUsage {
        // Check cache first
        if let cached = cache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheValiditySeconds {
            return cached.data
        }
        
        var lastResult: ToolUsage?
        
        for attempt in 1...maxRetries {
            let result = await Task.detached(priority: .userInitiated) {
                fetch()
            }.value
            
            if result.status != "Error" && result.status != "未連線" && result.status != "連線中斷" {
                cache[cacheKey] = (data: result, timestamp: Date())
                return result
            }
            
            lastResult = result
            
            if attempt < maxRetries {
                LoggingService.shared.log("Retry \(attempt)/\(maxRetries) for \(cacheKey)", level: .info)
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            }
        }
        
        LoggingService.shared.log("All retries failed for \(cacheKey)", level: .error)
        return lastResult ?? ToolUsage(toolName: cacheKey, status: "連線中斷", usageValue: "—", metric: "Status")
    }
    
    // MARK: - Helpers
    
    private static func extractFirst(pattern: String, from text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }
        
        let captureRange = match.numberOfRanges > 1 ? match.range(at: 1) : match.range
        guard let swiftRange = Range(captureRange, in: text) else {
            return nil
        }
        return String(text[swiftRange])
    }
}
