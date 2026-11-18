import Foundation
import AppKit

public struct TranslationResult: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let image: NSImage?
    public let originalText: String
    public let detectedLanguageCode: String
    public let detectedLanguageName: String
    public let arabicTranslation: String
    public let englishTranslation: String
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        image: NSImage? = nil,
        originalText: String,
        detectedLanguageCode: String,
        detectedLanguageName: String,
        arabicTranslation: String,
        englishTranslation: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.image = image
        self.originalText = originalText
        self.detectedLanguageCode = detectedLanguageCode
        self.detectedLanguageName = detectedLanguageName
        self.arabicTranslation = arabicTranslation
        self.englishTranslation = englishTranslation
    }
    
    public var isOriginalArabic: Bool {
        detectedLanguageCode.lowercased().hasPrefix("ar")
    }
    
    public var isOriginalEnglish: Bool {
        detectedLanguageCode.lowercased().hasPrefix("en")
    }
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: timestamp)
    }
}
