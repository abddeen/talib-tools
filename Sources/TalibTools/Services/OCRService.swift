import Foundation
import AppKit
import Vision
import NaturalLanguage

public struct OCRResult: Sendable {
    public let text: String
    public let languageCode: String
    public let languageName: String
}

public final class OCRService {
    public static let shared = OCRService()
    
    private init() {}
    
    public func recognizeText(from image: NSImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(
                domain: "TalibTools.OCR",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to obtain CGImage from NSImage"]
            )
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: OCRResult(text: "", languageCode: "unknown", languageName: "Unknown"))
                    return
                }
                
                // Sort observations top-to-bottom
                // Note: Vision bounding box origin is bottom-left, so higher Y means higher up.
                let sortedObservations = observations.sorted { obs1, obs2 in
                    let y1 = obs1.boundingBox.origin.y
                    let y2 = obs2.boundingBox.origin.y
                    // If on roughly the same line (within 2% height)
                    if abs(y1 - y2) < 0.02 {
                        return obs1.boundingBox.origin.x < obs2.boundingBox.origin.x
                    }
                    return y1 > y2
                }
                
                var recognizedLines: [String] = []
                for obs in sortedObservations {
                    if let candidate = obs.topCandidates(1).first {
                        let trimmed = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            recognizedLines.append(trimmed)
                        }
                    }
                }
                
                let fullText = recognizedLines.joined(separator: "\n")
                let (langCode, langName) = Self.detectLanguage(for: fullText)
                
                let result = OCRResult(
                    text: fullText,
                    languageCode: langCode,
                    languageName: langName
                )
                continuation.resume(returning: result)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.revision = VNRecognizeTextRequestRevision3
            request.recognitionLanguages = [
                "ar-SA", "ars-SA",
                "en-US", "en-GB",
                "fr-FR", "de-DE", "es-ES", "it-IT",
                "tr-TR", "ru-RU", "zh-Hans", "zh-Hant",
                "ja-JP", "ko-KR", "pt-BR", "nl-NL"
            ]
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    public static func detectLanguage(for text: String) -> (code: String, name: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ("en", "English")
        }
        
        // 1. Direct Arabic script detection heuristic
        var arabicCharCount = 0
        var latinCharCount = 0
        for scalar in trimmed.unicodeScalars {
            if (0x0600...0x06FF).contains(scalar.value) ||
               (0x0750...0x077F).contains(scalar.value) ||
               (0x08A0...0x08FF).contains(scalar.value) ||
               (0xFB50...0xFDFF).contains(scalar.value) ||
               (0xFE70...0xFEFF).contains(scalar.value) {
                arabicCharCount += 1
            } else if (0x0041...0x005A).contains(scalar.value) || (0x0061...0x007A).contains(scalar.value) {
                latinCharCount += 1
            }
        }
        
        if arabicCharCount > 0 && arabicCharCount >= latinCharCount / 2 {
            return ("ar", "Arabic")
        }
        
        // 2. NaturalLanguage recognizer
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(trimmed)
        if let dominant = recognizer.dominantLanguage?.rawValue {
            let localizedName = Locale.current.localizedString(forLanguageCode: dominant) ?? dominant.uppercased()
            return (dominant, localizedName)
        }
        
        // Default to English if undetermined
        return ("en", "English")
    }
}
