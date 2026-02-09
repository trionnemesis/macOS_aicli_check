import SwiftUI

/// A row displaying a single AI CLI tool's status and usage.
struct ToolRowView: View {
    let tool: ToolUsage
    
    var statusColor: Color {
        switch tool.status.lowercased() {
        case "ok": return .green
        case "error": return .red
        case "not installed": return .gray
        default: return .yellow
        }
    }
    
    var body: some View {
        HStack {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            // Tool name
            Text(tool.toolName)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
            
            Spacer()
            
            // Usage value
            VStack(alignment: .trailing) {
                Text(tool.usageValue)
                    .font(.system(.callout, design: .rounded))
                    .fontWeight(.medium)
                Text(tool.metric)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
