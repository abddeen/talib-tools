import Foundation

public struct DualTranslation: Sendable {
    public let originalText: String
    public let detectedLanguageCode: String
    public let detectedLanguageName: String
    public let arabicText: String
    public let englishText: String
}

public final class TranslationService {
    public static let shared = TranslationService()
    
    private let urlSession: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        config.timeoutIntervalForResource = 30.0
        self.urlSession = URLSession(configuration: config)
    }
    
    /// Translates extracted text into both Arabic and English, automatically detecting source language.
    public func translateToBoth(
        text: String,
        hintedLanguageCode: String? = nil
    ) async throws -> DualTranslation {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return DualTranslation(
                originalText: "",
                detectedLanguageCode: "en",
                detectedLanguageName: "English",
                arabicText: "",
                englishText: ""
            )
        }
        
        let initialLangCode = hintedLanguageCode ?? OCRService.detectLanguage(for: trimmed).code
        let isArabic = initialLangCode.lowercased().hasPrefix("ar")
        let isEnglish = initialLangCode.lowercased().hasPrefix("en")
        
        if isArabic {
            // Source is Arabic: keep original for Arabic, translate to English
            async let englishAsync = translate(text: trimmed, targetLanguage: "en", sourceLanguage: "ar")
            let (english, detectedCode) = try await englishAsync
            let finalCode = detectedCode.isEmpty ? "ar" : detectedCode
            let finalName = Locale.current.localizedString(forLanguageCode: finalCode) ?? "Arabic"
            
            return DualTranslation(
                originalText: trimmed,
                detectedLanguageCode: finalCode,
                detectedLanguageName: finalName,
                arabicText: trimmed,
                englishText: english
            )
        } else if isEnglish {
            // Source is English: keep original for English, translate to Arabic
            async let arabicAsync = translate(text: trimmed, targetLanguage: "ar", sourceLanguage: "en")
            let (arabic, detectedCode) = try await arabicAsync
            let finalCode = detectedCode.isEmpty ? "en" : detectedCode
            let finalName = Locale.current.localizedString(forLanguageCode: finalCode) ?? "English"
            
            return DualTranslation(
                originalText: trimmed,
                detectedLanguageCode: finalCode,
                detectedLanguageName: finalName,
                arabicText: arabic,
                englishText: trimmed
            )
        } else {
            // Source is a third language (e.g. French, German, Spanish, etc.)
            // Concurrently translate to both Arabic and English
            async let arabicAsync = translate(text: trimmed, targetLanguage: "ar", sourceLanguage: "auto")
            async let englishAsync = translate(text: trimmed, targetLanguage: "en", sourceLanguage: "auto")
            
            let (arabicResult, englishResult) = try await (arabicAsync, englishAsync)
            let detectedCode = !arabicResult.detectedSource.isEmpty ? arabicResult.detectedSource :
                              (!englishResult.detectedSource.isEmpty ? englishResult.detectedSource : initialLangCode)
            let finalName = Locale.current.localizedString(forLanguageCode: detectedCode) ?? detectedCode.uppercased()
            
            return DualTranslation(
                originalText: trimmed,
                detectedLanguageCode: detectedCode,
                detectedLanguageName: finalName,
                arabicText: arabicResult.text,
                englishText: englishResult.text
            )
        }
    }
    
    /// Translates text using Google Translate GTX API
    /// Returns (translatedText, detectedSourceLanguageCode)
    public func translate(
        text: String,
        targetLanguage: String,
        sourceLanguage: String = "auto"
    ) async throws -> (text: String, detectedSource: String) {
        guard let encodedQuery = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw URLError(.badURL)
        }
        
        let urlString = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=\(sourceLanguage)&tl=\(targetLanguage)&dt=t&q=\(encodedQuery)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NSError(
                domain: "ArabicHelper.Translation",
                code: code,
                userInfo: [NSLocalizedDescriptionKey: "Translation request failed with HTTP \(code)"]
            )
        }
        
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let rootArray = json as? [Any] else {
            throw NSError(
                domain: "ArabicHelper.Translation",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response structure"]
            )
        }
        
        // Parse translated sentences in rootArray[0]
        var translatedParts: [String] = []
        if let sentencesArray = rootArray.first as? [[Any]] {
            for sentence in sentencesArray {
                if let part = sentence.first as? String {
                    translatedParts.append(part)
                }
            }
        }
        
        // Detected source language is typically at rootArray[2]
        var detectedSource = ""
        if rootArray.count > 2, let detected = rootArray[2] as? String {
            detectedSource = detected
        }
        
        let translatedText = translatedParts.joined()
        return (translatedText.isEmpty ? text : translatedText, detectedSource)
    }
}
