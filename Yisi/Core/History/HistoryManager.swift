import Foundation
import Combine

class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    @Published var historyItems: [TranslationHistoryItem] = []
    
    @Published var selectedGroup: HistoryDateGroup = .all
    
    private init() {
        loadHistory()
    }
    
    var filteredItems: [TranslationHistoryItem] {
        switch selectedGroup {
        case .all:
            return historyItems
        case .today:
            return historyItems.filter { Calendar.current.isDateInToday($0.timestamp) }
        case .yesterday:
            return historyItems.filter { Calendar.current.isDateInYesterday($0.timestamp) }
        case .thisWeek:
            return historyItems.filter {
                let calendar = Calendar.current
                guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return false }
                return $0.timestamp > weekAgo && !calendar.isDateInToday($0.timestamp) && !calendar.isDateInYesterday($0.timestamp)
            }
        case .older:
            return historyItems.filter {
                let calendar = Calendar.current
                guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return true }
                return $0.timestamp <= weekAgo
            }
        }
    }
    
    func loadHistory() {
        let items = DatabaseManager.shared.fetchAll()
        DispatchQueue.main.async {
            self.historyItems = items.sorted(by: { $0.timestamp > $1.timestamp })
        }
    }
    
    func addHistory(
        sourceText: String,
        targetText: String,
        sourceLanguage: String,
        targetLanguage: String,
        mode: PromptMode,
        customPerception: String? = nil,
        customInstruction: String? = nil
    ) {
        let id = UUID()
        let timestamp = Date()
        
        var type: HistoryType = .translation
        var presetName: String? = nil
        var customPrompt: String? = nil
        
        switch mode {
        case .defaultTranslation:
            type = .translation
        case .userPreset(let preset):
            type = .preset
            presetName = preset.name
        case .temporaryCustom:
            type = .custom
            // Format custom prompt for display
            var parts: [String] = []
            if let p = customPerception, !p.isEmpty {
                parts.append("I perceive this as \(p)")
            }
            if let i = customInstruction, !i.isEmpty {
                parts.append("please \(i)")
            }
            customPrompt = parts.joined(separator: ", ")
        }
        
        let item = TranslationHistoryItem(
            id: id,
            sourceText: sourceText,
            targetText: targetText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            timestamp: timestamp,
            type: type,
            presetName: presetName,
            customPrompt: customPrompt
        )
        
        // Save to DB (Background)
        DispatchQueue.global(qos: .userInitiated).async {
            DatabaseManager.shared.insert(item: item)
        }
        
        // Update UI immediately (Optimistic)
        self.historyItems.insert(item, at: 0)
    }
    
    func deleteHistory(item: TranslationHistoryItem) {
        // Update UI immediately (Optimistic)
        if let index = self.historyItems.firstIndex(where: { $0.id == item.id }) {
            self.historyItems.remove(at: index)
        }
        
        // Delete from DB (Background)
        DispatchQueue.global(qos: .userInitiated).async {
            DatabaseManager.shared.delete(id: item.id)
        }
    }
    
    func clearAllHistory() {
        // Update UI immediately (Optimistic)
        self.historyItems.removeAll()
        
        // Clear DB (Background)
        DispatchQueue.global(qos: .userInitiated).async {
            DatabaseManager.shared.clearAll()
        }
    }
}

enum HistoryDateGroup: String, CaseIterable, Identifiable {
    case all = "All"
    case today = "Today"
    case yesterday = "Yesterday"
    case thisWeek = "This Week"
    case older = "Older"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .all: return "All".localized
        case .today: return "Today".localized
        case .yesterday: return "Yesterday".localized
        case .thisWeek: return "This Week".localized
        case .older: return "Older".localized
        }
    }
}
