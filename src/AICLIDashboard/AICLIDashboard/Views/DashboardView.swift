import SwiftUI

/// The single, opaque dashboard surface used by the safe rendering mode.
struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI CLI Dashboard")
                    .font(.headline)
                Spacer()
                Button(action: viewModel.requestRefresh) {
                    Image(systemName: viewModel.isLoading ? "hourglass" : "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
                .accessibilityLabel(viewModel.isLoading ? "Refreshing" : "Refresh")
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("AI CLI Availability")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if viewModel.toolUsages.isEmpty {
                    Text("Waiting for a safe refresh")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.toolUsages) { tool in
                        ToolRowView(tool: tool)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Configured MCP Servers")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if viewModel.mcpConnections.isEmpty {
                    Text("No supported MCP configuration found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.mcpConnections) { connection in
                        MCPStatusView(connection: connection)
                    }
                }
            }

            Spacer()

            HStack {
                if let error = viewModel.lastError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if let lastUpdated = viewModel.lastUpdated {
                    Text("Updated: \(lastUpdated, style: .time)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    Text("Automatic refresh is off by default")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
        .frame(width: 320, height: 420)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .onAppear {
            viewModel.setWindowVisible(true)
        }
        .onDisappear {
            viewModel.setWindowVisible(false)
        }
    }
}
