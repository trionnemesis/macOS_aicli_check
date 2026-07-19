Feature: 儀表板顯示 (Dashboard Display)

  Rule: 只顯示可由明確資料來源證實的 AI CLI 狀態
    Example: 顯示受支援 adapter 回傳的使用資訊
      Given "Codex CLI" adapter 有新鮮且可解析的使用資訊
      When 儀表板更新資料時
      Then 儀表板應顯示 "Codex CLI" 的使用資訊
      And 儀表板應顯示資料來源與最後更新時間

    Example: 不以互動式 slash command 冒充 headless API
      Given "Gemini CLI" 沒有可用的 bounded machine-readable usage adapter
      When 儀表板更新資料時
      Then "Gemini CLI" 的狀態應顯示為 "Unsupported"
      And 儀表板不得啟動互動式 slash command

    Example: CLI 不存在時顯示 unavailable
      Given 使用者系統找不到 "Claude Code" executable
      When 儀表板更新資料時
      Then "Claude Code" 的狀態應顯示為 "Unavailable"
      And 該結果不得觸發自動重試

  Rule: MCP 狀態不得超過觀測證據
    Example: 顯示已設定的 MCP server
      Given MCP 設定檔包含 server "filesystem"
      When 儀表板讀取 MCP inventory 時
      Then "filesystem" 的狀態應顯示為 "Configured"

    Example: 未執行 protocol health check 時不宣稱 Connected
      Given MCP 設定檔包含 server "filesystem"
      And 儀表板沒有完成 MCP protocol health check
      When 儀表板顯示該 server 時
      Then "filesystem" 的狀態不得顯示為 "Connected"

  Rule: 預設使用低合成成本的安全顯示模式
    Example: 啟動時顯示穩定的單一面板
      Given 應用程式已啟動
      When 儀表板視窗顯示時
      Then 預設背景應為不透明
      And 視窗不應預設加入所有 Spaces
      And 視窗不應預設顯示於 full-screen app 上方

    Example: 系統要求減少動態效果
      Given macOS 已啟用 Reduce Motion 或 Reduce Transparency
      When 儀表板顯示狀態更新時
      Then 儀表板不得使用 hover opacity 動畫
      And 儀表板不得強制使用透明 material
