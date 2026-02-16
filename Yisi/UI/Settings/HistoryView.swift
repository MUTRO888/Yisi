import SwiftUI

struct HistoryView: View {
    @ObservedObject private var historyManager = HistoryManager.shared
    @State private var previewImage: NSImage? = nil
    @Environment(\.colorScheme) var currentColorScheme
    
    // Optical Lens State
    @State private var isSearchVisible = false // Capsule Visible (Surface Tension)
    @State private var isSearchExpanded = false // Bar Expanded (Active Lens)
    @State private var hoverTimer: Timer?
    // Removed expandTimer to prevent accidental triggers
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Main Content Stream (The Stage)
            VStack(spacing: 0) {
                if historyManager.filteredItems.isEmpty {
                    // Empty State
                    if !historyManager.searchQuery.isEmpty {
                        // Search - No Results
                         VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(.secondary.opacity(0.3))
                            Text("No matches found".localized)
                                .font(.system(size: 14, weight: .medium, design: .serif))
                                .foregroundColor(.secondary.opacity(0.8))
                            Spacer()
                        }
                    } else {
                        // No History at all
                        EmptyHistoryView()
                    }
                } else {
                    // Content List
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            Color.clear.frame(height: 20)
                            
                            ForEach(historyManager.filteredItems) { item in
                                HistoryRowView(item: item) { image in
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        previewImage = image
                                    }
                                }
                                .frame(maxWidth: 600)
                                .transition(.opacity.combined(with: .move(edge: .bottom))) // Dissolve / Re-aggregate
                            }
                            
                            
                            if historyManager.hasMoreItems() {
                                Button(action: {
                                    withAnimation { historyManager.loadMoreItems() }
                                }) {
                                    Text("Load More".localized)
                                        .font(.system(size: 12, design: .serif))
                                        .foregroundColor(.secondary.opacity(0.5))
                                        .padding(.vertical, 20)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Color.clear.frame(height: 100)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .scrollContentBackground(.hidden)
                    // Scene Management: Recede only when "Focusing" (Expanded + Empty)
                    .blur(radius: (isSearchExpanded && historyManager.searchQuery.isEmpty) ? 8 : 0)
                    .scaleEffect((isSearchExpanded && historyManager.searchQuery.isEmpty) ? 0.98 : 1)
                    // Interaction: Block ONLY if we are in "Focus Mode" (Empty Search).
                    // If showing results (Query !Empty), we MUST allow interaction.
                    .allowsHitTesting(!(isSearchExpanded && historyManager.searchQuery.isEmpty))
                    .animation(.easeOut(duration: 0.3), value: isSearchExpanded)
                    .animation(.easeOut(duration: 0.3), value: historyManager.searchQuery.isEmpty)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle()) // Capture taps on empty space
            .onTapGesture {
                // Exit Mechanism: Click Outside
                if isSearchExpanded {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isSearchExpanded = false
                        // If no text, hide completely
                        if historyManager.searchQuery.isEmpty {
                            isSearchVisible = false
                        }
                        // If text exists, we just collapse to "Badge" mode to let user view results.
                        // We DO NOT clear text on background tap anymore, to prevent accidental loss of results.
                    }
                }
            }
            
            // 2. Optical Lens (Periscope)
            PeriscopeSearchField(
                text: $historyManager.searchQuery,
                isVisible: $isSearchVisible,
                isExpanded: $isSearchExpanded
            )
            .padding(.bottom, 12) // Total offset 12px (previously 30+8=38)
            .zIndex(10)
            .onHover { mirroring in
                isHoveringBar = mirroring
                checkHoverState()
            }
            
            // 3. Trigger Zone (Bottom 18%)
            GeometryReader { geo in
                VStack {
                    Spacer()
                    Color.clear
                        .frame(height: geo.size.height * 0.18)
                        .contentShape(Rectangle())
                        .onHover { mirroring in
                            isHoveringTrigger = mirroring
                            checkHoverState()
                        }
                }
            }
            // Trigger Zone always active to catch hovers for Re-Expand
            
            // Lightbox Overlay
            if let image = previewImage {
                LightboxView(image: image, onClose: { previewImage = nil })
            }
        }
    }
    
    // MARK: - Hover Logic
    
    @State private var isHoveringTrigger = false
    @State private var isHoveringBar = false
    
    private func checkHoverState() {
        // Debounce slightly to handle gap jumps? (SwiftUI onHover is usually immediate)
        // Main Logic:
        if isHoveringTrigger || isHoveringBar {
            // Enter / Maintain
            hoverTimer?.invalidate()
            
            withAnimation(.easeOut(duration: 0.3)) {
                isSearchVisible = true
            }
            
            // Auto-Expand if we are directly interacting with the BAR components
            // (e.g., hovering the badge to check it)
            if isHoveringBar {
                // Only auto-expand if we have text (logic: viewing results -> want to edit)
                // OR if user clicks (handled by tap).
                // User said: "Automatic display logic".
                // If I hover the Badge (Filtered), it should expand?
                if !historyManager.searchQuery.isEmpty {
                     withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isSearchExpanded = true
                    }
                }
            }
        } else {
            // Exit Both -> Start Timer
            hoverTimer?.invalidate()
            hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    // Double check state inside timer
                    if !self.isHoveringTrigger && !self.isHoveringBar {
                        if historyManager.searchQuery.isEmpty {
                            // Usage: Idle -> Fade out
                            isSearchExpanded = false
                            isSearchVisible = false
                        } else {
                            // Usage: Viewing Results -> Collapse to Badge
                            isSearchExpanded = false
                            // isSearchVisible remains true (Badge)
                        }
                    }
                }
            }
        }
    }
}

// Helper for Lightbox to clean up main view
struct LightboxView: View {
    let image: NSImage
    let onClose: () -> Void
    
    var body: some View {
        Color.black.opacity(0.8)
            .edgesIgnoringSafeArea(.all)
            .overlay(
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(40)
            )
            .overlay(alignment: .topTrailing) {
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { onClose() } }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(20)
                }
                .buttonStyle(.plain)
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) { onClose() }
            }
            .transition(.opacity)
            .zIndex(200)
    }
}

// MARK: - Restored Components

struct HistoryRowView: View {
    let item: TranslationHistoryItem
    let onImageClick: (NSImage) -> Void
    
    @State private var isHovering = false
    @State private var isExpanded = false
    @State private var thumbnailImage: NSImage? = nil
    
    var body: some View {
        // 1. 核心容器：強制頂部對齊
        VStack(alignment: .leading, spacing: 0) {
            
            // 2. 內容區域 (可點擊展開)
            ZStack(alignment: .topTrailing) {
                contentLayout
                
                // 刪除按鈕 (僅 Hover 顯示)
                if isHovering {
                    Button(action: {
                        HistoryManager.shared.deleteHistory(item: item)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(10)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if !isExpanded {
                    // 使用簡單的 easeInOut 動畫，比 spring 更輕量
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded = true
                    }
                }
            }
            
            // 3. 底部收起欄 (僅展開時顯示)
            if isExpanded {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded = false
                    }
                }) {
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
        // 4. 外觀修飾
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
            // Header: Type Tag + Timestamp
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
                    CollapsibleText(
                        text: item.targetText,
                        font: .system(size: 13, design: .serif),
                        color: AppColors.text,
                        isExpanded: isExpanded
                    )
                    .layoutPriority(isExpanded ? 1 : 0)
                }
                
                // Source (Original)
                if !item.sourceText.isEmpty && item.sourceText != "🖼️ Image Recognition" {
                    CollapsibleText(
                        text: item.sourceText,
                        font: .system(size: 13, design: .serif),
                        color: AppColors.text.opacity(0.6),
                        isExpanded: isExpanded
                    )
                    .layoutPriority(isExpanded ? 1 : 0)
                }
                
                // Expanded Image Thumbnail
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
                                // 加載高清原圖用於詳情頁展示
                                if let path = item.imagePath {
                                    DispatchQueue.global(qos: .userInitiated).async {
                                        if let fullImage = HistoryManager.shared.getFullImage(for: path) {
                                            DispatchQueue.main.async { onImageClick(fullImage) }
                                        }
                                    }
                                }
                            }
                        
                        Text("View Image".localized)
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
                
                // Custom Prompt Details
                if item.type == .custom, let prompt = item.customPrompt {
                    if isExpanded {
                        VStack(alignment: .leading, spacing: 4) {
                            Divider().opacity(0.1).padding(.vertical, 2)
                            Text(prompt)
                                .font(.system(size: 11, design: .serif).italic())
                                .foregroundColor(AppColors.primary.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                                .layoutPriority(1)
                        }
                    }
                }
            }
        }
        .padding(16)
    }
    
    // MARK: - Load Thumbnail
    
    /// 加載縮略圖（使用 HistoryManager 的緩存系統）
    private func loadThumbnail() {
        guard let path = item.imagePath else { return }

        // 1. 同步檢查內存緩存（極速，解決切換 Tab 卡頓）
        if let cached = HistoryManager.shared.getThumbnail(for: path) {
            self.thumbnailImage = cached
            return
        }

        // 2. 異步加載（首次讀取）
        DispatchQueue.global(qos: .userInitiated).async {
            if let thumb = HistoryManager.shared.getThumbnail(for: path) {
                DispatchQueue.main.async { self.thumbnailImage = thumb }
            }
        }
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.secondary.opacity(0.2))
            Text("No History".localized)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(.secondary.opacity(0.8))
            Text("Your recent translations will appear here.".localized)
                .font(.system(size: 12, design: .serif))
                .foregroundColor(.secondary.opacity(0.5))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HistoryTypeTag: View {
    let item: TranslationHistoryItem
    
    var body: some View {
        HStack(spacing: 4) {
            // Minimalist dot indicator
            Circle()
                .fill(indicatorColor)
                .frame(width: 4, height: 4)
            
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .serif))
                .foregroundColor(AppColors.text.opacity(0.6))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.primary.opacity(0.02))
        .cornerRadius(4)
    }
    
    var label: String {
        if item.imagePath != nil {
            return "Vision".localized
        }
        switch item.type {
        case .translation:
            return "Translation".localized
        case .preset:
            return item.presetName ?? "Preset".localized
        case .custom:
            return "Custom".localized
        }
    }
    
    var indicatorColor: Color {
        if item.imagePath != nil {
            return .purple.opacity(0.7)
        }
        switch item.type {
        case .translation:
            return AppColors.primary.opacity(0.6)
        case .preset:
            return AppColors.secondary
        case .custom:
            return Color.teal.opacity(0.7)
        }
    }
}

extension Date {
    func formattedRelative() -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(self) {
            return "Today".localized
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday".localized
        } else {
            // 超過昨天的顯示具體日期
            let components = calendar.dateComponents([.day], from: self, to: Date())
            if let days = components.day, days < 7 {
                let format = "%d days ago".localized
                return String(format: format, days)
            } else {
                let formatter = DateFormatter()
                let language = LocalizationManager.shared.language
                formatter.dateFormat = language == "zh" ? "M月d日" : "MMM d"
                return formatter.string(from: self)
            }
        }
    }
}

// MARK: - Helper Views

private struct CollapsibleText: View {
    let text: String
    let font: Font
    let color: Color
    let isExpanded: Bool
    
    @State private var singleLineHeight: CGFloat = 18 // Default approximation
    
    var body: some View {
        let textContent = Text(text)
            .font(font)
            .foregroundColor(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true) // Force full height logic
            .lineLimit(nil) // Always render all lines
            .frame(height: isExpanded ? nil : singleLineHeight, alignment: .top)
            .clipped() // The core "Drawer" effect
            .background(
                // Invisible measuring view for single-line height
                Text(text)
                    .font(font)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(GeometryReader { geo in
                        Color.clear.onAppear {
                            singleLineHeight = geo.size.height
                        }
                    })
                    .hidden()
            )
        
        if isExpanded {
            textContent.textSelection(.enabled)
        } else {
            textContent.textSelection(.disabled)
        }
    }
}
