import SwiftUI

struct HistoryView: View {
    @ObservedObject private var historyManager = HistoryManager.shared
    @State private var isSidebarVisible = false
    @State private var showClearConfirmation = false
    @State private var previewImage: NSImage? = nil // State for modal image preview
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Main Content
            VStack(spacing: 0) {
                // List
                if historyManager.filteredItems.isEmpty {
                    EmptyHistoryView()
                        .padding(.leading, isSidebarVisible ? 130 : 0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSidebarVisible)
                } else {
                    TransparentScrollView {
                        VStack(spacing: 0) {
                            ForEach(historyManager.filteredItems) { item in
                                HistoryRowView(item: item) { image in
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        previewImage = image
                                    }
                                }
                                .transition(.opacity)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.leading, isSidebarVisible ? 130 : 0)
                        .frame(maxWidth: .infinity, alignment: .top)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSidebarVisible)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Hover Trigger Zone (Left Edge)
            Rectangle()
                .fill(Color.clear)
                .frame(width: 20)
                .contentShape(Rectangle())
                .onHover { hovering in
                    if hovering {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isSidebarVisible = true
                        }
                    }
                }
            
            // Sidebar
            if isSidebarVisible {
                HistorySidebar(
                    isVisible: $isSidebarVisible,
                    selectedGroup: $historyManager.selectedGroup,
                    onClearAll: {
                        showClearConfirmation = true
                    }
                )
                .transition(.move(edge: .leading))
                .zIndex(2)
            }
            
            // Custom Confirmation Dialog
            if showClearConfirmation {
                Color.black.opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            showClearConfirmation = false
                        }
                    }
                    .zIndex(3)
                
                ClearHistoryConfirmationDialog(
                    isPresented: $showClearConfirmation,
                    onConfirm: {
                        historyManager.clearAllHistory()
                    }
                )
                .zIndex(4)
            }
            
            // Lightbox Layer
            if let image = previewImage {
                Color.black.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(40)
                    )
                    .overlay(alignment: .topTrailing) {
                        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { previewImage = nil } }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(20)
                        }
                        .buttonStyle(.plain)
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) { previewImage = nil }
                    }
                    .transition(.opacity)
                    .zIndex(200)
            }
        }
    }
}

struct HistoryRowView: View {
    let item: TranslationHistoryItem
    let onImageClick: (NSImage) -> Void
    
    @State private var isHovering = false
    @State private var isExpanded = false
    @State private var thumbnailImage: NSImage? = nil
    @State private var expandedHeight: CGFloat = 0
    @State private var collapsedHeight: CGFloat = 0
    @State private var scrollCompensation: CGFloat = 0
    
    /// 是否為圖片記錄
    private var isImageRecord: Bool {
        item.imagePath != nil
    }
    
    var body: some View {
        // 1. 核心容器：強制頂部對齊，消除中心擴展導致的位移
        VStack(alignment: .leading, spacing: 0) {
            
            // 2. 內容區域 (可點擊展開，但展開後不響應收起)
            ZStack(alignment: .topTrailing) {
                contentLayout
                
                // 刪除按鈕 (僅 Hover 顯示)
                if isHovering {
                    Button(action: {
                        withAnimation {
                            HistoryManager.shared.deleteHistory(item: item)
                        }
                    }) {
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
                    // 只有未展開時，點擊才觸發展開
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded = true
                    }
                }
            }
            
            // 3. 底部收起欄 (僅展開時顯示)
            if isExpanded {
                Button(action: {
                    // 計算收起時需要補償的高度差
                    let heightDelta = expandedHeight - collapsedHeight
                    if heightDelta > 0 {
                        scrollCompensation = heightDelta
                    }
                    
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded = false
                    }
                    
                    // 重置補償值（在下一個運行循環）
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        scrollCompensation = 0
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
                .transition(.opacity)
            }
        }
        // 4. 外觀修飾
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        // 記錄初始（collapsed）高度
                        if collapsedHeight == 0 {
                            collapsedHeight = geo.size.height
                        }
                    }
                    .onChange(of: geo.size.height) { _, newHeight in
                        // 追蹤高度變化
                        if isExpanded {
                            expandedHeight = newHeight
                        } else {
                            collapsedHeight = newHeight
                        }
                    }
            }
        )
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
        .preference(key: ScrollCompensationKey.self, value: scrollCompensation)
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
                    let targetText = Text(item.targetText)
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(AppColors.text)
                        .lineLimit(isExpanded ? nil : 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(isExpanded ? 1 : 0)
                    
                    if isExpanded {
                        targetText.textSelection(.enabled)
                    } else {
                        targetText
                    }
                }
                
                // Source (Original)
                if !item.sourceText.isEmpty && item.sourceText != "🖼️ Image Recognition" {
                    let sourceText = Text(item.sourceText)
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(AppColors.text.opacity(0.6))
                        .lineLimit(isExpanded ? nil : 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(isExpanded ? 1 : 0)
                    
                    if isExpanded {
                        sourceText.textSelection(.enabled)
                    } else {
                        sourceText
                    }
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
                                onImageClick(image)
                            }
                        
                        Text("View Image")
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
    
    private func loadThumbnail() {
        guard let imagePath = item.imagePath,
              let fullPath = HistoryManager.shared.getFullImagePath(imagePath) else {
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = NSImage(contentsOf: fullPath) {
                DispatchQueue.main.async {
                    self.thumbnailImage = image
                }
            }
        }
    }
}



struct HistorySidebar: View {
    @Binding var isVisible: Bool
    @Binding var selectedGroup: HistoryDateGroup
    var onClearAll: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(HistoryDateGroup.allCases) { group in
                            SidebarItem(
                                title: group.localizedName,
                                isSelected: selectedGroup == group,
                                action: {
                                    withAnimation {
                                        selectedGroup = group
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 24)
                }
                
                Spacer()
                
                Button(action: onClearAll) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                        Text("Clear All".localized)
                            .font(.system(size: 12, design: .serif))
                    }
                    .foregroundColor(.secondary.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 16)
            }
            .frame(width: 120)
            .background(
                ZStack {
                    VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    Color.white.opacity(0.1)
                }
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 0)
            )
            .padding(.leading, 8)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            
            Rectangle()
                .fill(Color.clear)
                .frame(width: 40)
                .contentShape(Rectangle())
                .onHover { hovering in
                    // Buffer zone logic
                }
        }
        .onHover { hovering in
            if !hovering {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isVisible = false
                }
            }
        }
    }
}

struct SidebarItem: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .medium : .regular, design: .serif))
                .foregroundColor(isSelected ? AppColors.primary : AppColors.text.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? AppColors.primary.opacity(0.1) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ClearHistoryConfirmationDialog: View {
    @Binding var isPresented: Bool
    var onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Clear History".localized)
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundColor(AppColors.text)
            
            Text("Are you sure you want to delete all history items? This action cannot be undone.".localized)
                .font(.system(size: 13, design: .serif))
                .foregroundColor(AppColors.text.opacity(0.7))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }) {
                    Text("Cancel".localized)
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundColor(AppColors.text.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    withAnimation(.spring()) {
                        onConfirm()
                        isPresented = false
                    }
                }) {
                    Text("Clear".localized)
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppColors.primary)
                        .cornerRadius(8)
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .frame(width: 300)
        .background(
            ZStack {
                ThemeBackground()
                Color.white.opacity(0.95)
            }
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .transition(.scale(scale: 0.9).combined(with: .opacity))
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
            return "Vision"
        }
        switch item.type {
        case .translation:
            return "Translation"
        case .preset:
            return item.presetName ?? "Preset"
        case .custom:
            return "Custom"
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
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
