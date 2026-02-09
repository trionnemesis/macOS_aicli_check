# macOS AI CLI Dashboard (v2.0.0)

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Version](https://img.shields.io/badge/version-2.0.0-green)

一個 macOS 原生桌面儀表板，用於即時監控和顯示多個 AI CLI 工具的使用狀態。

## 🌟 主要功能

- 🔍 **AI CLI 監控**: 支持 `gemini`, `codex`, `claude` (Claude Code) 指令的使用量追蹤。
- 🌐 **MCP 伺服器狀態**: 即時監控已連線的 Model Context Protocol (MCP) 伺服器且每 10 秒自動檢查。
- 💎 **現代化設計**: 採用 Glassmorphism 半透明設計，背景透明度 85%，滑鼠懸停時自動提升至 95%。
- 📌 **桌面常駐**: 視窗始終保持在最上層，支持隨意拖拽且自動記憶上次視窗位置。
- ⚡ **系統列整合**: 最小化時縮小至選單列（Menu Bar），點擊圖示即可快速開關及存取設定。
- ⚙️ **完整自定義**: 提供設定介面調整更新頻率、透明度、選擇監控工具及設定開機自動啟動。
- 🛡️ **穩定性機制**: 內建 3 次自動重試邏輯與回應快取，保障資料獲取的穩定性。
- 📝 **錯誤日誌**: 完整的錯誤日誌追蹤功能，方便排查 CLI 連線問題。

## 💻 系統需求

- **macOS**: 13.0 (Ventura) 或更高版本。
- **處理器**: 支援 Apple Silicon (M3+) 及 Intel 架構。
- **依賴**: 建議預先安裝對應的 CLI 工具 (`gemini`, `codex`, `claude`)。

## 📦 安裝方式

### Homebrew (推薦)

這是最簡單的安裝方式：

```bash
# 添加 Tap
brew tap trionnemesis/tap

# 安裝應用程式
brew install --cask aicli-dashboard
```

### 手動安裝

1. 從 [GitHub Releases](https://github.com/trionnemesis/macOS_aicli_check/releases) 下載 `AICLIDashboard-v2.0.0.zip`。
2. 解壓縮後將 `AICLIDashboard.app` 移至 `/Applications` 文件夾。
3. 首次啟動若提示「應用程式已損毀」或安全性阻擋，請執行：
   ```bash
   xattr -cr /Applications/AICLIDashboard.app
   ```

## 🛠️ 開發與建置

若您想從原始碼自行建置：

```bash
git clone https://github.com/trionnemesis/macOS_aicli_check.git
cd macOS_aicli_check/src/AICLIDashboard
swift build -c release
```

二進位檔案將生成於 `.build/release/AICLIDashboard`。

## 📝 授權與版權

Copyright © 2026 warden. All rights reserved.
