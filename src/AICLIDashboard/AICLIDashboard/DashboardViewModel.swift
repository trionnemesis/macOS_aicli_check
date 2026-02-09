import SwiftUI
import Combine

/// ViewModel that orchestrates fetching and refreshing dashboard data.
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var toolUsages: [ToolUsage] = []
    @Published var mcpConnections: [MCPConnection] = []
    @Published var lastUpdated: Date = Date()
    @Published var isLoading: Bool = false
    
    private var refreshTimer: AnyCancellable?
    let refreshInterval: TimeInterval = 60 // seconds (increased to 60s to reduce power usage)
    
    init() {
        startAutoRefresh()
        Task { await refresh() }
    }
    
    /// Refreshes all data from CLI tools and MCP servers.
    func refresh() async {
        isLoading = true
        
        // Run in background to avoid blocking UI
        await Task.detached(priority: .userInitiated) { [weak self] in
            let tools = AICLIService.fetchAll()
            let mcp = MCPService.fetchAllConnections()
            
            await MainActor.run {
                self?.toolUsages = tools
                self?.mcpConnections = mcp
                self?.lastUpdated = Date()
                self?.isLoading = false
            }
        }.value
    }
    
    /// Starts a timer to auto-refresh data.
    private func startAutoRefresh() {
        refreshTimer = Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.refresh() }
            }
    }
}
