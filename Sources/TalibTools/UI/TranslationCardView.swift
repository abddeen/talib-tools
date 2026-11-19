import SwiftUI
import AppKit

public struct TranslationCardView: View {
    public let title: String
    public let badge: String
    public let text: String
    public let isArabic: Bool
    public let languageCode: String
    
    @ObservedObject private var speechService = SpeechService.shared
    @State private var hasCopied = false
    
    public init(
        title: String,
        badge: String,
        text: String,
        isArabic: Bool,
        languageCode: String
    ) {
        self.title = title
        self.badge = badge
        self.text = text
        self.isArabic = isArabic
        self.languageCode = languageCode
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                HStack(spacing: 5) {
                    Text(badge)
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                }
                
                Spacer()
                
                // Speak Button
                Button(action: {
                    if speechService.isSpeaking && speechService.currentlySpeakingLanguage == languageCode {
                        speechService.stop()
                    } else {
                        speechService.speak(text: text, languageCode: languageCode)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: (speechService.isSpeaking && speechService.currentlySpeakingLanguage == languageCode) ? "speaker.wave.3.fill" : "speaker.wave.2")
                            .font(.system(size: 11))
                            .foregroundColor((speechService.isSpeaking && speechService.currentlySpeakingLanguage == languageCode) ? .accentColor : .secondary)
                        Text("Listen")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Listen to pronunciation")
                
                // Copy Button
                Button(action: {
                    copyText()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: hasCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                            .foregroundColor(hasCopied ? .green : .secondary)
                        Text(hasCopied ? "Copied" : "Copy")
                            .font(.system(size: 11))
                            .foregroundColor(hasCopied ? .green : .secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Copy to clipboard")
            }
            
            // Content
            Text(text.isEmpty ? "—" : text)
                .font(isArabic ? .system(size: 15, weight: .regular, design: .serif) : .system(size: 14))
                .lineSpacing(isArabic ? 6 : 4)
                .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
                .multilineTextAlignment(isArabic ? .trailing : .leading)
                .environment(\.layoutDirection, isArabic ? .rightToLeft : .leftToRight)
                .textSelection(.enabled)
                .foregroundColor(.primary)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.textBackgroundColor).opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func copyText() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        withAnimation {
            hasCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation {
                hasCopied = false
            }
        }
    }
}
