import SwiftUI
import AppKit

/// 高性能虛擬列表組件，基於 NSTableView 實現單元格回收
struct VirtualizedHistoryList: NSViewRepresentable {
    @ObservedObject var historyManager: HistoryManager
    let onImageClick: (NSImage) -> Void
    
    func makeNSView(context: Context) -> NSScrollView {
        // 使用 YisiScrollView 保持統一的滾動條樣式
        let scrollView = YisiScrollView()
        
        let tableView = NSTableView()
        tableView.style = .plain
        tableView.backgroundColor = .clear
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.selectionHighlightStyle = .none
        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        tableView.headerView = nil
        tableView.usesAutomaticRowHeights = true
        
        // 單列設置
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("content"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        
        scrollView.documentView = tableView
        context.coordinator.tableView = tableView
        context.coordinator.scrollView = scrollView
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let oldItems = context.coordinator.items
        let newItems = historyManager.filteredItems
        
        // 只有當數據實際改變時才重新加載
        if oldItems.map({ $0.id }) != newItems.map({ $0.id }) {
            context.coordinator.items = newItems
            context.coordinator.onImageClick = onImageClick
            context.coordinator.historyManager = historyManager
            context.coordinator.tableView?.reloadData()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(items: historyManager.filteredItems, onImageClick: onImageClick, historyManager: historyManager)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
        var items: [TranslationHistoryItem]
        var onImageClick: (NSImage) -> Void
        var historyManager: HistoryManager
        weak var tableView: NSTableView?
        weak var scrollView: NSScrollView?
        
        // 追蹤展開狀態
        var expandedRows: Set<UUID> = []
        
        // Cell 視圖緩存池
        private var cellCache: [UUID: HistoryTableCellView] = [:]
        
        init(items: [TranslationHistoryItem], onImageClick: @escaping (NSImage) -> Void, historyManager: HistoryManager) {
            self.items = items
            self.onImageClick = onImageClick
            self.historyManager = historyManager
            super.init()
        }
        
        // MARK: - DataSource
        
        func numberOfRows(in tableView: NSTableView) -> Int {
            return items.count
        }
        
        // MARK: - Delegate
        
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard row < items.count else { return nil }
            let item = items[row]
            
            // 嘗試從緩存獲取或創建新的 cell
            let cellView: HistoryTableCellView
            if let cached = cellCache[item.id] {
                cellView = cached
            } else {
                cellView = HistoryTableCellView()
                cellCache[item.id] = cellView
            }
            
            let isExpanded = expandedRows.contains(item.id)
            cellView.configure(
                with: item,
                isExpanded: isExpanded,
                historyManager: historyManager,
                onExpand: { [weak self] in
                    self?.toggleExpand(row: row, itemId: item.id)
                },
                onCollapse: { [weak self] in
                    self?.toggleExpand(row: row, itemId: item.id)
                },
                onDelete: { [weak self] in
                    self?.deleteItem(at: row)
                },
                onImageClick: onImageClick
            )
            
            return cellView
        }
        
        func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
            guard row < items.count else { return 80 }
            let item = items[row]
            
            if expandedRows.contains(item.id) {
                // 展開狀態：動態計算高度
                return calculateExpandedHeight(for: item)
            } else {
                // 收起狀態：固定高度
                return 80
            }
        }
        
        // MARK: - Actions
        
        private func toggleExpand(row: Int, itemId: UUID) {
            guard row < items.count else { return }
            let item = items[row]
            
            if expandedRows.contains(itemId) {
                expandedRows.remove(itemId)
            } else {
                expandedRows.insert(itemId)
            }
            
            let isExpanded = expandedRows.contains(itemId)
            
            // 重新配置 cell 以更新展開狀態
            if let cellView = cellCache[itemId] {
                cellView.configure(
                    with: item,
                    isExpanded: isExpanded,
                    historyManager: historyManager,
                    onExpand: { [weak self] in
                        self?.toggleExpand(row: row, itemId: itemId)
                    },
                    onCollapse: { [weak self] in
                        self?.toggleExpand(row: row, itemId: itemId)
                    },
                    onDelete: { [weak self] in
                        self?.deleteItem(at: row)
                    },
                    onImageClick: onImageClick
                )
            }
            
            // 動畫更新行高
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.allowsImplicitAnimation = true
                tableView?.noteHeightOfRows(withIndexesChanged: IndexSet(integer: row))
            }
        }
        
        private func deleteItem(at row: Int) {
            guard row < items.count else { return }
            let item = items[row]
            historyManager.deleteHistory(item: item)
        }
        
        private func calculateExpandedHeight(for item: TranslationHistoryItem) -> CGFloat {
            // 基礎高度 + 文本行數估算
            var height: CGFloat = 100 // Header + padding
            
            // 目標文本（翻譯結果）
            let targetLines = max(1, item.targetText.count / 40)
            height += CGFloat(targetLines) * 18
            
            // 源文本
            if !item.sourceText.isEmpty && item.sourceText != "🖼️ Image Recognition" {
                let sourceLines = max(1, item.sourceText.count / 40)
                height += CGFloat(sourceLines) * 18 + 10
            }
            
            // 圖片縮略圖
            if item.imagePath != nil {
                height += 80
            }
            
            // 自定義提示
            if item.type == .custom && item.customPrompt != nil {
                height += 60
            }
            
            // 底部收起欄
            height += 30
            
            return max(height, 150)
        }
    }
}

// MARK: - History Table Cell View

class HistoryTableCellView: NSView {
    private var hostingView: NSHostingView<AnyView>?
    private var currentItemId: UUID?
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    func configure(
        with item: TranslationHistoryItem,
        isExpanded: Bool,
        historyManager: HistoryManager,
        onExpand: @escaping () -> Void,
        onCollapse: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onImageClick: @escaping (NSImage) -> Void
    ) {
        currentItemId = item.id
        
        let content = HistoryCellContent(
            item: item,
            isExpanded: isExpanded,
            historyManager: historyManager,
            onExpand: onExpand,
            onCollapse: onCollapse,
            onDelete: onDelete,
            onImageClick: onImageClick
        )
        
        if let existing = hostingView {
            existing.rootView = AnyView(content)
        } else {
            let hosting = NSHostingView(rootView: AnyView(content))
            hosting.translatesAutoresizingMaskIntoConstraints = false
            addSubview(hosting)
            
            NSLayoutConstraint.activate([
                hosting.topAnchor.constraint(equalTo: topAnchor),
                hosting.leadingAnchor.constraint(equalTo: leadingAnchor),
                hosting.trailingAnchor.constraint(equalTo: trailingAnchor),
                hosting.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            
            hostingView = hosting
        }
    }
}

// MARK: - History Cell Content (SwiftUI)

struct HistoryCellContent: View {
    let item: TranslationHistoryItem
    let isExpanded: Bool
    let historyManager: HistoryManager
    let onExpand: () -> Void
    let onCollapse: () -> Void
    let onDelete: () -> Void
    let onImageClick: (NSImage) -> Void
    
    @State private var isHovering = false
    @State private var thumbnailImage: NSImage? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 內容區域
            ZStack(alignment: .topTrailing) {
                contentLayout
                
                // 刪除按鈕
                if isHovering {
                    Button(action: onDelete) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(10)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if !isExpanded {
                    onExpand()
                }
            }
            
            // 底部收起欄
            if isExpanded {
                Button(action: onCollapse) {
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.up")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppColors.primary.opacity(0.6))
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.03))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovering || isExpanded ? Color.primary.opacity(0.02) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(isExpanded ? 0.1 : 0.05), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .onHover { isHovering = $0 }
        .onAppear { loadThumbnail() }
    }
    
    // MARK: - Content Layout
    
    @ViewBuilder
    private var contentLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                HistoryTypeTag(item: item)
                
                Text(item.timestamp.formattedRelative())
                    .font(.system(size: 11, design: .serif))
                    .foregroundColor(.secondary.opacity(0.5))
                
                Spacer()
            }
            .allowsHitTesting(false)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Target (Translation)
                if !item.targetText.isEmpty {
                    Text(item.targetText)
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(AppColors.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(isExpanded ? nil : 1)
                        .fixedSize(horizontal: false, vertical: isExpanded)
                }
                
                // Source (Original) - 展開時顯示
                if isExpanded && !item.sourceText.isEmpty && item.sourceText != "🖼️ Image Recognition" {
                    Text(item.sourceText)
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(AppColors.text.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                
                // 展開時的圖片縮略圖
                if isExpanded, let image = thumbnailImage {
                    HStack(spacing: 8) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            .onTapGesture {
                                if let path = item.imagePath {
                                    DispatchQueue.global(qos: .userInitiated).async {
                                        if let fullImage = historyManager.getFullImage(for: path) {
                                            DispatchQueue.main.async { onImageClick(fullImage) }
                                        }
                                    }
                                }
                            }
                        
                        Text("View Image")
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
                
                // Custom Prompt Details
                if isExpanded, item.type == .custom, let prompt = item.customPrompt {
                    VStack(alignment: .leading, spacing: 4) {
                        Divider().opacity(0.1).padding(.vertical, 2)
                        Text(prompt)
                            .font(.system(size: 11, design: .serif).italic())
                            .foregroundColor(AppColors.primary.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .padding(16)
    }
    
    // MARK: - Load Thumbnail
    
    private func loadThumbnail() {
        guard let path = item.imagePath else { return }
        
        if let cached = historyManager.getThumbnail(for: path) {
            self.thumbnailImage = cached
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let thumb = historyManager.getThumbnail(for: path) {
                DispatchQueue.main.async { self.thumbnailImage = thumb }
            }
        }
    }
}
