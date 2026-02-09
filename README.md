# AICLIDashboard

AICLIDashboard 是一個 macOS 桌面小工具（Widget），旨在監控各種 AI CLI 工具的狀態和使用情況，並檢查 MCP（Model Context Protocol）伺服器的連接狀態。它以半透明的浮動視窗形式運行在桌面上，讓您可以隨時掌握 AI 工具的運行狀況。

## 功能特點

- **AI CLI 工具監控**：
  - **Gemini CLI**：檢查 `gemini /status`，顯示 Token 使用量或狀態。
  - **Codex CLI**：檢查 `codex /status`，顯示請求次數或狀態。
  - **Claude Code**：檢查 `claude /usage`，顯示費用或 Token 使用量。

- **MCP 伺服器監控**：
  - 監控已知 MCP 伺服器（如 `chrome-devtools`、`context7`、`playwright`）的連接狀態。
  - 通過檢查進程或設定檔來判斷伺服器是否正在運行。

- **桌面小工具體驗**：
  - 半透明視窗，不遮擋視線。
  - 始終保持在桌面層級之上（Floating）。
  - 自動每 30 秒重新整理數據。
  - 支援 macOS 14 (Sonoma) 及以上版本。

## 安裝與使用方式

### 前置需求
- macOS 14 (Sonoma) 或更高版本。
- 已安裝 Swift (通常包含在 Xcode 或 Command Line Tools 中)。
- 確保您已安裝並配置了相應的 AI CLI 工具（如 `gemini`、`codex`、`claude`），並且可以在終端機中執行它們。

### 安裝步驟

1. **複製專案**：
   ```bash
   git clone <repository-url>
   cd AICLIDashboard
   ```

2. **編譯專案**：
   使用 Swift Package Manager 編譯：
   ```bash
   cd src/AICLIDashboard
   swift build -c release
   ```

3. **執行程式**：
   編譯完成後，執行檔位於 `.build/release` 目錄下：
   ```bash
   ./.build/release/AICLIDashboard
   ```
   或者直接透過 Swift 執行（開發模式）：
   ```bash
   swift run
   ```

### 注意事項
- 首次執行時，可能需要允許程式存取網路或自動化權限（視 macOS 安全設定而定）。
- 由於使用了 `zsh -l -c` 來執行命令，程式會讀取您的 `.zshrc` 或 `.zprofile` 設定，確保 CLI 工具的路徑已包含在 `PATH` 環境變數中。

## 開發

本專案使用 SwiftUI 開發，結構如下：
- `AICLIDashboardApp.swift`: 應用程式入口與視窗設定。
- `DashboardViewModel.swift`: 負責數據獲取與定期更新。
- `Services/`: 包含與 Shell 互動及解析 CLI 輸出的邏輯。
- `Models/`: 定義數據結構。

歡迎提交 Pull Request 或 Issue 來改進此專案！
