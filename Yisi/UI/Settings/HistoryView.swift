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
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background & Content Container
            VStack(alignment: .leading, spacing: 10) {
                // Header: Type Tag + Timestamp
                HStack(spacing: 8) {
                    HistoryTypeTag(item: item)
                    
                    Text(item.timestamp.formattedRelative())
                        .font(.system(size: 11, design: .serif))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Spacer()
                }
                .allowsHitTesting(false) // Pass clicks on header to background
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    // Target (Translation)
                    if !item.targetText.isEmpty {
                        let targetText = Text(item.targetText)
                            .font(.system(size: 13, design: .serif))
                            .foregroundColor(AppColors.text)
                            .lineLimit(isExpanded ? nil : 1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true) // Ensure full height
                        
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
                        .fixedSize(horizontal: false, vertical: true) // Ensure full height
                    
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
                                    .textSelection(.enabled) // Always selectable when expanded
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
            .contentShape(Rectangle()) // Make entire area hit-testable
            .simultaneousGesture(
                TapGesture().onEnded {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }
            )
            
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
