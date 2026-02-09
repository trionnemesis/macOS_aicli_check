import Foundation

/// Data model representing a specific limit or metric for a CLI tool.
struct LimitMetric: Identifiable, Codable {
    var id = UUID()
    let name: String      // e.g., "5h limit", "Weekly limit"
    let value: Double     // e.g., 0.86 (for 86%)
    let detail: String    // e.g., "86% left (resets 01:32)"
}

/// Data model representing the usage statistics for a single AI CLI tool.
struct ToolUsage: Identifiable, Codable {
    var id = UUID()
    let toolName: String
    var status: String    // e.g., "OK", "Error", "未連線"
    var usageValue: String // Primary value (deprecated/fallback)
    var metric: String    // Primary metric name (deprecated/fallback)
    var limits: [LimitMetric] = []
    
    // Initializer to maintain compatibility with existing code
    init(toolName: String, status: String, usageValue: String, metric: String, limits: [LimitMetric] = []) {
        self.toolName = toolName
        self.status = status
        self.usageValue = usageValue
        self.metric = metric
        self.limits = limits
    }
}

/// Data model representing the connection status of an MCP server.
struct MCPConnection: Identifiable, Codable {
    var id = UUID()
    let serverName: String
    var status: ConnectionStatus
    
    enum ConnectionStatus: String, Codable {
        case connected = "Connected"
        case connecting = "Connecting"
        case disconnected = "Disconnected"
        case error = "Error"
        
        var color: String {
            switch self {
            case .connected: return "green"
            case .connecting: return "yellow"
            case .disconnected: return "gray"
            case .error: return "red"
            }
        }
    }
}
