import SwiftUI

/// The main dashboard view with glassmorphism design and hover opacity.
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var isHovering = false
    @AppStorage("windowOpacity") private var windowOpacity: Double = 0.85
    
    var currentOpacity: Double {
        isHovering ? min(windowOpacity + 0.10, 0.95) : windowOpacity
    }
    
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
            
            // Footer with error status
            HStack {
                if let error = viewModel.lastError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Updated: \(viewModel.lastUpdated, style: .time)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
        .frame(width: 280, height: 380)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(currentOpacity))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}
