import SwiftUI
import ServiceManagement

/// Settings view for customizing dashboard behavior.
struct SettingsView: View {
    @AppStorage("windowOpacity") private var windowOpacity: Double = 0.85
    @AppStorage("cliRefreshInterval") private var cliRefreshInterval: Double = 30
    @AppStorage("mcpRefreshInterval") private var mcpRefreshInterval: Double = 10
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    
    @AppStorage("monitorGemini") private var monitorGemini: Bool = true
    @AppStorage("monitorCodex") private var monitorCodex: Bool = true
    @AppStorage("monitorClaude") private var monitorClaude: Bool = true
    
    var body: some View {
        Form {
            Section("Appearance") {
                HStack {
                    Text("Window Opacity")
                    Slider(value: $windowOpacity, in: 0.70...0.95, step: 0.05)
                    Text("\(Int(windowOpacity * 100))%")
                        .frame(width: 40)
                }
            }
            
            Section("Refresh Intervals") {
                HStack {
                    Text("CLI Status")
                    Slider(value: $cliRefreshInterval, in: 10...120, step: 10)
                    Text("\(Int(cliRefreshInterval))s")
                        .frame(width: 40)
                }
                
                HStack {
                    Text("MCP Status")
                    Slider(value: $mcpRefreshInterval, in: 5...60, step: 5)
                    Text("\(Int(mcpRefreshInterval))s")
                        .frame(width: 40)
                }
            }
            
            Section("Monitor") {
                Toggle("Gemini CLI", isOn: $monitorGemini)
                Toggle("Codex CLI", isOn: $monitorCodex)
                Toggle("Claude Code", isOn: $monitorClaude)
            }
            
            Section("System") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        updateLaunchAtLogin(newValue)
                    }
            }
            
            Section {
                Button("Open Log File") {
                    LoggingService.shared.openLogFile()
                }
                
                Button("Reset to Defaults") {
                    resetToDefaults()
                }
                .foregroundColor(.red)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 450)
        .navigationTitle("Settings")
    }
    
    private func updateLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                LoggingService.shared.log("Failed to update launch at login: \(error)")
            }
        }
    }
    
    private func resetToDefaults() {
        windowOpacity = 0.85
        cliRefreshInterval = 30
        mcpRefreshInterval = 10
        launchAtLogin = false
        monitorGemini = true
        monitorCodex = true
        monitorClaude = true
    }
}
