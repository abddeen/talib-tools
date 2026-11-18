import SwiftUI
import AppKit
import Carbon

public struct ShortcutRecorderView: View {
    @EnvironmentObject var appState: AppState
    @State private var isListening = false
    @State private var eventMonitor: Any?
    
    public var body: some View {
        HStack {
            Text("Screenshot Shortcut:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {
                if isListening {
                    stopListening()
                } else {
                    startListening()
                }
            }) {
                HStack(spacing: 6) {
                    if isListening {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("Press keys...")
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    } else {
                        Image(systemName: "keyboard")
                            .font(.caption)
                        Text(appState.preferences.shortcut.displayString)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isListening ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isListening ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            
            if appState.preferences.shortcut != .default {
                Button(action: {
                    appState.updateShortcut(.default)
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Reset to default (⌘⇧2)")
            }
        }
        .onDisappear {
            stopListening()
        }
    }
    
    private func startListening() {
        isListening = true
        appState.isRecordingShortcut = true
        
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            // Ignore bare modifier key presses
            let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
            if flags.isEmpty && event.keyCode == UInt16(kVK_Escape) {
                // Cancel on Escape
                self.stopListening()
                return nil
            }
            
            guard !flags.isEmpty else {
                return nil
            }
            
            let carbonMods = ShortcutModel.carbonModifiers(from: flags)
            let newShortcut = ShortcutModel(
                keyCode: UInt32(event.keyCode),
                carbonModifiers: carbonMods
            )
            
            DispatchQueue.main.async {
                self.appState.updateShortcut(newShortcut)
                self.stopListening()
            }
            return nil
        }
    }
    
    private func stopListening() {
        isListening = false
        appState.isRecordingShortcut = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
