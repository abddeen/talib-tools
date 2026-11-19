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
    
    // MARK: - Arabic Word Extraction Helpers
    
    /// Checks whether a scalar belongs to Arabic Unicode blocks.
    public static func isArabicScalar(_ scalar: UnicodeScalar) -> Bool {
        return (0x0600...0x06FF).contains(scalar.value) ||
               (0x0750...0x077F).contains(scalar.value) ||
               (0x0870...0x089F).contains(scalar.value) ||
               (0x08A0...0x08FF).contains(scalar.value) ||
               (0xFB50...0xFDFF).contains(scalar.value) ||
               (0xFE70...0xFEFF).contains(scalar.value)
    }
    
    /// Checks whether a scalar is an Arabic or decimal digit.
    public static func isDigitScalar(_ scalar: UnicodeScalar) -> Bool {
        return (0x0660...0x0669).contains(scalar.value) ||
               (0x06F0...0x06F9).contains(scalar.value) ||
               (0x0030...0x0039).contains(scalar.value)
    }
    
    /// Extracts a single Arabic word from the text if present.
    /// Returns nil if the text is empty, contains multiple words, or is not in Arabic script.
    public static func extractSingleArabicWord(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        // Split by whitespace / newlines
        let tokens = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard tokens.count == 1 else { return nil }
        
        let punctuationAndSymbols = CharacterSet.punctuationCharacters
            .union(.symbols)
            .union(CharacterSet(charactersIn: "؟،؛«»\"'“”‘’—–-()[]{}<>.,:!/?\\"))
        
        let cleaned = tokens[0].trimmingCharacters(in: punctuationAndSymbols)
        guard !cleaned.isEmpty else { return nil }
        
        var hasArabicLetter = false
        for scalar in cleaned.unicodeScalars {
            if isDigitScalar(scalar) {
                return nil
            }
            if isArabicScalar(scalar) {
                // Check if it's an Arabic letter (not purely diacritic/tatweel)
                if (0x0620...0x064A).contains(scalar.value) ||
                   (0x066E...0x066F).contains(scalar.value) ||
                   (0x0671...0x06D3).contains(scalar.value) ||
                   (0x0750...0x077F).contains(scalar.value) ||
                   (0x08A0...0x08FF).contains(scalar.value) ||
                   (0xFB50...0xFDFF).contains(scalar.value) ||
                   (0xFE70...0xFEFF).contains(scalar.value) {
                    hasArabicLetter = true
                }
            } else if CharacterSet.punctuationCharacters.contains(scalar) {
                // Allow inner punctuation like hyphen
                continue
            } else {
                return nil
            }
        }
        
        return hasArabicLetter ? cleaned : nil
    }
    
    /// Returns the single Arabic word if either the original text or translated Arabic text is a single Arabic word.
    public var singleArabicWord: String? {
        if let word = Self.extractSingleArabicWord(from: originalText) {
            return word
        }
        if let word = Self.extractSingleArabicWord(from: arabicTranslation) {
            return word
        }
        return nil
    }
}
