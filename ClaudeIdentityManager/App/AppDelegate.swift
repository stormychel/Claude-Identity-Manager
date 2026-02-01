import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var viewModel: IdentityManagerViewModel?

    func setViewModel(_ viewModel: IdentityManagerViewModel) {
        self.viewModel = viewModel
        setupMenuBar()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar setup is deferred until viewModel is set
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep running with menu bar
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        guard let viewModel = viewModel else { return }

        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "person.2.circle", accessibilityDescription: "Claude Identity Manager")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Create popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 260, height: 350)
        popover?.behavior = .transient
        popover?.animates = true

        // Set popover content
        let menuBarView = MenuBarView(
            viewModel: viewModel,
            onOpenMainWindow: { [weak self] in
                self?.openMainWindow()
            }
        )
        popover?.contentViewController = NSHostingController(rootView: menuBarView)
    }

    @objc private func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            // Refresh identities when opening
            Task { @MainActor in
                await viewModel?.loadIdentities()
            }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func openMainWindow() {
        popover?.performClose(nil)

        // Activate the app and bring main window to front
        NSApplication.shared.activate(ignoringOtherApps: true)

        // Find and show the main window
        if let window = NSApplication.shared.windows.first(where: { $0.title.isEmpty || $0.title == "Claude Identity Manager" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            // Open a new window if none exists
            NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
        }
    }
}
