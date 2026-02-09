import SwiftUI
import AppKit

@main
struct AICLIDashboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .background(WindowAccessor { window in
                    appDelegate.configureWindow(window)
                })
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("Hide Window") {
                    NSApp.hide(nil)
                }
                .keyboardShortcut("h", modifiers: [.command])
                
                Divider()
                
                Button("Quit AI CLI Dashboard") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: [.command])
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}

// MARK: - Window Accessor Helper

struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                callback(window)
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBarIcon()
        
        // Prevent app from terminating when window is closed
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Minimize to menu bar instead of quitting
        return false
    }
    
    func configureWindow(_ window: NSWindow) {
        // Translucent background
        window.isOpaque = false
        window.backgroundColor = NSColor.clear.withAlphaComponent(0.01)
        
        // Always on top (floating level)
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Enable dragging
        window.isMovableByWindowBackground = true
        
        // Restore saved position
        if let savedFrame = UserDefaults.standard.string(forKey: "windowFrame") {
            window.setFrame(from: savedFrame)
        }
        
        // Save position when window moves
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { _ in
            UserDefaults.standard.set(window.frameDescriptor, forKey: "windowFrame")
        }
    }
    
    private func setupMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "AI CLI Dashboard")
            button.action = #selector(toggleWindow)
            button.target = self
        }
        
        // Setup menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Dashboard", action: #selector(showWindow), keyEquivalent: "s"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc private func toggleWindow() {
        if let window = NSApp.windows.first(where: { $0.title != "Settings" }) {
            if window.isVisible {
                window.orderOut(nil)
            } else {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    @objc private func showWindow() {
        if let window = NSApp.windows.first(where: { $0.title != "Settings" }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
