cask "aicli-dashboard" do
  version "2.1.0"
  sha256 "d320ba5452632b7c056afd881f2970d25897f81d32c7331baa25ffccd5f438bc"

  url "https://github.com/trionnemesis/macOS_aicli_check/releases/download/v#{version}/AICLIDashboard-v#{version}.zip",
      verified: "github.com/trionnemesis/macOS_aicli_check/"
  name "AI CLI Dashboard"
  desc "Desktop widget to monitor AI CLI tool usage and MCP server connections"
  homepage "https://github.com/trionnemesis/macOS_aicli_check"

  depends_on macos: ">= :ventura"

  app "AICLIDashboard.app"

  postflight do
    system_command "/usr/bin/xattr", args: ["-cr", "#{appdir}/AICLIDashboard.app"]
  end

  zap trash: [
    "~/Library/Preferences/com.warden.AICLIDashboard.plist",
    "~/Library/Application Support/AICLIDashboard",
  ]
end
