import SwiftUI
import AppKit

public struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Section: Shortcut
                GroupBox(label: Label("Shortcut Configuration", systemImage: "keyboard")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Set a global shortcut to capture any section of your screen for immediate OCR and translation.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ShortcutRecorderView()
                            .environmentObject(appState)
                    }
                    .padding(8)
                }
                
                // Section: Automation & Preferences
                GroupBox(label: Label("Behavior", systemImage: "gearshape")) {
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle("Automatically open popup when translation finishes", isOn: Binding(
                            get: { appState.preferences.autoOpenPopup },
                            set: { newValue in
                                appState.updatePreferences { $0.autoOpenPopup = newValue }
                            }
                        ))
                        .toggleStyle(.checkbox)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Automatic Clipboard Copy:")
                                .font(.subheadline)
                            Picker("", selection: Binding(
                                get: { appState.preferences.autoCopyOption },
                                set: { newValue in
                                    appState.updatePreferences { $0.autoCopyOption = newValue }
                                }
                            )) {
                                ForEach(AutoCopyOption.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding(8)
                }
                
                // Section: How it works
                GroupBox(label: Label("How it works", systemImage: "info.circle")) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("1.")
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                            Text("Press your shortcut (\(appState.preferences.shortcut.displayString)) anywhere in macOS.")
                                .font(.caption)
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("2.")
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                            Text("Drag crosshairs across any text on your screen (Arabic, English, French, etc.).")
                                .font(.caption)
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("3.")
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                            Text("macOS Vision OCR automatically extracts text and detects the source language.")
                                .font(.caption)
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("4.")
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                            Text("The menu bar popover displays both Arabic and English translations with one-click audio and copy.")
                                .font(.caption)
                        }
                    }
                    .padding(8)
                }
                
                // Section: App info
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("ArabicHelper v1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Native macOS Menu Bar App")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
    }
}
