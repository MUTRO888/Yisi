import Foundation

enum HistoryType: String, Codable {
    case translation
    case preset
    case custom
}

struct TranslationHistoryItem: Identifiable, Codable, Hashable {
    let id: UUID
    let sourceText: String
    let targetText: String
    let sourceLanguage: String
    let targetLanguage: String
    let timestamp: Date
    let type: HistoryType
    let presetName: String?
    let customPrompt: String?
    let imagePath: String?  // 图片相对路径（存储在沙盒 Documents/HistoryImages/）
    
    // Helper to get a display title for the type
    var typeDisplayName: String {
        switch type {
        case .translation:
            return "Translation"
        case .preset:
            return presetName ?? "Preset"
        case .custom:
            return "Custom"
        }
    }
}
