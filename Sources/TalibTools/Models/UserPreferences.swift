import Foundation

public enum AutoCopyOption: String, CaseIterable, Codable, Sendable {
    case none = "None"
    case arabic = "Arabic Translation"
    case english = "English Translation"
}

public struct UserPreferences: Codable, Sendable {
    public var shortcut: ShortcutModel
    public var autoOpenPopup: Bool
    public var autoCopyOption: AutoCopyOption
    public var playSoundOnCapture: Bool
    
    public init(
        shortcut: ShortcutModel = .default,
        autoOpenPopup: Bool = true,
        autoCopyOption: AutoCopyOption = .none,
        playSoundOnCapture: Bool = true
    ) {
        self.shortcut = shortcut
        self.autoOpenPopup = autoOpenPopup
        self.autoCopyOption = autoCopyOption
        self.playSoundOnCapture = playSoundOnCapture
    }
    
    public static let defaultsKey = "TalibTools_Preferences"
    
    public static func load() -> UserPreferences {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let prefs = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            return prefs
        }
        return UserPreferences()
    }
    
    public func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: UserPreferences.defaultsKey)
        }
    }
}
