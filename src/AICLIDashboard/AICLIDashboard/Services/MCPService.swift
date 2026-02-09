import Foundation

/// Service to check MCP server connection statuses.
enum MCPService {
    
    /// Known MCP servers to check (can be expanded or made configurable).
    static let knownServers = ["chrome-devtools", "context7", "playwright"]
    
    /// Fetches the connection status for all known MCP servers.
    static func fetchAllConnections() async -> [MCPConnection] {
        return await Task.detached(priority: .userInitiated) {
            knownServers.map { serverName in
                let status = checkServerStatus(name: serverName)
                return MCPConnection(serverName: serverName, status: status)
            }
        }.value
    }
    
    /// Checks if a specific MCP server is running.
    private static func checkServerStatus(name: String) -> MCPConnection.ConnectionStatus {
        // Strategy 1: Check for process by name
        if let processOutput = ShellService.run("pgrep -fl '\(name)' 2>/dev/null"),
           !processOutput.isEmpty {
            return .connected
        }
        
        // Strategy 2: Check common MCP config locations
        let configPaths = [
            "~/.config/mcp/servers.json",
            "~/.mcp/config.json",
            "~/.claude/mcp.json"
        ]
        
        for path in configPaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            if let config = ShellService.run("cat '\(expandedPath)' 2>/dev/null"),
               config.contains(name) {
                // Config exists for this server, but check if actually running
                if let lsof = ShellService.run("lsof -i -P 2>/dev/null | grep -i '\(name)'"),
                   !lsof.isEmpty {
                    return .connected
                }
                return .disconnected
            }
        }
        
        return .disconnected
    }
}
