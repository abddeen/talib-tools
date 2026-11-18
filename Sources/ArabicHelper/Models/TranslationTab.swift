import Foundation

public enum TranslationTab: String, CaseIterable, Identifiable {
    case translation = "Translation"
    case vocab = "Vocab"
    case hansWehr = "Hans Wehr"
    
    public var id: String { rawValue }
}
