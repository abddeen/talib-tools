import Testing
@testable import ArabicHelper

@Suite("Translation Tabs and Hans Wehr Feature Tests")
struct TranslationTabsTests {
    
    @Test("TranslationTab cases and identifiers")
    func testTranslationTabs() {
        #expect(TranslationTab.allCases.count == 3)
        #expect(TranslationTab.translation.rawValue == "Translation")
        #expect(TranslationTab.vocab.rawValue == "Vocab")
        #expect(TranslationTab.hansWehr.rawValue == "Hans Wehr")
    }
    
    @Test("Single Arabic word extraction with various inputs")
    func testSingleArabicWordExtraction() {
        // Standard Arabic word
        #expect(TranslationResult.extractSingleArabicWord(from: "كتاب") == "كتاب")
        #expect(TranslationResult.extractSingleArabicWord(from: "  كتاب  ") == "كتاب")
        
        // Punctuation and quotes stripped
        #expect(TranslationResult.extractSingleArabicWord(from: "كتاب!") == "كتاب")
        #expect(TranslationResult.extractSingleArabicWord(from: "«كتاب»") == "كتاب")
        #expect(TranslationResult.extractSingleArabicWord(from: "كتاب،") == "كتاب")
        #expect(TranslationResult.extractSingleArabicWord(from: "كتاب؟") == "كتاب")
        #expect(TranslationResult.extractSingleArabicWord(from: "\"كتاب\"") == "كتاب")
        
        // Arabic with harakat (diacritics)
        #expect(TranslationResult.extractSingleArabicWord(from: "كِتَابٌ") == "كِتَابٌ")
        #expect(TranslationResult.extractSingleArabicWord(from: "مَرْحَبًا") == "مَرْحَبًا")
        
        // Arabic with tatweel
        #expect(TranslationResult.extractSingleArabicWord(from: "كـتـاب") == "كـتـاب")
        
        // Multi-word strings should return nil
        #expect(TranslationResult.extractSingleArabicWord(from: "كتاب جديد") == nil)
        #expect(TranslationResult.extractSingleArabicWord(from: "صباح الخير") == nil)
        
        // Non-Arabic strings should return nil
        #expect(TranslationResult.extractSingleArabicWord(from: "book") == nil)
        #expect(TranslationResult.extractSingleArabicWord(from: "hello world") == nil)
        #expect(TranslationResult.extractSingleArabicWord(from: "") == nil)
        #expect(TranslationResult.extractSingleArabicWord(from: "   ") == nil)
        #expect(TranslationResult.extractSingleArabicWord(from: "123") == nil)
        #expect(TranslationResult.extractSingleArabicWord(from: "١٢٣") == nil)
        #expect(TranslationResult.extractSingleArabicWord(from: "كتاب123") == nil)
    }
    
    @Test("TranslationResult singleArabicWord identification")
    func testTranslationResultSingleArabicWord() {
        // Original text is Arabic single word
        let arabicOriginal = TranslationResult(
            originalText: "سلام",
            detectedLanguageCode: "ar",
            detectedLanguageName: "Arabic",
            arabicTranslation: "سلام",
            englishTranslation: "peace"
        )
        #expect(arabicOriginal.singleArabicWord == "سلام")
        
        // Translated text is Arabic single word (original was English)
        let englishOriginal = TranslationResult(
            originalText: "peace",
            detectedLanguageCode: "en",
            detectedLanguageName: "English",
            arabicTranslation: "سلام",
            englishTranslation: "peace"
        )
        #expect(englishOriginal.singleArabicWord == "سلام")
        
        // Neither is a single Arabic word (multi-word phrase)
        let multiWord = TranslationResult(
            originalText: "Good morning",
            detectedLanguageCode: "en",
            detectedLanguageName: "English",
            arabicTranslation: "صباح الخير",
            englishTranslation: "Good morning"
        )
        #expect(multiWord.singleArabicWord == nil)
    }
}
