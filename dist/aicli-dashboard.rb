cask "aicli-dashboard" do
  version "2.0.0"
  sha256 "d56de7aa3792bf65c2fb2c2678e8cb7a4cf244b03ff176f6425b5077b61b2773"

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
