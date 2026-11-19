import Cocoa

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Runs as menu bar accessory app
        NSApp.setActivationPolicy(.accessory)
        
        statusBarController = StatusBarController(appState: AppState.shared)
        
        print("TalibTools started. Listening for shortcut: \(AppState.shared.preferences.shortcut.displayString)")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        HotKeyManager.shared.unregisterHotKey()
    }
}

@main
struct TalibToolsMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
