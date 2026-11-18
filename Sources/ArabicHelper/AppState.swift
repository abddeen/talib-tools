import Foundation
import AppKit
import SwiftUI
import Combine

public enum AppTab: String, CaseIterable, Identifiable {
    case translation = "Translate"
    case history = "History"
    case settings = "Settings"
    
    public var id: String { rawValue }
}

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var currentResult: TranslationResult?
    @Published public var isCapturing: Bool = false
    @Published public var isProcessing: Bool = false
    @Published public var statusMessage: String = "Ready"
    @Published public var errorMessage: String?
    @Published public var history: [TranslationResult] = []
    @Published public var preferences: UserPreferences
    @Published public var activeTab: AppTab = .translation
    @Published public var isRecordingShortcut: Bool = false
    
    public var onTranslationCompleted: (() -> Void)?
    
    private init() {
        let loadedPrefs = UserPreferences.load()
        self.preferences = loadedPrefs
        
        // Setup HotKey
        HotKeyManager.shared.onHotKeyPressed = { [weak self] in
            Task { @MainActor in
                self?.triggerCapture()
            }
        }
        HotKeyManager.shared.register(shortcut: loadedPrefs.shortcut)
    }
    
    public func triggerCapture() {
        guard !isCapturing && !isProcessing else { return }
        
        isCapturing = true
        errorMessage = nil
        statusMessage = "Select area on screen..."
        
        Task {
            // Give time for any active popover to dismiss if needed
            let capturedImage = await ScreenCaptureService.shared.captureInteractiveSelection()
            self.isCapturing = false
            
            guard let image = capturedImage else {
                self.statusMessage = "Capture cancelled"
                return
            }
            
            await self.processImage(image)
        }
    }
    
    public func processImage(_ image: NSImage) async {
        self.isProcessing = true
        self.errorMessage = nil
        self.statusMessage = "Extracting text..."
        self.activeTab = .translation
        
        do {
            // 1. OCR Text Recognition & Language Detection
            let ocr = try await OCRService.shared.recognizeText(from: image)
            
            if ocr.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.statusMessage = "No text recognized in screenshot"
                self.errorMessage = "Could not find any readable text in the selected area."
                self.isProcessing = false
                self.onTranslationCompleted?()
                return
            }
            
            // 2. Dual Translation (Arabic & English)
            self.statusMessage = "Translating text..."
            let translation = try await TranslationService.shared.translateToBoth(
                text: ocr.text,
                hintedLanguageCode: ocr.languageCode
            )
            
            let result = TranslationResult(
                image: image,
                originalText: translation.originalText,
                detectedLanguageCode: translation.detectedLanguageCode,
                detectedLanguageName: translation.detectedLanguageName,
                arabicTranslation: translation.arabicText,
                englishTranslation: translation.englishText
            )
            
            self.currentResult = result
            self.history.insert(result, at: 0)
            if self.history.count > 30 {
                self.history.removeLast()
            }
            
            // Handle auto-copy preference
            switch self.preferences.autoCopyOption {
            case .arabic:
                self.copyToPasteboard(result.arabicTranslation)
            case .english:
                self.copyToPasteboard(result.englishTranslation)
            case .none:
                break
            }
            
            self.statusMessage = "Translation complete!"
            self.isProcessing = false
            
            // Notify UI to open popup
            if self.preferences.autoOpenPopup {
                self.onTranslationCompleted?()
            }
            
        } catch {
            print("Processing error: \(error)")
            self.errorMessage = error.localizedDescription
            self.statusMessage = "Translation failed"
            self.isProcessing = false
            self.onTranslationCompleted?()
        }
    }
    
    public func copyToPasteboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    public func updateShortcut(_ newShortcut: ShortcutModel) {
        preferences.shortcut = newShortcut
        preferences.save()
        HotKeyManager.shared.register(shortcut: newShortcut)
    }
    
    public func updatePreferences(_ update: (inout UserPreferences) -> Void) {
        update(&preferences)
        preferences.save()
    }
    
    public func clearHistory() {
        history.removeAll()
    }
}
