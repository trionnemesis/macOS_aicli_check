import Foundation

/// Reads configured MCP server names without shelling out or claiming a
/// protocol-level connection that has not been observed.
enum MCPService {
    static func fetchAllConnections(configURLs: [URL]? = nil) async -> [MCPConnection] {
        let sources = configURLs ?? defaultConfigURLs()
        return await Task.detached(priority: .utility) {
            configuredConnections(from: sources)
        }.value
    }

    static func configuredConnections(from configURLs: [URL]) -> [MCPConnection] {
        var serverNames = Set<String>()

        for url in configURLs where FileManager.default.fileExists(atPath: url.path) {
            do {
                let data = try Data(contentsOf: url, options: [.mappedIfSafe])
                if url.pathExtension.lowercased() == "toml" {
                    if let text = String(data: data, encoding: .utf8) {
                        serverNames.formUnion(parseCodexTOML(text))
                    }
                } else {
                    let value = try JSONSerialization.jsonObject(with: data)
                    collectServerNames(from: value, into: &serverNames)
                }
            } catch {
                LoggingService.shared.log(
                    "Unable to parse MCP configuration \(url.lastPathComponent): \(error.localizedDescription)",
                    level: .warning
                )
            }
        }

        return serverNames.sorted().map {
            MCPConnection(serverName: $0, status: .configured)
        }
    }

    private static func defaultConfigURLs() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent(".config/mcp/servers.json"),
            home.appendingPathComponent(".mcp/config.json"),
            home.appendingPathComponent(".claude/mcp.json"),
            home.appendingPathComponent(".claude.json"),
            home.appendingPathComponent(".gemini/settings.json"),
            home.appendingPathComponent(".codex/config.toml")
        ]
    }

    private static func collectServerNames(from value: Any, into result: inout Set<String>) {
        if let dictionary = value as? [String: Any] {
            for (key, nestedValue) in dictionary {
                if (key == "mcpServers" || key == "servers"),
                   let servers = nestedValue as? [String: Any] {
                    result.formUnion(servers.keys)
                }
                collectServerNames(from: nestedValue, into: &result)
            }
        } else if let array = value as? [Any] {
            for nestedValue in array {
                collectServerNames(from: nestedValue, into: &result)
            }
        }
    }

    private static func parseCodexTOML(_ text: String) -> Set<String> {
        let pattern = #"(?m)^\s*\[mcp_servers\.(?:\"([^\"]+)\"|([A-Za-z0-9_.-]+))\]\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let range = NSRange(text.startIndex..., in: text)
        return Set(regex.matches(in: text, range: range).compactMap { match in
            for index in 1..<match.numberOfRanges {
                if let swiftRange = Range(match.range(at: index), in: text) {
                    return String(text[swiftRange])
                }
            }
            return nil
        })
    }
}
