import AppKit
import SwiftUI

@main
@MainActor
struct AICLIDashboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = DashboardViewModel()

    var body: some Scene {
        Window("AI CLI Dashboard", id: "dashboard") {
            DashboardView(viewModel: viewModel)
                .background(WindowAccessor { window in
                    appDelegate.visibilityHandler = { [weak viewModel] visible in
                        viewModel?.setWindowVisible(visible)
                    }
                    appDelegate.configureWindow(window)
                    viewModel.setWindowVisible(
                        window.isVisible && window.occlusionState.contains(.visible)
                    )
                })
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("Hide Window") {
                    appDelegate.hideWindow()
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

// MARK: - Window Accessor

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

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                callback(window)
            }
        }
    }
}

// MARK: - App Delegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var visibilityHandler: ((Bool) -> Void)?

    private var statusItem: NSStatusItem?
    private weak var dashboardWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBarIcon()
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationDidHide(_ notification: Notification) {
        visibilityHandler?(false)
    }

    func applicationDidUnhide(_ notification: Notification) {
        notifyCurrentVisibility()
    }

    func applicationWillTerminate(_ notification: Notification) {
        visibilityHandler?(false)
    }

    func configureWindow(_ window: NSWindow) {
        guard dashboardWindow !== window else { return }
        dashboardWindow = window

        window.delegate = self
        window.isOpaque = true
        window.backgroundColor = .windowBackgroundColor
        window.level = .normal
        window.collectionBehavior = []
        window.isMovableByWindowBackground = true
        _ = window.setFrameAutosaveName("AICLIDashboardWindow")
    }

    func hideWindow() {
        dashboardWindow?.orderOut(nil)
        visibilityHandler?(false)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        visibilityHandler?(false)
        return false
    }

    func windowDidMiniaturize(_ notification: Notification) {
        visibilityHandler?(false)
    }

    func windowDidDeminiaturize(_ notification: Notification) {
        notifyCurrentVisibility()
    }

    func windowDidChangeOcclusionState(_ notification: Notification) {
        notifyCurrentVisibility()
    }

    private func notifyCurrentVisibility() {
        guard let window = dashboardWindow else {
            visibilityHandler?(false)
            return
        }
        visibilityHandler?(
            window.isVisible && window.occlusionState.contains(.visible) && !NSApp.isHidden
        )
    }

    private func setupMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "chart.bar.fill",
                accessibilityDescription: "AI CLI Dashboard"
            )
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "Show Dashboard",
            action: #selector(showWindow),
            keyEquivalent: "s"
        ))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        ))
        menu.items.forEach { $0.target = self }
        statusItem?.menu = menu
    }

    @objc private func showWindow() {
        guard let window = dashboardWindow else { return }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        notifyCurrentVisibility()
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
