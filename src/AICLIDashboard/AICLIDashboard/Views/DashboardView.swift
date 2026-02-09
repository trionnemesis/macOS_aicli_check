import SwiftUI

/// The main dashboard view with a glassmorphism (translucent) design.
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("AI CLI Dashboard")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Button(action: { Task { await viewModel.refresh() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Divider()
            
            // Tool Usage Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Tool Usage")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                ForEach(viewModel.toolUsages) { tool in
                    ToolRowView(tool: tool)
                }
            }
            
            Divider()
            
            // MCP Connections Section
            VStack(alignment: .leading, spacing: 8) {
                Text("MCP Servers")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                ForEach(viewModel.mcpConnections) { conn in
                    MCPStatusView(connection: conn)
                }
            }
            
            Spacer()
            
            // Footer
            Text("Updated: \(viewModel.lastUpdated, style: .time)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(width: 280, height: 360)
        .background(
            // Glassmorphism effect
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}
