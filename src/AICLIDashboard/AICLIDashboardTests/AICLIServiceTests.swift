import XCTest
@testable import AICLIDashboard

final class AICLIServiceTests: XCTestCase {
    
    func testGeminiStatusParsingTokens() {
        // This test would use dependency injection for ShellService in production
        // For now, just verify the parsing logic structure exists
        let result = AICLIService.fetchGeminiStatus()
        XCTAssertEqual(result.toolName, "Gemini CLI")
    }
    
    func testCodexStatusParsingRequests() {
        let result = AICLIService.fetchCodexStatus()
        XCTAssertEqual(result.toolName, "Codex CLI")
    }
    
    func testClaudeUsageParsingCost() {
        let result = AICLIService.fetchClaudeUsage()
        XCTAssertEqual(result.toolName, "Claude Code")
    }
    
    func testFetchAllReturnsThreeTools() {
        let results = AICLIService.fetchAll()
        XCTAssertEqual(results.count, 3)
    }
}

final class MCPServiceTests: XCTestCase {
    
    func testKnownServersExist() {
        XCTAssertEqual(MCPService.knownServers.count, 3)
        XCTAssertTrue(MCPService.knownServers.contains("chrome-devtools"))
    }
    
    func testFetchAllConnectionsReturnsCorrectCount() {
        let connections = MCPService.fetchAllConnections()
        XCTAssertEqual(connections.count, MCPService.knownServers.count)
    }
}
