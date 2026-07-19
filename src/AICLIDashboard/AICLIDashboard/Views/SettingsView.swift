import ServiceManagement
import SwiftUI

/// Settings use conservative defaults: one interval, opt-in polling, and no
/// transparent/floating rendering mode.
struct SettingsView: View {
    @AppStorage("autoRefreshEnabled") private var autoRefreshEnabled = false
    @AppStorage("refreshInterval") private var refreshInterval: Double = 120
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    @AppStorage("monitorGemini") private var monitorGemini = true
    @AppStorage("monitorCodex") private var monitorCodex = true
    @AppStorage("monitorClaude") private var monitorClaude = true

    var body: some View {
        Form {
            Section("Refresh") {
                Toggle("Enable automatic refresh", isOn: $autoRefreshEnabled)

                HStack {
                    Text("Interval")
                    Slider(value: $refreshInterval, in: 60...600, step: 60)
                        .disabled(!autoRefreshEnabled)
                    Text("\(Int(refreshInterval))s")
                        .frame(width: 48)
                }

                Text("Changes apply immediately. Hidden windows do not refresh.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Monitor") {
                Toggle("Gemini CLI", isOn: $monitorGemini)
                Toggle("Codex CLI", isOn: $monitorCodex)
                Toggle("Claude Code", isOn: $monitorClaude)
            }

            Section("Rendering") {
                Text("Safe mode uses an opaque, non-floating, animation-free window.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

                Button("Reset to Safe Defaults") {
                    resetToDefaults()
                }
                .foregroundColor(.red)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 480)
        .navigationTitle("Settings")
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        guard #available(macOS 13.0, *) else { return }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            LoggingService.shared.log(
                "Failed to update launch at login: \(error.localizedDescription)",
                level: .error
            )
        }
    }

    private func resetToDefaults() {
        autoRefreshEnabled = false
        refreshInterval = 120
        launchAtLogin = false
        monitorGemini = true
        monitorCodex = true
        monitorClaude = true
    }
}
