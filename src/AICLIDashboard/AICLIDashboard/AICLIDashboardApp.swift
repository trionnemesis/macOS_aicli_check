import SwiftUI

@main
struct AICLIDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

// MARK: - App Delegate for Desktop Widget Behavior

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Make window semi-transparent and always on desktop
        if let window = NSApp.windows.first {
            window.isOpaque = false
            window.backgroundColor = NSColor.clear.withAlphaComponent(0.01)
            window.level = .floating // Keeps it above desktop but below modal dialogs
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        }
    }
}
