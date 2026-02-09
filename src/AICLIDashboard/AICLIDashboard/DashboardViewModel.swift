import SwiftUI
import Combine

/// ViewModel that orchestrates fetching and refreshing dashboard data.
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var toolUsages: [ToolUsage] = []
    @Published var mcpConnections: [MCPConnection] = []
    @Published var lastUpdated: Date = Date()
    @Published var isLoading: Bool = false
    @Published var lastError: String? = nil
    
    @AppStorage("cliRefreshInterval") private var cliRefreshInterval: Double = 30
    @AppStorage("mcpRefreshInterval") private var mcpRefreshInterval: Double = 10
    @AppStorage("monitorGemini") private var monitorGemini: Bool = true
    @AppStorage("monitorCodex") private var monitorCodex: Bool = true
    @AppStorage("monitorClaude") private var monitorClaude: Bool = true
    
    private var cliTimer: AnyCancellable?
    private var mcpTimer: AnyCancellable?
    
    init() {
        startTimers()
        Task { await refresh() }
    }
    
    /// Refreshes all data from CLI tools and MCP servers.
    func refresh() async {
        isLoading = true
        lastError = nil
        
        // Fetch CLI statuses based on user preferences
        var tools: [ToolUsage] = []
        
        if monitorGemini {
            tools.append(await AICLIService.fetchGeminiStatus())
        }
        if monitorCodex {
            tools.append(await AICLIService.fetchCodexStatus())
        }
        if monitorClaude {
            tools.append(await AICLIService.fetchClaudeUsage())
        }
        
        // Check for errors
        let hasError = tools.contains { $0.status == "Error" || $0.status == "連線中斷" }
        if hasError {
            lastError = "部分工具無法連線"
        }
        
        toolUsages = tools
        lastUpdated = Date()
        isLoading = false
    }
    
    /// Refreshes MCP connections only.
    func refreshMCP() async {
        mcpConnections = await MCPService.fetchAllConnections()
    }
    
    /// Starts separate timers for CLI and MCP refresh.
    private func startTimers() {
        // CLI refresh timer (default 30s)
        cliTimer = Timer.publish(every: cliRefreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.refresh() }
            }
        
        // MCP refresh timer (default 10s)
        mcpTimer = Timer.publish(every: mcpRefreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.refreshMCP() }
            }
        
        // Initial MCP fetch
        Task { await refreshMCP() }
    }
    
    /// Restarts timers when intervals change.
    func restartTimers() {
        cliTimer?.cancel()
        mcpTimer?.cancel()
        startTimers()
    }
}
