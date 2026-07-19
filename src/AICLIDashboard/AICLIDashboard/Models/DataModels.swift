import Foundation

/// A stable, vendor-defined limit metric.
struct LimitMetric: Identifiable, Codable, Equatable, Sendable {
    var id: String { name }
    let name: String
    let value: Double
    let detail: String
}

/// The last bounded observation for a supported AI CLI tool.
struct ToolUsage: Identifiable, Codable, Equatable, Sendable {
    var id: String { toolName }
    let toolName: String
    var status: String
    var usageValue: String
    var metric: String
    var limits: [LimitMetric]
    var dataSource: String

    init(
        toolName: String,
        status: String,
        usageValue: String,
        metric: String,
        limits: [LimitMetric] = [],
        dataSource: String = "Availability probe"
    ) {
        self.toolName = toolName
        self.status = status
        self.usageValue = usageValue
        self.metric = metric
        self.limits = limits
        self.dataSource = dataSource
    }
}

/// A conservative MCP inventory observation. "Configured" does not imply that
/// a protocol-level health check succeeded.
struct MCPConnection: Identifiable, Codable, Equatable, Sendable {
    var id: String { serverName }
    let serverName: String
    var status: ConnectionStatus

    enum ConnectionStatus: String, Codable, Sendable {
        case configured = "Configured"
        case unavailable = "Unavailable"
        case error = "Error"
    }
}
