import Foundation

/// Service to fetch usage data from the supported AI CLI tools.
enum AICLIService {
    
    // MARK: - Gemini CLI
    
    /// Parses the output of `gemini /status` command.
    static func fetchGeminiStatus() -> ToolUsage {
        guard let output = ShellService.run("gemini /status 2>/dev/null") else {
            return ToolUsage(toolName: "Gemini CLI", status: "Not Installed", usageValue: "—", metric: "Status")
        }
        
        if output.lowercased().contains("error") || output.isEmpty {
            return ToolUsage(toolName: "Gemini CLI", status: "Error", usageValue: output.isEmpty ? "No Response" : String(output.prefix(40)), metric: "Status")
        }
        
        // Try to extract token usage (example format: "Tokens: 12,500")
        if let match = extractFirst(pattern: "Tokens?:?\\s*([\\d,]+)", from: output) {
            return ToolUsage(toolName: "Gemini CLI", status: "OK", usageValue: match, metric: "Tokens")
        }
        
        return ToolUsage(toolName: "Gemini CLI", status: "OK", usageValue: String(output.prefix(50)), metric: "Status")
    }
    
    // MARK: - Codex CLI
    
    /// Parses the output of `codex /status` command.
    static func fetchCodexStatus() -> ToolUsage {
        guard let output = ShellService.run("codex /status 2>/dev/null") else {
            return ToolUsage(toolName: "Codex CLI", status: "Not Installed", usageValue: "—", metric: "Status")
        }
        
        if output.lowercased().contains("error") || output.isEmpty {
            return ToolUsage(toolName: "Codex CLI", status: "Error", usageValue: output.isEmpty ? "No Response" : String(output.prefix(40)), metric: "Status")
        }
        
        // Try to extract multi-line limit info (e.g., "5h limit" and "Weekly limit")
        var details = [String]()
        if let h5Match = extractFirst(pattern: "5h limit:.*?(\\d+%)", from: output) {
            details.append("5h: \(h5Match)")
        }
        if let weeklyMatch = extractFirst(pattern: "Weekly limit:.*?(\\d+%)", from: output) {
            details.append("Wkly: \(weeklyMatch)")
        }

        if !details.isEmpty {
            return ToolUsage(toolName: "Codex CLI", status: "OK", usageValue: details.joined(separator: " | "), metric: "Limits Left")
        }

        // Fallback to requests count
        if let match = extractFirst(pattern: "Requests?:?\\s*([\\d,]+)", from: output) {
            return ToolUsage(toolName: "Codex CLI", status: "OK", usageValue: match, metric: "Requests")
        }
        
        return ToolUsage(toolName: "Codex CLI", status: "OK", usageValue: String(output.prefix(50)), metric: "Status")
    }
    
    // MARK: - Claude Code
    
    /// Parses the output of `claude /usage` command.
    static func fetchClaudeUsage() -> ToolUsage {
        guard let output = ShellService.run("claude /usage 2>/dev/null") else {
            return ToolUsage(toolName: "Claude Code", status: "Not Installed", usageValue: "—", metric: "Usage")
        }
        
        if output.lowercased().contains("error") || output.isEmpty {
            return ToolUsage(toolName: "Claude Code", status: "Error", usageValue: output.isEmpty ? "No Response" : String(output.prefix(40)), metric: "Usage")
        }
        
        // Try to extract cost (example format: "Cost: $1.23")
        if let match = extractFirst(pattern: "\\$[\\d,.]+", from: output) {
            return ToolUsage(toolName: "Claude Code", status: "OK", usageValue: match, metric: "Cost")
        }
        
        // Try to extract tokens
        if let match = extractFirst(pattern: "([\\d,]+)\\s*tokens?", from: output) {
            return ToolUsage(toolName: "Claude Code", status: "OK", usageValue: match + " tokens", metric: "Tokens")
        }
        
        return ToolUsage(toolName: "Claude Code", status: "OK", usageValue: String(output.prefix(50)), metric: "Usage")
    }
    
    /// Fetches all CLI tool statuses.
    static func fetchAll() -> [ToolUsage] {
        return [
            fetchGeminiStatus(),
            fetchCodexStatus(),
            fetchClaudeUsage()
        ]
    }
    
    // MARK: - Helpers
    
    /// Extracts the first match (or first capture group) from a regex pattern.
    private static func extractFirst(pattern: String, from text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }
        
        // If there's a capture group, return it; otherwise return the full match
        let captureRange = match.numberOfRanges > 1 ? match.range(at: 1) : match.range
        guard let swiftRange = Range(captureRange, in: text) else {
            return nil
        }
        return String(text[swiftRange])
    }
}
