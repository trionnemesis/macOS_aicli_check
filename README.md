# macOS AI CLI Dashboard

![macOS](https://img.shields.io/badge/macOS-14+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)

一個 macOS 桌面常駐工具，監控 AI CLI 工具使用量與 MCP 伺服器連線狀態。

## 功能特色

- 🔍 **AI CLI 監控**: 顯示 `gemini`, `codex`, `claude` 的使用量
- 🌐 **MCP 狀態追蹤**: 即時監控 MCP 伺服器連線狀態
- 💎 **半透明介面**: Glassmorphism 設計風格的桌面 Widget
- 🔄 **自動更新**: 每 30 秒自動刷新數據

## 安裝方式

### Homebrew (推薦)

```bash
# 添加 tap (僅需執行一次)
brew tap trionnemesis/tap

# 安裝應用程式
brew install --cask aicli-dashboard
```

### 手動安裝

1. 從 [Releases](https://github.com/trionnemesis/macOS_aicli_check/releases) 下載最新版本的 `AICLIDashboard-v1.0.0.zip`
2. 解壓縮並將 `AICLIDashboard.app` 拖曳到「應用程式」資料夾
3. 首次開啟時，右鍵點擊並選擇「打開」以繞過安全檢查

## 從原始碼建置

```bash
git clone https://github.com/trionnemesis/macOS_aicli_check.git
cd macOS_aicli_check/src/AICLIDashboard
swift build -c release
```

## 使用說明

應用程式啟動後會在桌面顯示半透明視窗，自動偵測並顯示：

- **Tool Usage**: AI CLI 工具的使用狀態
- **MCP Servers**: 本地 MCP 伺服器連線狀態

點擊右上角的刷新按鈕可手動更新數據。

## 系統需求

- macOS 14.0 (Sonoma) 或更新版本
- Apple Silicon (M3+) 或 Intel 處理器

## 技術細節

- **語言**: Swift 5.9+
- **框架**: SwiftUI
- **架構**: DBML + Gherkin (BDD)

## 授權

Copyright © 2026 warden. All rights reserved.
