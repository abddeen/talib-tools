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
        
        let quitItem = NSMenuItem(title: "Quit TalibTools", action: #selector(menuQuitClicked), keyEquivalent: "q")
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
    
    /// Generates a clean 18x18 status bar template icon showing a mosque silhouette
    private func createStatusBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.black.setFill()
            
            // Main building
            NSBezierPath(rect: NSRect(x: 3, y: 2.5, width: 12, height: 4.5)).fill()
            
            // Dome
            let dome = NSBezierPath()
            dome.move(to: NSPoint(x: 5, y: 7))
            dome.appendArc(withCenter: NSPoint(x: 9, y: 7), radius: 4, startAngle: 0, endAngle: 180, clockwise: false)
            dome.close()
            dome.fill()
            
            // Finial on top of the dome
            NSBezierPath(rect: NSRect(x: 8.5, y: 11, width: 1, height: 2)).fill()
            
            // Minarets
            NSBezierPath(rect: NSRect(x: 2, y: 2.5, width: 2.2, height: 8)).fill()
            NSBezierPath(rect: NSRect(x: 13.8, y: 2.5, width: 2.2, height: 8)).fill()
            
            // Pointed minaret caps
            let leftCap = NSBezierPath()
            leftCap.move(to: NSPoint(x: 1.7, y: 10.5))
            leftCap.line(to: NSPoint(x: 3.1, y: 13.5))
            leftCap.line(to: NSPoint(x: 4.5, y: 10.5))
            leftCap.close()
            leftCap.fill()
            
            let rightCap = NSBezierPath()
            rightCap.move(to: NSPoint(x: 13.5, y: 10.5))
            rightCap.line(to: NSPoint(x: 14.9, y: 13.5))
            rightCap.line(to: NSPoint(x: 16.3, y: 10.5))
            rightCap.close()
            rightCap.fill()
            
            return true
        }
        image.isTemplate = true
        return image
    }
}
