cask "aicli-dashboard" do
  version "1.0.0"
  sha256 "d4edf1d8e6fff2f2092600b45166949a8eb21d00c81f2e41711aea1cdc2fc40c"

  url "https://github.com/trionnemesis/macOS_aicli_check/releases/download/v#{version}/AICLIDashboard-v#{version}.zip",
      verified: "github.com/trionnemesis/macOS_aicli_check/"
  name "AI CLI Dashboard"
  desc "Desktop widget to monitor AI CLI tool usage and MCP server connections"
  homepage "https://github.com/trionnemesis/macOS_aicli_check"

  depends_on macos: ">= :sonoma"

  app "AICLIDashboard.app"

  zap trash: [
    "~/Library/Preferences/com.warden.AICLIDashboard.plist",
    "~/Library/Application Support/AICLIDashboard",
  ]
end
