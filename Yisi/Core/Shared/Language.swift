import Foundation

enum Language: String, CaseIterable, Identifiable {
    case auto = "Auto Detect"
    case english = "English"
    case simplifiedChinese = "Simplified Chinese"
    case traditionalChinese = "Traditional Chinese"
    case japanese = "Japanese"
    case korean = "Korean"
    case french = "French"
    case spanish = "Spanish"
    case german = "German"
    case russian = "Russian"
    case arabic = "Arabic"
    case thai = "Thai"
    case vietnamese = "Vietnamese"
    
    var displayName: String {
        return self.rawValue.localized
    }
    
    var id: String { self.rawValue }
    
    // Languages available for source selection
    static var sourceLanguages: [Language] {
        return Language.allCases
    }
    
    // Languages available for target selection (Auto is not a valid target)
    static var targetLanguages: [Language] {
        return Language.allCases.filter { $0 != .auto }
    }
}
