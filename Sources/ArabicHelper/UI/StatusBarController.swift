import Cocoa
import SwiftUI

@MainActor
public final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    
    public init(appState: AppState) {
        super.init()
        setupStatusItem()
        setupPopover(appState: appState)
        
        // When translation completes, show the popover
        appState.onTranslationCompleted = { [weak self] in
            DispatchQueue.main.async {
                self?.showPopover()
            }
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Create a sharp template icon
            button.image = createStatusBarIcon()
            button.imagePosition = .imageOnly
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Arabic & English Screen Helper (Click to open, Right-click for menu)"
        }
    }
    
    private func setupPopover(appState: AppState) {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 440, height: 560)
        popover.behavior = .transient
        popover.animates = true
        
        let contentView = PopupView()
            .environmentObject(appState)
        
        popover.contentViewController = NSHostingController(rootView: contentView)
    }
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let currentEvent = NSApp.currentEvent
        if currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }
    
    public func togglePopover() {
        if popover.isShown {
            hidePopover()
        } else {
            showPopover()
        }
    }
    
    public func showPopover() {
        guard let button = statusItem.button else { return }
        
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        
        // Popover transient behavior handles outside clicks, but global monitor ensures dismissal
        startEventMonitor()
    }
    
    public func hidePopover() {
        popover.performClose(nil)
        stopEventMonitor()
    }
    
    private func startEventMonitor() {
        if eventMonitor == nil {
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                if self?.popover.isShown == true {
                    self?.hidePopover()
                }
            }
        }
    }
    
    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func showContextMenu() {
        let menu = NSMenu()
        
        let captureItem = NSMenuItem(
            title: "Capture Screen (\(AppState.shared.preferences.shortcut.displayString))",
            action: #selector(menuCaptureClicked),
            keyEquivalent: ""
        )
        captureItem.target = self
        menu.addItem(captureItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let openItem = NSMenuItem(title: "Open Translations", action: #selector(menuOpenClicked), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(menuSettingsClicked), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit ArabicHelper", action: #selector(menuQuitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil // Clear after presentation so left-click works
    }
    
    @objc private func menuCaptureClicked() {
        AppState.shared.triggerCapture()
    }
    
    @objc private func menuOpenClicked() {
        AppState.shared.activeTab = .translation
        showPopover()
    }
    
    @objc private func menuSettingsClicked() {
        AppState.shared.activeTab = .settings
        showPopover()
    }
    
    @objc private func menuQuitClicked() {
        NSApplication.shared.terminate(nil)
    }
    
    /// Generates a clean 18x18 status bar template icon showing an Arabic/English symbol
    private func createStatusBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            // Use SF Symbol if available, or custom draw "ع"
            if let sfImage = NSImage(systemSymbolName: "character.book.closed.fill", accessibilityDescription: nil) {
                sfImage.draw(in: rect)
                return true
            }
            
            // Fallback drawing
            let path = NSBezierPath(roundedRect: NSRect(x: 1, y: 1, width: 16, height: 16), xRadius: 4, yRadius: 4)
            NSColor.black.setStroke()
            path.lineWidth = 1.2
            path.stroke()
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 10),
                .foregroundColor: NSColor.black
            ]
            let str = "ع" as NSString
            let strSize = str.size(withAttributes: attrs)
            let strRect = NSRect(
                x: (18 - strSize.width) / 2,
                y: (18 - strSize.height) / 2,
                width: strSize.width,
                height: strSize.height
            )
            str.draw(in: strRect, withAttributes: attrs)
            return true
        }
        image.isTemplate = true
        return image
    }
}
