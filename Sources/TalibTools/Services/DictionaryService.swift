import Foundation

public enum DictionaryServiceError: LocalizedError {
    case emptyQuery
    case invalidURL
    case badStatusCode(Int)

    public var errorDescription: String? {
        switch self {
        case .emptyQuery:
            return "Enter an Arabic word to look up."
        case .invalidURL:
            return "Could not build the dictionary search URL."
        case .badStatusCode(let code):
            return "Dictionary request failed with HTTP \(code)."
        }
    }
}

/// Client for the Lexicon search API (Arabic Students Dictionary).
public final class DictionaryService {
    public static let shared = DictionaryService()

    private let urlSession: URLSession
    private let decoder = JSONDecoder()

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        config.timeoutIntervalForResource = 30.0
        self.urlSession = URLSession(configuration: config)
    }

    /// Searches the dictionary for `word`, returning all matching entries.
    public func search(word: String, language: String = "en") async throws -> DictionarySearchResponse {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw DictionaryServiceError.emptyQuery }

        guard let encodedQuery = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.arabicstudentsdictionary.com/search?query=\(encodedQuery)&language=\(language)") else {
            throw DictionaryServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw DictionaryServiceError.badStatusCode(code)
        }

        return try decoder.decode(DictionarySearchResponse.self, from: data)
    }
}
