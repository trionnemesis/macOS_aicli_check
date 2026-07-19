import SwiftUI

/// A row displaying a single AI CLI tool's status and usage.
struct ToolRowView: View {
    let tool: ToolUsage
    
    var statusColor: Color {
        switch tool.status.lowercased() {
        case "available": return .green
        case "unsupported": return .blue
        case "unavailable", "cancelled": return .gray
        case "timed out": return .orange
        case "error": return .red
        default: return .secondary
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                // Tool name
                Text(tool.toolName)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                Spacer()
                
                if tool.limits.isEmpty {
                    VStack(alignment: .trailing) {
                        Text(tool.status)
                            .font(.system(.callout, design: .rounded))
                            .fontWeight(.medium)
                        Text(tool.usageValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            // Limit Metrics with Progress Bars
            if !tool.limits.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tool.limits) { limit in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(limit.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(limit.detail)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            
                            ProgressView(value: limit.value)
                                .progressViewStyle(.linear)
                                .tint(limit.value < 0.2 ? .red : .blue)
                                .scaleEffect(x: 1, y: 0.5, anchor: .center)
                        }
                    }
                }
                .padding(.leading, 12)
            }

            Text("Source: \(tool.dataSource)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }
}
