import SwiftUI
import AppKit

public struct PopupView: View {
    @EnvironmentObject var appState: AppState
    @State private var enteredText: String = ""
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top App Bar
            headerBar
            
            Divider()
            
            // Body Content based on active tab
            Group {
                switch appState.activeTab {
                case .translation:
                    translationContentView
                case .history:
                    HistoryView()
                        .environmentObject(appState)
                case .settings:
                    SettingsView()
                        .environmentObject(appState)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // Bottom Status & Quick Action Bar
            bottomBar
        }
        .frame(width: 440, height: 580)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 12) {
            // App Branding
            HStack(spacing: 7) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 26, height: 26)
                    Text("ع/A")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("ArabicHelper")
                    .font(.system(size: 13, weight: .bold))
            }
            
            Spacer()
            
            // Tab Picker
            Picker("", selection: $appState.activeTab) {
                ForEach(AppTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 210)
            
            // Quit Button
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Quit ArabicHelper")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
    
    // MARK: - Translation View
    private var translationContentView: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Direct Text Input Card (Always accessible)
                textInputCard
                
                if appState.isProcessing || appState.isCapturing {
                    processingView
                } else if let error = appState.errorMessage {
                    errorCardView(message: error)
                }
                
                if let result = appState.currentResult {
                    // Original Source Card
                    originalSourceCard(result: result)
                    
                    // Arabic Translation Card
                    TranslationCardView(
                        title: "العربية (Arabic)",
                        badge: "🇦🇪",
                        text: result.arabicTranslation,
                        isArabic: true,
                        languageCode: "ar"
                    )
                    
                    // English Translation Card
                    TranslationCardView(
                        title: "English",
                        badge: "🇬🇧",
                        text: result.englishTranslation,
                        isArabic: false,
                        languageCode: "en"
                    )
                } else if !appState.isProcessing && !appState.isCapturing && appState.errorMessage == nil {
                    emptyWelcomeState
                }
            }
            .padding(14)
        }
    }
    
    // MARK: - Direct Text Input Card
    private var textInputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)
                    Text("Enter Text or Screenshot")
                        .font(.system(size: 12, weight: .bold))
                }
                
                Spacer()
                
                if !enteredText.isEmpty {
                    Button(action: {
                        enteredText = ""
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                            Text("Clear")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Button(action: {
                    if let clipboard = NSPasteboard.general.string(forType: .string) {
                        enteredText = clipboard
                    }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 10))
                        Text("Paste")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Paste from clipboard")
            }
            
            ZStack(alignment: .topLeading) {
                if enteredText.isEmpty {
                    Text("Type or paste text here to translate...")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $enteredText)
                    .font(.system(size: 13))
                    .frame(minHeight: 48, maxHeight: 80)
                    .scrollContentBackground(.hidden)
                    .padding(4)
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.textBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            
            HStack {
                Button(action: {
                    appState.triggerCapture()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "camera")
                            .font(.system(size: 11))
                        Text("Screenshot (\(appState.preferences.shortcut.displayString))")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .help("Capture a section of your screen")
                
                Spacer()
                
                Button(action: {
                    submitEnteredText()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption)
                        Text("Translate")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(enteredText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.25) : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .disabled(enteredText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || appState.isProcessing)
                .keyboardShortcut(.return, modifiers: [.command])
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.18), lineWidth: 1)
        )
    }
    
    private func submitEnteredText() {
        let text = enteredText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        Task {
            await appState.translateDirectText(text)
        }
    }
    
    // MARK: - Processing View
    private var processingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            Text(appState.statusMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.1))
        )
    }
    
    // MARK: - Error Card
    private func errorCardView(message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Notice")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    // MARK: - Original Source Card
    private func originalSourceCard(result: TranslationResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: result.image != nil ? "camera.viewfinder" : "keyboard")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(result.image != nil ? "Screenshot Source" : "Entered Text")
                        .font(.system(size: 12, weight: .bold))
                }
                
                Spacer()
                
                // Detected Language Badge
                Text("Detected: \(result.detectedLanguageName)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .cornerRadius(4)
                
                // Copy button for original
                Button(action: {
                    appState.copyToPasteboard(result.originalText)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Copy original text")
            }
            
            HStack(alignment: .top, spacing: 10) {
                // Screenshot Thumbnail (if present)
                if let image = result.image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 80, maxHeight: 60)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.accentColor.opacity(0.1))
                            .frame(width: 32, height: 32)
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 14))
                            .foregroundColor(.accentColor)
                    }
                }
                
                Text(result.originalText)
                    .font(.system(size: 13))
                    .lineLimit(4)
                    .textSelection(.enabled)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.textBackgroundColor).opacity(0.5))
            )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Empty Welcome State
    private var emptyWelcomeState: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 20)
            
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 64, height: 64)
                Image(systemName: "translate")
                    .font(.system(size: 30))
                    .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 4) {
                Text("Ready to Translate")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Type text in the box above, or press \(appState.preferences.shortcut.displayString) to screenshot any screen section.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Spacer(minLength: 20)
        }
    }
    
    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack {
            Text(appState.statusMessage)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {
                appState.triggerCapture()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "camera.fill")
                        .font(.caption)
                    Text("Capture")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(appState.preferences.shortcut.displayString)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(3)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.12))
                .foregroundColor(.accentColor)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .disabled(appState.isCapturing || appState.isProcessing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
    }
}
