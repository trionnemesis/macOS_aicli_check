import Foundation

/// Service to check MCP server connection statuses.
enum MCPService {
    
    /// Known MCP servers to check (can be expanded or made configurable).
    static let knownServers = ["chrome-devtools", "context7", "playwright"]
    
    /// Fetches the connection status for all known MCP servers.
    /// This checks for running processes or local socket/port availability.
    static func fetchAllConnections() -> [MCPConnection] {
        return knownServers.map { serverName in
            let status = checkServerStatus(name: serverName)
            return MCPConnection(serverName: serverName, status: status)
        }
    }
    
    /// Checks if a specific MCP server is running.
    private static func checkServerStatus(name: String) -> MCPConnection.ConnectionStatus {
        // Strategy 1: Check for process by name
        if let processOutput = ShellService.run("pgrep -fl '\(name)' 2>/dev/null"),
           !processOutput.isEmpty {
            return .connected
        }
        
        // Strategy 2: For known ports (if any), check port availability
        // This is a placeholder - real MCP servers may have specific ports
        // Strategy 3: Check MCP config file for active servers
        if let mcpConfig = ShellService.run("cat ~/.config/mcp/servers.json 2>/dev/null"),
           mcpConfig.contains(name) {
            // Config exists, but process isn't running
            return .disconnected
        }
        
        // Unknown or not configured
        return .disconnected
    }
}
