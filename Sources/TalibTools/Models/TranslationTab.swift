import Foundation

public enum TranslationTab: String, CaseIterable, Identifiable {
    case translation = "Translation"
    case vocab = "Vocab"
    case lexicon = "Lexicon"
    
    public var id: String { rawValue }
}
