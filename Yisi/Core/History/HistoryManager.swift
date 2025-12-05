import Foundation
import Combine
import AppKit

class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    @Published var historyItems: [TranslationHistoryItem] = []
    
    @Published var selectedGroup: HistoryDateGroup = .all
    
    /// 历史图片存储目录名
    private let imageDirectoryName = "HistoryImages"
    
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
    
    // MARK: - Image Storage Helpers
    
    /// 获取图片存储目录的完整路径
    private func getImageDirectoryURL() -> URL? {
        let fileManager = FileManager.default
        guard let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let imageDir = documentsUrl.appendingPathComponent(imageDirectoryName)
        
        // 确保目录存在
        if !fileManager.fileExists(atPath: imageDir.path) {
            try? fileManager.createDirectory(at: imageDir, withIntermediateDirectories: true)
        }
        
        return imageDir
    }
    
    /// 将图片保存到磁盘，返回相对路径
    private func saveImageToDisk(_ image: NSImage) -> String? {
        guard let imageDir = getImageDirectoryURL() else { return nil }
        
        // 生成唯一文件名
        let fileName = "\(UUID().uuidString).jpg"
        let filePath = imageDir.appendingPathComponent(fileName)
        
        // 将 NSImage 转换为 JPEG 数据
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
            print("Failed to convert image to JPEG")
            return nil
        }
        
        // 写入文件
        do {
            try jpegData.write(to: filePath)
            print("Image saved to: \(filePath.path)")
            return "\(imageDirectoryName)/\(fileName)"  // 返回相对路径
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }
    
    /// 将相对路径转换为完整的文件系统 URL
    func getFullImagePath(_ relativePath: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsUrl.appendingPathComponent(relativePath)
    }
    
    /// 删除磁盘上的图片文件
    private func deleteImageFromDisk(_ relativePath: String) {
        guard let fullPath = getFullImagePath(relativePath) else { return }
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: fullPath.path) {
            try? fileManager.removeItem(at: fullPath)
            print("Deleted image: \(fullPath.path)")
        }
    }
    
    // MARK: - History CRUD
    
    func addHistory(
        sourceText: String,
        targetText: String,
        sourceLanguage: String,
        targetLanguage: String,
        mode: PromptMode,
        customPerception: String? = nil,
        customInstruction: String? = nil,
        image: NSImage? = nil
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
        
        // 保存图片到磁盘（如果存在）
        var imagePath: String? = nil
        if let img = image {
            imagePath = saveImageToDisk(img)
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
            customPrompt: customPrompt,
            imagePath: imagePath
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
        
        // Delete associated image from disk (if exists)
        if let imagePath = item.imagePath {
            deleteImageFromDisk(imagePath)
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
