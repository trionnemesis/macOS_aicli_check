import Foundation

/// Data model representing the usage statistics for a single AI CLI tool.
struct ToolUsage: Identifiable {
    let id = UUID()
    let toolName: String
    var status: String // e.g., "OK", "Error", "Not Installed"
    var usageValue: String // e.g., "12,500 tokens", "$0.50"
    var metric: String // e.g., "Tokens Used", "Cost Today"
}

/// Data model representing the connection status of an MCP server.
struct MCPConnection: Identifiable {
    let id = UUID()
    let serverName: String
    var status: ConnectionStatus
    
    enum ConnectionStatus: String {
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
