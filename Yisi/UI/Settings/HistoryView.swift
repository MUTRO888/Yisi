import SwiftUI

struct HistoryView: View {
    @ObservedObject private var historyManager = HistoryManager.shared
    @State private var isSidebarVisible = false
    @State private var showClearConfirmation = false
    
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
                                HistoryRowView(item: item)
                                    .transition(.opacity)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.leading, isSidebarVisible ? 130 : 0) // Reduced gap
                        .frame(maxWidth: .infinity, alignment: .top) // Ensure top alignment
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
        }
        .onHover { hovering in
            // Auto-hide sidebar when mouse leaves the entire view area (if needed)
            // But we want it to stay if we are IN the sidebar.
            // The Sidebar view handles its own hover state to stay open.
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
                // Removed duplicate "History" title
                
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
                    .padding(.top, 24) // Add top padding since title is gone
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
            .frame(width: 120) // Reduced width
            .background(
                ZStack {
                    // Custom background: Just VisualEffectView and a LIGHTER tint
                    VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    Color.white.opacity(0.1) // Lighter tint as requested
                }
                .cornerRadius(16) // Rounded corners as requested
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 0)
            )
            .padding(.leading, 8) // Add some spacing from edge for the rounded look? Or keep attached?
            // User said "square corners are too rigid", implying they want the sidebar itself to be rounded.
            // If it's attached to the edge, usually top-right/bottom-right are rounded.
            // Let's try rounding all corners and adding padding, making it a "floating" sidebar.
            .padding(.vertical, 8) 
            .contentShape(Rectangle())
            
            // Invisible closer area (to the right of sidebar)
            Rectangle()
                .fill(Color.clear)
                .frame(width: 40) // Buffer zone
                .contentShape(Rectangle())
                .onHover { hovering in
                    if hovering {
                        // Keep visible
                    } else {
                        // If we leave the sidebar + buffer, hide it
                        // This logic might be tricky. Better to use onHover on the sidebar itself.
                    }
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

struct HistoryRowView: View {
    let item: TranslationHistoryItem
    @State private var isHovering = false
    @State private var isExpanded = false
    @State private var thumbnailImage: NSImage? = nil
    @State private var showImagePreview = false
    
    /// 是否为图片识别记录
    private var isImageRecord: Bool {
        item.imagePath != nil
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 根据是否有图片选择不同的布局
            if isImageRecord {
                imageRecordLayout
            } else {
                textRecordLayout
            }
            
            // Delete Button (Visible on Hover)
            if isHovering {
                Button(action: {
                    withAnimation {
                        HistoryManager.shared.deleteHistory(item: item)
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .light))
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(4)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    // MARK: - 图片识别记录布局（卡片式设计）
    
    private var imageRecordLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 缩略图区域（主视觉焦点）
            ZStack(alignment: .bottomLeading) {
                // 背景图片
                if let image = thumbnailImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: isExpanded ? 160 : 80)
                        .clipped()
                        .overlay(
                            // 渐变遮罩，让文字更易读
                            LinearGradient(
                                colors: [Color.clear, Color.black.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else {
                    // 占位背景
                    Rectangle()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: isExpanded ? 160 : 80)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary.opacity(0.3))
                        )
                }
                
                // 左下角的类型标签
                HStack(spacing: 6) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 9))
                    Text("Vision")
                        .font(.system(size: 10, weight: .medium, design: .serif))
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.3))
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // 内容区域
            VStack(alignment: .leading, spacing: 6) {
                // 时间戳
                Text(item.timestamp.formattedRelative())
                    .font(.system(size: 10, design: .serif))
                    .foregroundColor(.secondary.opacity(0.5))
                
                // 翻译结果
                let targetText = Text(item.targetText)
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(AppColors.text)
                    .lineLimit(isExpanded ? nil : 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                if isExpanded {
                    targetText.textSelection(.enabled)
                } else {
                    targetText
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isHovering ? Color.primary.opacity(0.03) : Color.primary.opacity(0.01))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }
        )
    }
    
    // MARK: - 文本翻译记录布局（原有设计）
    
    private var textRecordLayout: some View {
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovering ? Color.primary.opacity(0.02) : Color.clear)
        )
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }
        )
    }
    
    /// 加载缩略图
    private func loadThumbnail() {
        guard let imagePath = item.imagePath,
              let fullPath = HistoryManager.shared.getFullImagePath(imagePath) else {
            return
        }
        
        // 异步加载图片
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = NSImage(contentsOf: fullPath) {
                DispatchQueue.main.async {
                    self.thumbnailImage = image
                }
            }
        }
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
        switch item.type {
        case .translation:
            return AppColors.primary.opacity(0.6)
        case .preset:
            return AppColors.secondary
        case .custom:
            return Color.teal.opacity(0.7) // Changed from Orange to Teal (Cooler tone)
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
