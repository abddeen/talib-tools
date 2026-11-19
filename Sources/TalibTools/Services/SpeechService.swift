import Foundation
import AVFoundation

@MainActor
public final class SpeechService: NSObject, ObservableObject, @preconcurrency AVSpeechSynthesizerDelegate {
    public static let shared = SpeechService()
    
    private let synthesizer = AVSpeechSynthesizer()
    @Published public var isSpeaking: Bool = false
    @Published public var currentlySpeakingLanguage: String? = nil
    
    override private init() {
        super.init()
        synthesizer.delegate = self
    }
    
    public func speak(text: String, languageCode: String) {
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
            currentlySpeakingLanguage = nil
        }
        
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        
        let voiceLocale: String
        if languageCode.lowercased().hasPrefix("ar") {
            voiceLocale = "ar-SA"
        } else if languageCode.lowercased().hasPrefix("en") {
            voiceLocale = "en-US"
        } else {
            voiceLocale = languageCode
        }
        
        if let voice = AVSpeechSynthesisVoice(language: voiceLocale) {
            utterance.voice = voice
        } else if let fallbackVoice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = fallbackVoice
        }
        
        isSpeaking = true
        currentlySpeakingLanguage = languageCode
        synthesizer.speak(utterance)
    }
    
    public func stop() {
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
            currentlySpeakingLanguage = nil
        }
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.currentlySpeakingLanguage = nil
        }
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.currentlySpeakingLanguage = nil
        }
    }
}
