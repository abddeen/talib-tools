import Foundation

// MARK: - Response Models

/// Top-level response from the Arabic Students Dictionary search API.
public struct DictionarySearchResponse: Codable, Sendable, Equatable {
    public let words: [DictionaryWord]
    public let searched: String

    public init(words: [DictionaryWord], searched: String) {
        self.words = words
        self.searched = searched
    }

    private enum CodingKeys: String, CodingKey {
        case words, searched
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        words = try container.decodeIfPresent([DictionaryWord].self, forKey: .words) ?? []
        searched = try container.decodeIfPresent(String.self, forKey: .searched) ?? ""
    }

    /// Entries ordered with exact (diacritic-insensitive) matches first, then shorter headwords.
    public var sortedWords: [DictionaryWord] {
        let normalizedQuery = Self.normalizedArabic(searched)
        return words.sorted { lhs, rhs in
            let lhsExact = Self.normalizedArabic(lhs.text) == normalizedQuery
            let rhsExact = Self.normalizedArabic(rhs.text) == normalizedQuery
            if lhsExact != rhsExact { return lhsExact }
            return lhs.text.count < rhs.text.count
        }
    }

    /// Removes Arabic diacritics, tatweel and whitespace so "كِتَاب" and "كتاب" compare equal.
    public static func normalizedArabic(_ text: String) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            let v = scalar.value
            let isDiacritic = (0x064B...0x065F).contains(v) ||
                              v == 0x0670 ||
                              (0x06D6...0x06ED).contains(v) ||
                              (0x08D3...0x08FF).contains(v)
            let isTatweel = v == 0x0640
            if isDiacritic || isTatweel { continue }
            scalars.append(scalar)
        }
        return String(scalars)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// A single dictionary entry (one verb form or noun pattern of a root).
public struct DictionaryWord: Codable, Identifiable, Sendable, Equatable {
    public let id: String
    public let text: String
    public let form: String
    public let transliteration: String
    public let plural: DictionaryPlural
    public let root: DictionaryRoot
    public let translation: DictionaryTranslation
    public let hasWordMatch: Bool

    public init(
        id: String = UUID().uuidString,
        text: String,
        form: String = "",
        transliteration: String = "",
        plural: DictionaryPlural = DictionaryPlural(),
        root: DictionaryRoot = DictionaryRoot(),
        translation: DictionaryTranslation = DictionaryTranslation(),
        hasWordMatch: Bool = false
    ) {
        self.id = id
        self.text = text
        self.form = form
        self.transliteration = transliteration
        self.plural = plural
        self.root = root
        self.translation = translation
        self.hasWordMatch = hasWordMatch
    }

    private enum CodingKeys: String, CodingKey {
        case id, text, form, transliteration, plural, root, translation
        case hasWordMatch = "has_word_match"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        form = try container.decodeIfPresent(String.self, forKey: .form) ?? ""
        transliteration = try container.decodeIfPresent(String.self, forKey: .transliteration) ?? ""
        plural = try container.decodeIfPresent(DictionaryPlural.self, forKey: .plural) ?? DictionaryPlural()
        root = try container.decodeIfPresent(DictionaryRoot.self, forKey: .root) ?? DictionaryRoot()
        translation = try container.decodeIfPresent(DictionaryTranslation.self, forKey: .translation) ?? DictionaryTranslation()
        hasWordMatch = try container.decodeIfPresent(Bool.self, forKey: .hasWordMatch) ?? false
    }

    /// Full definition with the API's HTML italics markup removed for display.
    public var plainFullDefinition: String {
        Self.removeHTMLTags(translation.text)
    }

    /// Short gloss with HTML markup removed for display.
    public var plainShortDefinition: String {
        Self.removeHTMLTags(translation.short)
    }

    private static func removeHTMLTags(_ string: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "<[^>]+>") else {
            return string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let range = NSRange(string.startIndex..., in: string)
        let cleaned = regex.stringByReplacingMatches(in: string, range: range, withTemplate: "")
        return cleaned
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Plural information for a dictionary entry.
public struct DictionaryPlural: Codable, Sendable, Equatable {
    public let text: String
    public let transliteration: String

    public init(text: String = "", transliteration: String = "") {
        self.text = text
        self.transliteration = transliteration
    }

    private enum CodingKeys: String, CodingKey {
        case text, transliteration
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        transliteration = try container.decodeIfPresent(String.self, forKey: .transliteration) ?? ""
    }
}

/// Root information shared by several entries of the same verb root.
public struct DictionaryRoot: Codable, Sendable, Equatable {
    public let id: String
    public let text: String
    public let wordCount: Int
    public let formCount: Int

    public init(id: String = "", text: String = "", wordCount: Int = 0, formCount: Int = 0) {
        self.id = id
        self.text = text
        self.wordCount = wordCount
        self.formCount = formCount
    }

    private enum CodingKeys: String, CodingKey {
        case id, text
        case wordCount = "word_count"
        case formCount = "form_count"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        wordCount = try container.decodeIfPresent(Int.self, forKey: .wordCount) ?? 0
        formCount = try container.decodeIfPresent(Int.self, forKey: .formCount) ?? 0
    }
}

/// Definition fields for a dictionary entry.
public struct DictionaryTranslation: Codable, Sendable, Equatable {
    public let id: String
    public let text: String
    public let short: String
    public let google: String
    public let amazon: String

    public init(id: String = "", text: String = "", short: String = "", google: String = "", amazon: String = "") {
        self.id = id
        self.text = text
        self.short = short
        self.google = google
        self.amazon = amazon
    }

    private enum CodingKeys: String, CodingKey {
        case id, text, short, google, amazon
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        short = try container.decodeIfPresent(String.self, forKey: .short) ?? ""
        google = try container.decodeIfPresent(String.self, forKey: .google) ?? ""
        amazon = try container.decodeIfPresent(String.self, forKey: .amazon) ?? ""
    }
}
