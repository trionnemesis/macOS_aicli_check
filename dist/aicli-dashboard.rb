cask "aicli-dashboard" do
  version "1.0.0"
  sha256 :no_check # Will be updated after build

  url "https://github.com/warden/macOS_aicli_check/releases/download/v#{version}/AICLIDashboard.app.zip",
      verified: "github.com/warden/macOS_aicli_check/"
  name "AI CLI Dashboard"
  desc "Desktop widget to monitor AI CLI tool usage and MCP server connections"
  homepage "https://github.com/warden/macOS_aicli_check"

  depends_on macos: ">= :sonoma"

  app "AICLIDashboard.app"

  zap trash: [
    "~/Library/Preferences/com.warden.AICLIDashboard.plist",
    "~/Library/Application Support/AICLIDashboard",
  ]
end
