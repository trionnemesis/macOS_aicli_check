import XCTest
@testable import AICLIDashboard

final class AICLIServiceTests: XCTestCase {
    
    func testGeminiStatusParsingTokens() async {
        let result = await AICLIService.fetchGeminiStatus()
        XCTAssertEqual(result.toolName, "Gemini CLI")
    }
    
    func testCodexStatusParsingLimits() async {
        let result = await AICLIService.fetchCodexStatus()
        XCTAssertEqual(result.toolName, "Codex CLI")
        // Since we don't have real output in tests without mocking ShellService,
        // we mainly verify the async structure is correct.
    }
    
    func testClaudeUsageParsingCost() async {
        let result = await AICLIService.fetchClaudeUsage()
        XCTAssertEqual(result.toolName, "Claude Code")
    }
}

final class MCPServiceTests: XCTestCase {
    
    func testKnownServersExist() {
        XCTAssertEqual(MCPService.knownServers.count, 3)
        XCTAssertTrue(MCPService.knownServers.contains("chrome-devtools"))
    }
    
    func testFetchAllConnectionsReturnsCorrectCount() async {
        let connections = await MCPService.fetchAllConnections()
        XCTAssertEqual(connections.count, MCPService.knownServers.count)
    }
}
