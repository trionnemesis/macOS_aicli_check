Feature: 儀表板顯示 (Dashboard Display)

  Rule: 顯示 AI CLI 工具使用量 (Display AI CLI Tool Usage)
    Example: 顯示 gemini cli 的使用量
      Given 用戶可以使用 "gemini cli"
      When 儀表板更新數據時
      Then 儀表板應顯示 "gemini cli" 的 "tokens" 使用量
      And 儀表板應顯示 "gemini cli" 的 "status"

    Example: 顯示 codex cli 的使用量
      Given 用戶可以使用 "codex cli"
      When 儀表板更新數據時
      Then 儀表板應顯示 "codex cli" 的 "requests" 使用量

    Example: 顯示 claude code 的使用量
      Given 用戶可以使用 "claude code"
      When 儀表板更新數據時
      Then 儀表板應顯示 "claude code" 的 "cost" 使用量

  Rule: 顯示 MCP 連線狀態 (Display MCP Connection Status)
    Example: 顯示活躍的 MCP 連線
      Given MCP server "filesystem" 正在運行
      When 儀表板檢查連線狀態時
      Then "filesystem" 的狀態應顯示為 "Connected"

    Example: 顯示斷開的 MCP 連線
      Given MCP server "calculator" 已停止
      When 儀表板檢查連線狀態時
      Then "calculator" 的狀態應顯示為 "Disconnected"

  Rule: 桌面常駐與透明顯示 (Desktop Widget Appearance)
    Example: 啟動時顯示半透明視窗
      Given 應用程式已啟動
      When 視窗顯示在桌面上時
      Then視窗背景應為 "半透明" (Translucent)
      And 視窗應保持在 "Desktop Level" (常駐桌面)
