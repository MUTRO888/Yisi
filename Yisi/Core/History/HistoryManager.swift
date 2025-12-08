import Foundation
import Combine
import AppKit

class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    @Published var historyItems: [TranslationHistoryItem] = []
    @Published var selectedGroup: HistoryDateGroup = .all
    
    // MARK: - Pagination
    private let pageSize = 30
    @Published var displayedItemsCount = 30 // 初始顯示數量
    
    // MARK: - Cache System
    /// 縮略圖緩存池 (Key: ImagePath, Value: Downsampled NSImage)
    private let thumbnailCache = NSCache<NSString, NSImage>()
    private let imageDirectoryName = "HistoryImages"
    
    // MARK: - Prefetch System
    /// 預取隊列，用於提前加載即將可見的縮略圖
    private let prefetchQueue = DispatchQueue(label: "com.yisi.thumbnail.prefetch", qos: .utility)
    private var prefetchWorkItems: [UUID: DispatchWorkItem] = [:]
    
    private init() {
        thumbnailCache.countLimit = 200 // 限制緩存數量，防止內存溢出
        loadHistory()
    }
    
    /// 分頁後的過濾項目（只返回前 displayedItemsCount 個）
    var filteredItems: [TranslationHistoryItem] {
        let allFiltered: [TranslationHistoryItem]
        switch selectedGroup {
        case .all: allFiltered = historyItems
        case .today: allFiltered = historyItems.filter { Calendar.current.isDateInToday($0.timestamp) }
        case .yesterday: allFiltered = historyItems.filter { Calendar.current.isDateInYesterday($0.timestamp) }
        case .thisWeek:
            allFiltered = historyItems.filter {
                let calendar = Calendar.current
                guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return false }
                return $0.timestamp > weekAgo && !calendar.isDateInToday($0.timestamp) && !calendar.isDateInYesterday($0.timestamp)
            }
        case .older:
            allFiltered = historyItems.filter {
                let calendar = Calendar.current
                guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return true }
                return $0.timestamp <= weekAgo
            }
        }
        // 只返回前 displayedItemsCount 個項目
        return Array(allFiltered.prefix(displayedItemsCount))
    }
    
    /// 是否還有更多項目可加載
    func hasMoreItems() -> Bool {
        let totalCount: Int
        switch selectedGroup {
        case .all: totalCount = historyItems.count
        case .today: totalCount = historyItems.filter { Calendar.current.isDateInToday($0.timestamp) }.count
        case .yesterday: totalCount = historyItems.filter { Calendar.current.isDateInYesterday($0.timestamp) }.count
        case .thisWeek:
            totalCount = historyItems.filter {
                let calendar = Calendar.current
                guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return false }
                return $0.timestamp > weekAgo && !calendar.isDateInToday($0.timestamp) && !calendar.isDateInYesterday($0.timestamp)
            }.count
        case .older:
            totalCount = historyItems.filter {
                let calendar = Calendar.current
                guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return true }
                return $0.timestamp <= weekAgo
            }.count
        }
        return displayedItemsCount < totalCount
    }
    
    /// 加載更多項目
    func loadMoreItems() {
        displayedItemsCount += pageSize
    }
    
    /// 重置分頁（切換分組時調用）
    func resetPagination() {
        displayedItemsCount = pageSize
    }
    
    func loadHistory() {
        DispatchQueue.global(qos: .userInitiated).async {
            let items = DatabaseManager.shared.fetchAll()
            let sortedItems = items.sorted(by: { $0.timestamp > $1.timestamp })
            DispatchQueue.main.async { self.historyItems = sortedItems }
        }
    }
    
    // MARK: - Image Handling (High Performance)
    
    /// 獲取縮略圖（優先查內存緩存 -> 磁盤降採樣）
    /// - 用途：列表展示，極速加載
    func getThumbnail(for relativePath: String) -> NSImage? {
        let cacheKey = relativePath as NSString
        
        // 1. 命中內存緩存：直接返回
        if let cachedImage = thumbnailCache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // 2. 未命中：從磁盤讀取並降採樣
        guard let fullURL = getFullImagePath(relativePath) else { return nil }
        
        // 目標尺寸：100x100 (Retina 50pt)
        if let downsampled = downsample(imageAt: fullURL, to: CGSize(width: 100, height: 100)) {
            thumbnailCache.setObject(downsampled, forKey: cacheKey)
            return downsampled
        }
        
        return nil
    }
    
    /// 獲取高清原圖（不緩存）
    /// - 用途：詳情頁展示，保證清晰度
    func getFullImage(for relativePath: String) -> NSImage? {
        guard let fullURL = getFullImagePath(relativePath) else { return nil }
        return NSImage(contentsOf: fullURL)
    }
    
    /// ImageIO 高性能降採樣
    private func downsample(imageAt imageURL: URL, to pointSize: CGSize) -> NSImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions) else { return nil }
        
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * 2 // *2 for Retina
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else { return nil }
        return NSImage(cgImage: downsampledImage, size: pointSize)
    }
    
    // MARK: - Prefetch Methods
    
    /// 預取多個項目的縮略圖（用於即將可見的行）
    func prefetchThumbnails(for items: [TranslationHistoryItem]) {
        for item in items {
            guard let path = item.imagePath,
                  thumbnailCache.object(forKey: path as NSString) == nil,
                  prefetchWorkItems[item.id] == nil else { continue }
            
            let workItem = DispatchWorkItem { [weak self] in
                _ = self?.getThumbnail(for: path) // 填充緩存
            }
            prefetchWorkItems[item.id] = workItem
            prefetchQueue.async(execute: workItem)
        }
    }
    
    /// 取消預取（當項目滾動出預取範圍）
    func cancelPrefetch(for items: [TranslationHistoryItem]) {
        for item in items {
            prefetchWorkItems[item.id]?.cancel()
            prefetchWorkItems.removeValue(forKey: item.id)
        }
    }
    // MARK: - File & CRUD Helpers
    
    private func getImageDirectoryURL() -> URL? {
        let fileManager = FileManager.default
        guard let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let imageDir = documentsUrl.appendingPathComponent(imageDirectoryName)
        if !fileManager.fileExists(atPath: imageDir.path) {
            try? fileManager.createDirectory(at: imageDir, withIntermediateDirectories: true)
        }
        return imageDir
    }

    private func saveImageToDisk(_ image: NSImage) -> String? {
        guard let imageDir = getImageDirectoryURL() else { return nil }
        let fileName = "\(UUID().uuidString).jpg"
        let filePath = imageDir.appendingPathComponent(fileName)
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else { return nil }
        try? jpegData.write(to: filePath)
        return "\(imageDirectoryName)/\(fileName)"
    }

    func getFullImagePath(_ relativePath: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsUrl.appendingPathComponent(relativePath)
    }

    private func deleteImageFromDisk(_ relativePath: String) {
        guard let fullPath = getFullImagePath(relativePath) else { return }
        try? FileManager.default.removeItem(at: fullPath)
    }
    
    func addHistory(sourceText: String, targetText: String, sourceLanguage: String, targetLanguage: String, mode: PromptMode, customPerception: String? = nil, customInstruction: String? = nil, image: NSImage? = nil) {
        let id = UUID()
        let timestamp = Date()
        var type: HistoryType = .translation
        var presetName: String? = nil
        var customPrompt: String? = nil
        switch mode {
        case .defaultTranslation: type = .translation
        case .userPreset(let preset): type = .preset; presetName = preset.name
        case .temporaryCustom: type = .custom; var parts: [String] = []; if let p = customPerception, !p.isEmpty { parts.append("I perceive this as \(p)") }; if let i = customInstruction, !i.isEmpty { parts.append("please \(i)") }; customPrompt = parts.joined(separator: ", ")
        }
        var imagePath: String? = nil
        if let img = image {
            imagePath = saveImageToDisk(img)
        }
        let item = TranslationHistoryItem(id: id, sourceText: sourceText, targetText: targetText, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage, timestamp: timestamp, type: type, presetName: presetName, customPrompt: customPrompt, imagePath: imagePath)
        DispatchQueue.global(qos: .userInitiated).async { DatabaseManager.shared.insert(item: item) }
        self.historyItems.insert(item, at: 0)
    }
    
    func deleteHistory(item: TranslationHistoryItem) {
        if let index = self.historyItems.firstIndex(where: { $0.id == item.id }) { self.historyItems.remove(at: index) }
        if let imagePath = item.imagePath { deleteImageFromDisk(imagePath) }
        DispatchQueue.global(qos: .userInitiated).async { DatabaseManager.shared.delete(id: item.id) }
    }
    
    func clearAllHistory() {
        self.historyItems.removeAll()
        DispatchQueue.global(qos: .userInitiated).async { DatabaseManager.shared.clearAll() }
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
