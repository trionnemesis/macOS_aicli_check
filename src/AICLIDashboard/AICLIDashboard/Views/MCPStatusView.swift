import SwiftUI

/// A view for displaying the status of a single MCP server connection.
struct MCPStatusView: View {
    let connection: MCPConnection
    
    var statusColor: Color {
        switch connection.status {
        case .configured: return .blue
        case .unavailable: return .gray
        case .error: return .red
        }
    }
    
    var statusIcon: String {
        switch connection.status {
        case .configured: return "gearshape.circle.fill"
        case .unavailable: return "minus.circle"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.system(size: 12))
            
            Text(connection.serverName)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
            
            Spacer()
            
            Text(connection.status.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
