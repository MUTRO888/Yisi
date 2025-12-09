import SwiftUI

enum ClosingMode: String, CaseIterable, Identifiable {
    case clickOutside = "clickOutside"
    case xButton = "xButton"
    case escKey = "escKey"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .clickOutside: return "Click Outside"
        case .xButton: return "X Button"
        case .escKey: return "Esc Key"
        }
    }
}

struct SettingsView: View {
    @State private var selectedTopTab: Int = 0 // 0: History, 1: Settings
    @AppStorage("app_theme") private var appTheme: String = "system"
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation
            HStack(spacing: 24) { // 減小標籤間距，更緊湊
                TopTabButton(title: "History".localized, isSelected: selectedTopTab == 0) { selectedTopTab = 0 }
                TopTabButton(title: "Settings".localized, isSelected: selectedTopTab == 1) { selectedTopTab = 1 }
                Spacer()
            }
            .padding(.leading, 20) // 微調對齊位置
            .padding(.trailing, 20)
            .padding(.top, 14)
            .padding(.bottom, 4) // 大幅減小，讓內容區上提
            
            // Content Area (使用 ZStack 保活視圖，避免切換時重新初始化)
            ZStack(alignment: .topLeading) {
                // History Tab (Index 0)
                HistoryView()
                    .opacity(selectedTopTab == 0 ? 1 : 0)
                    .allowsHitTesting(selectedTopTab == 0) // 隱藏時禁止點擊
                
                // Settings Tab (Index 1)
                SettingsContent()
                    .opacity(selectedTopTab == 1 ? 1 : 0)
                    .allowsHitTesting(selectedTopTab == 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // 填充剩餘空間
        }
        .frame(minWidth: 500, minHeight: 350)
        .background(ThemeBackground().edgesIgnoringSafeArea(.all))
        .preferredColorScheme(ColorScheme(from: appTheme))
    }
}

struct TopTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .medium : .regular, design: .serif))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                // Active Indicator
                Rectangle()
                    .fill(isSelected ? AppColors.primary.opacity(0.7) : Color.clear)
                    .frame(height: 1)
                    .frame(width: 20)
            }
        }
        .buttonStyle(.plain)
    }
}

/// 截图快捷键录制器
struct ScreenshotShortcutRecorder: View {
    @State private var isRecording = false
    @State private var currentShortcut: String = ""
    @State private var monitor: Any?
    
    var body: some View {
        Button(action: {
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        }) {
            HStack {
                if isRecording {
                    Text("Press keys...".localized)
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(.accentColor)
                    Spacer()
                    Image(systemName: "record.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)
                        .symbolEffect(.pulse)
                } else {
                    Text(currentShortcut.isEmpty ? "Record Shortcut".localized : currentShortcut)
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(.primary)
                    Spacer()
                    if !currentShortcut.isEmpty {
                        Button(action: {
                            resetShortcut()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .frame(width: 160)
            .background(isRecording ? AppColors.primary.opacity(0.1) : AppColors.primary.opacity(0.05))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isRecording ? AppColors.primary.opacity(0.3) : AppColors.primary.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            updateDisplay()
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyDown(event)
            return nil
        }
    }
    
    private func stopRecording() {
        isRecording = false
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
    
    private func resetShortcut() {
        GlobalShortcutManager.shared.updateScreenshotShortcut(keyCode: 7, modifiers: [.command, .shift])
        updateDisplay()
    }
    
    private func updateDisplay() {
        let keyCode = UserDefaults.standard.integer(forKey: "screenshot_shortcut_key")
        let modifiers = UserDefaults.standard.integer(forKey: "screenshot_shortcut_modifiers")
        
        if keyCode != 0 {
            currentShortcut = shortcutString(keyCode: UInt16(keyCode), modifiers: NSEvent.ModifierFlags(rawValue: UInt(modifiers)))
        } else {
            currentShortcut = "⌘⇧X" // Default
        }
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode
        
        if event.type == .flagsChanged { return }
        if keyCode == 53 { stopRecording(); return }
        
        GlobalShortcutManager.shared.updateScreenshotShortcut(keyCode: keyCode, modifiers: flags)
        updateDisplay()
        stopRecording()
    }
    
    private func shortcutString(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> String {
        var string = ""
        if modifiers.contains(.command) { string += "⌘" }
        if modifiers.contains(.control) { string += "⌃" }
        if modifiers.contains(.option) { string += "⌥" }
        if modifiers.contains(.shift) { string += "⇧" }
        
        switch keyCode {
        case 0: string += "A"; case 1: string += "S"; case 2: string += "D"; case 3: string += "F"
        case 4: string += "H"; case 5: string += "G"; case 6: string += "Z"; case 7: string += "X"
        case 8: string += "C"; case 9: string += "V"; case 11: string += "B"; case 12: string += "Q"
        case 13: string += "W"; case 14: string += "E"; case 15: string += "R"; case 16: string += "Y"
        case 17: string += "T"; case 31: string += "O"; case 32: string += "U"; case 34: string += "I"
        case 35: string += "P"; case 37: string += "L"; case 38: string += "J"; case 40: string += "K"
        case 45: string += "N"; case 46: string += "M"
        default: string += "?"
        }
        return string
    }
}

struct SettingsContent: View {
    @State private var selectedSection: String = "General"
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 4) {
                SidebarButton(title: "General".localized, isSelected: selectedSection == "General") { selectedSection = "General" }
                SidebarButton(title: "Prompts".localized, isSelected: selectedSection == "Prompts") { selectedSection = "Prompts" }
                SidebarButton(title: "Shortcuts".localized, isSelected: selectedSection == "Shortcuts") { selectedSection = "Shortcuts" }
                SidebarButton(title: "Learned Rules".localized, isSelected: selectedSection == "Learned Rules") { selectedSection = "Learned Rules" }
                Spacer()
            }
            .padding(.vertical, 14) // 内部内边距调整为 14
            .padding(.horizontal, 8)
            .frame(width: 140)
            .background(
                ZStack {
                    VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    Color.white.opacity(0.1)
                }
                .cornerRadius(12) // 圆角微调为 12，更精致
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 0)
            )
            .padding(.leading, 12)
            .padding(.top, 0) // 緊貼導航欄下方
            .padding(.bottom, 12)
            
            // Section Content
            TransparentScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if selectedSection == "General" {
                        GeneralSection()
                    } else if selectedSection == "Prompts" {
                        PromptsSection()
                    } else if selectedSection == "Shortcuts" {
                        ShortcutsSection()
                    } else if selectedSection == "Learned Rules" {
                        LearnedRulesSection()
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct SidebarButton: View {
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

// MARK: - Reusable API Configuration Form

private struct APIConfigForm: View {
    @Binding var provider: String
    @Binding var geminiKey: String
    @Binding var geminiModel: String
    @Binding var openaiKey: String
    @Binding var openaiModel: String
    @Binding var zhipuKey: String
    @Binding var zhipuModel: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Provider".localized)
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)
                
                CustomDropdown(selection: $provider, options: ["Gemini", "OpenAI", "Zhipu AI"])
            }
            
            if provider == "Gemini" {
                APIKeyInput(label: "API Key".localized, text: $geminiKey, placeholder: "Gemini API Key")
                APIKeyInput(label: "Model".localized, text: $geminiModel, placeholder: "gemini-2.0-flash-exp", isSecure: false)
            } else if provider == "OpenAI" {
                APIKeyInput(label: "API Key".localized, text: $openaiKey, placeholder: "OpenAI API Key")
                APIKeyInput(label: "Model".localized, text: $openaiModel, placeholder: "gpt-4o-mini", isSecure: false)
            } else if provider == "Zhipu AI" {
                APIKeyInput(label: "API Key".localized, text: $zhipuKey, placeholder: "Zhipu API Key")
                APIKeyInput(label: "Model".localized, text: $zhipuModel, placeholder: "glm-4-flash", isSecure: false)
            }
        }
    }
}

struct GeneralSection: View {
    // Text Mode API Settings (Default)
    @AppStorage("default_source_language") private var defaultSourceLanguage: String = "Auto Detect"
    @AppStorage("default_target_language") private var defaultTargetLanguage: String = "Simplified Chinese"
    @AppStorage("gemini_api_key") private var geminiKey: String = ""
    @AppStorage("openai_api_key") private var openaiKey: String = ""
    @AppStorage("zhipu_api_key") private var zhipuKey: String = ""
    @AppStorage("gemini_model") private var geminiModel: String = "gemini-2.0-flash-exp"
    @AppStorage("openai_model") private var openaiModel: String = "gpt-4o-mini"
    @AppStorage("zhipu_model") private var zhipuModel: String = "glm-4-flash"
    @AppStorage("api_provider") private var apiProvider: String = "Gemini"
    
    // Image Mode API Settings
    @AppStorage("apply_api_to_image_mode") private var applyApiToImageMode: Bool = true
    @AppStorage("image_api_provider") private var imageApiProvider: String = "Gemini"
    @AppStorage("image_gemini_api_key") private var imageGeminiKey: String = ""
    @AppStorage("image_gemini_model") private var imageGeminiModel: String = "gemini-2.0-flash-exp"
    @AppStorage("image_openai_api_key") private var imageOpenaiKey: String = ""
    @AppStorage("image_openai_model") private var imageOpenaiModel: String = "gpt-4o-mini"
    @AppStorage("image_zhipu_api_key") private var imageZhipuKey: String = ""
    @AppStorage("image_zhipu_model") private var imageZhipuModel: String = "glm-4v-flash"
    
    // General Settings
    @AppStorage("close_mode") private var closeMode: String = "clickOutside"
    @AppStorage("app_theme") private var appTheme: String = "system"
    @AppStorage("enable_improve_feature") private var enableImproveFeature: Bool = false
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Language & Appearance
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "General".localized)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Language".localized)
                            .font(.system(size: 13, design: .serif))
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        
                        CustomDropdown(
                            selection: $localizationManager.language,
                            options: ["en", "zh"],
                            displayNames: ["English".localized, "Simplified Chinese".localized]
                        )
                    }
                    
                    HStack {
                        Text("Appearance".localized)
                            .font(.system(size: 13, design: .serif))
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        
                        CustomDropdown(
                            selection: $appTheme,
                            options: ["system", "light", "dark"],
                            displayNames: ["System".localized, "Light".localized, "Dark".localized]
                        )
                    }
                }
            }
            
            Divider().opacity(0.3)
            
            // Default Translation Path
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Default Path".localized)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Source".localized)
                            .font(.system(size: 13, design: .serif))
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        
                        CustomDropdown(
                            selection: $defaultSourceLanguage,
                            options: Language.sourceLanguages.map { $0.rawValue },
                            displayNames: Language.sourceLanguages.map { $0.displayName }
                        )
                    }
                    
                    HStack {
                        Text("Target".localized)
                            .font(.system(size: 13, design: .serif))
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        
                        CustomDropdown(
                            selection: $defaultTargetLanguage,
                            options: Language.targetLanguages.map { $0.rawValue },
                            displayNames: Language.targetLanguages.map { $0.displayName }
                        )
                    }
                }
            }
            
            Divider().opacity(0.3)
            
            // API Configuration (Text Mode - Default)
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "API Service".localized)
                
                APIConfigForm(
                    provider: $apiProvider,
                    geminiKey: $geminiKey,
                    geminiModel: $geminiModel,
                    openaiKey: $openaiKey,
                    openaiModel: $openaiModel,
                    zhipuKey: $zhipuKey,
                    zhipuModel: $zhipuModel
                )
                
                Divider().opacity(0.2)
                
                // Toggle: Apply to Image Mode
                HStack {
                    Text("Image".localized)
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    
                    ElegantToggle(isOn: $applyApiToImageMode)
                    
                    Text("Apply to Image Mode".localized)
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(.secondary.opacity(0.7))
                    
                    Spacer()
                }
            }
            
            // Separate Image API Configuration (shown when toggle is OFF)
            if !applyApiToImageMode {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "API Service (Image)".localized)
                    
                    APIConfigForm(
                        provider: $imageApiProvider,
                        geminiKey: $imageGeminiKey,
                        geminiModel: $imageGeminiModel,
                        openaiKey: $imageOpenaiKey,
                        openaiModel: $imageOpenaiModel,
                        zhipuKey: $imageZhipuKey,
                        zhipuModel: $imageZhipuModel
                    )
                }
            }
            
            Divider().opacity(0.3)
            
            // Window Behavior
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Behavior".localized)
                
                HStack {
                    Text("Close Mode".localized)
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    
                    CustomDropdown(selection: $closeMode, options: ClosingMode.allCases.map { $0.rawValue }, displayNames: ClosingMode.allCases.map { $0.displayName.localized })
                }
                
                Divider().opacity(0.2)
                
                HStack {
                    Text("Improve".localized)
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    
                    ElegantToggle(isOn: $enableImproveFeature)
                    
                    Text("Enable translation improvement".localized)
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(.secondary.opacity(0.7))
                    
                    Spacer()
                }
                
                Divider().opacity(0.2)
                
                HStack {
                    Text("Layout".localized)
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    
                    Button(action: {
                        LayoutEditorManager.shared.openEditor()
                    }) {
                        Text("Customize Popup Layout".localized)
                            .font(.system(size: 13, design: .serif))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

class LayoutEditorManager {
    static let shared = LayoutEditorManager()
    var editorWindow: NSWindow?
    
    func openEditor() {
        editorWindow?.close()
        
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.frame
        
        // Load existing frame or default
        var initialFrame = CGRect(x: screenRect.midX - 200, y: screenRect.midY - 150, width: 400, height: 300)
        
        if let savedData = UserDefaults.standard.data(forKey: "popup_frame_rect"),
           let savedRect = try? JSONDecoder().decode(CGRect.self, from: savedData) {
            // Convert Cocoa (Bottom-Left) to SwiftUI (Top-Left)
            // Cocoa Y is from bottom. SwiftUI Y is from top.
            // swiftUI_Y = screenHeight - (cocoaY + height)
            let swiftUI_Y = screenRect.height - (savedRect.origin.y + savedRect.height)
            initialFrame = CGRect(x: savedRect.origin.x, y: swiftUI_Y, width: savedRect.width, height: savedRect.height)
        } else {
             // Default center (SwiftUI coords)
             // screenRect.midY is center.
             // Top-Left Y = center Y - height/2? No.
             // SwiftUI (0,0) is top-left.
             // Center Y in SwiftUI is screenHeight / 2.
             // So y = screenHeight/2 - 150.
             initialFrame = CGRect(x: screenRect.width/2 - 200, y: screenRect.height/2 - 150, width: 400, height: 300)
        }
        
        let contentView = LayoutEditorView(
            initialFrame: initialFrame,
            screenFrame: CGRect(x: 0, y: 0, width: screenRect.width, height: screenRect.height),
            onSave: { [weak self] frame in
                // Convert SwiftUI (Top-Left) to Cocoa (Bottom-Left)
                // cocoaY = screenHeight - (swiftUI_Y + height)
                let cocoaY = screenRect.height - (frame.origin.y + frame.height)
                let cocoaRect = CGRect(x: frame.origin.x, y: cocoaY, width: frame.width, height: frame.height)
                
                if let data = try? JSONEncoder().encode(cocoaRect) {
                    UserDefaults.standard.set(data, forKey: "popup_frame_rect")
                }
                
                DispatchQueue.main.async {
                    self?.editorWindow?.close()
                    self?.editorWindow = nil
                }
            },
            onCancel: { [weak self] in
                DispatchQueue.main.async {
                    self?.editorWindow?.close()
                    self?.editorWindow = nil
                }
            }
        )
        
        let window = NSWindow(
            contentRect: screenRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        editorWindow = window
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .medium, design: .serif))
            .foregroundColor(AppColors.text.opacity(0.8))
            .textCase(.uppercase)
            .kerning(0.5)
    }
}

struct APIKeyInput: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    var isSecure: Bool = true  // Default to secure (密文)
    
    var body: some View {
        HStack(alignment: .center) {
            Text(label)
                .font(.system(size: 13, design: .serif))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 13))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(AppColors.primary.opacity(0.05))
                    .cornerRadius(4)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColors.primary.opacity(0.1), lineWidth: 0.5))
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 13))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(AppColors.primary.opacity(0.05))
                    .cornerRadius(4)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColors.primary.opacity(0.1), lineWidth: 0.5))
            }
        }
    }
}

struct PromptsSection: View {
    @AppStorage("preset_mode_enabled") private var presetModeEnabled: Bool = false
    @AppStorage("selected_preset_id") private var selectedPresetId: String = DEFAULT_TRANSLATION_PRESET_ID
    @State private var presets: [PromptPreset] = []
    @State private var showEditSheet: Bool = false
    @State private var editingPreset: PromptPreset? // If nil, adding new
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionHeader(title: "Prompts".localized)
            
            // Preset Mode Toggle
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("启用预设模式".localized)
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundColor(.primary)
                    Text("关闭时为临时自定义模式；开启后选择预设".localized)
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                Spacer()
                ElegantToggle(isOn: $presetModeEnabled)
            }
            
            Divider().opacity(0.3)
            
            // Preset Selection (Only visible when preset mode is enabled)
            if presetModeEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    Text("选择预设".localized)
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundColor(.primary)
                    
                    // Default Translation Preset (Built-in)
                    PresetRadioRow(
                        id: DEFAULT_TRANSLATION_PRESET_ID,
                        name: "默认翻译".localized,
                        description: "标准翻译模式，支持 Learned Rules",
                        isSelected: selectedPresetId == DEFAULT_TRANSLATION_PRESET_ID,
                        onSelect: { selectedPresetId = DEFAULT_TRANSLATION_PRESET_ID }
                    )
                    
                    Divider().opacity(0.3)
                    
                    // User Presets Header
                    HStack {
                        Text("自定义预设".localized)
                            .font(.system(size: 12, weight: .medium, design: .serif))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            editingPreset = nil
                            showEditSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                                .padding(5)
                                .background(Color.primary.opacity(0.05))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // User Presets List
                    if presets.isEmpty {
                        Text("暂无自定义预设".localized)
                            .font(.system(size: 12, design: .serif))
                            .foregroundColor(.secondary.opacity(0.6))
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(presets) { preset in
                                PresetRadioRow(
                                    id: preset.id.uuidString,
                                    name: preset.name,
                                    description: "\(preset.inputPerception.prefix(30))...",
                                    isSelected: selectedPresetId == preset.id.uuidString,
                                    onSelect: { selectedPresetId = preset.id.uuidString },
                                    onEdit: {
                                        editingPreset = preset
                                        showEditSheet = true
                                    },
                                    onDelete: { deletePreset(preset) }
                                )
                            }
                        }
                    }
                }
            }
        }
        .onAppear { loadPresets() }
        .sheet(isPresented: $showEditSheet) {
            if let editing = editingPreset {
                PresetEditor(preset: editing, onSave: { updated in
                    updatePreset(updated)
                    showEditSheet = false
                }, onCancel: {
                    showEditSheet = false
                })
            } else {
                PresetEditor(preset: PromptPreset(id: UUID(), name: "", inputPerception: "", outputInstruction: ""), onSave: { new in
                    addPreset(new)
                    showEditSheet = false
                }, onCancel: {
                    showEditSheet = false
                })
            }
        }
    }
    
    private func loadPresets() {
        if let data = UserDefaults.standard.data(forKey: "saved_presets"),
           let decoded = try? JSONDecoder().decode([PromptPreset].self, from: data) {
            presets = decoded
        }
    }
    
    private func addPreset(_ preset: PromptPreset) {
        presets.append(preset)
        persistPresets()
    }
    
    private func updatePreset(_ preset: PromptPreset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
            persistPresets()
        }
    }
    
    private func deletePreset(_ preset: PromptPreset) {
        presets.removeAll { $0.id == preset.id }
        // Reset to default translation if deleting currently selected preset
        if selectedPresetId == preset.id.uuidString {
            selectedPresetId = DEFAULT_TRANSLATION_PRESET_ID
        }
        persistPresets()
    }
    
    private func persistPresets() {
        if let encoded = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(encoded, forKey: "saved_presets")
        }
    }
}

struct PresetRow: View {
    let preset: PromptPreset
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Radio Button
            Button(action: onSelect) {
                Image(systemName: isActive ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 14))
                    .foregroundColor(isActive ? .accentColor : .secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(preset.name)
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundColor(.primary)
                Text(preset.inputPerception.prefix(30) + "...")
                    .font(.system(size: 11, design: .serif))
                    .foregroundColor(.secondary.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .opacity(0.6)
        }
        .padding(10)
        .background(isActive ? Color.accentColor.opacity(0.05) : Color.primary.opacity(0.02))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}

// Radio-style preset row for mode selection
struct PresetRadioRow: View {
    let id: String
    let name: String
    let description: String
    let isSelected: Bool
    let onSelect: () -> Void
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // Swiss Indicator: A small, precise rectangle (Consistent with Sidebar)
            Rectangle()
                .fill(isSelected ? Color.primary : Color.clear)
                .frame(width: 2, height: 12)
                .opacity(isSelected ? 1 : 0)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular, design: .serif))
                    .foregroundColor(.primary)
                Text(description)
                    .font(.system(size: 11, design: .serif))
                    .foregroundColor(.secondary.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Actions (only for user presets)
            if let onEdit = onEdit, let onDelete = onDelete {
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                .opacity(0.6)
            }
        }
        .padding(.vertical, 8) // Increased vertical padding for breathing room
        .padding(.horizontal, 4) // Minimal horizontal padding
        .contentShape(Rectangle()) // Make full row clickable
        .onTapGesture {
            onSelect()
        }
    }
}

struct PresetEditor: View {
    @State private var name: String = ""
    @State private var inputPerception: String = ""
    @State private var outputInstruction: String = ""
    
    let preset: PromptPreset?
    let onSave: (PromptPreset) -> Void
    let onCancel: () -> Void
    
    init(preset: PromptPreset?, onSave: @escaping (PromptPreset) -> Void, onCancel: @escaping () -> Void) {
        self.preset = preset
        self.onSave = onSave
        self.onCancel = onCancel
        
        _name = State(initialValue: preset?.name ?? "")
        _inputPerception = State(initialValue: preset?.inputPerception ?? "")
        _outputInstruction = State(initialValue: preset?.outputInstruction ?? "")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(preset == nil ? "New Preset".localized : "Edit Preset".localized)
                .font(.system(size: 16, weight: .medium, design: .serif))
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name".localized)
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundColor(.secondary)
                    TextField("e.g. Code Audit".localized, text: $name)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(8)
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(6)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Input Perception".localized)
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundColor(.secondary)
                    TextEditor(text: $inputPerception)
                        .font(.system(size: 13))
                        .frame(height: 60)
                        .padding(4)
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(6)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Output Instruction".localized)
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundColor(.secondary)
                    TextEditor(text: $outputInstruction)
                        .font(.system(size: 13))
                        .frame(height: 60)
                        .padding(4)
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(6)
                }
            }
            
            HStack(spacing: 12) {
                Button("Cancel".localized) {
                    onCancel()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("Save".localized) {
                    let newPreset = PromptPreset(
                        id: preset?.id ?? UUID(),
                        name: name.isEmpty ? "Untitled" : name,
                        inputPerception: inputPerception,
                        outputInstruction: outputInstruction
                    )
                    onSave(newPreset)
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(name.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}

struct ShortcutsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Shortcuts".localized)
            
            HStack {
                Text("Activate".localized)
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)
                
                ShortcutRecorder()
            }
            
            HStack {
                Text("Screenshot".localized)
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)
                
                ScreenshotShortcutRecorder()
            }
            
            Text("Press the key combination you want to use.".localized)
                .font(.system(size: 12, design: .serif))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.top, 4)
        }
    }
}

struct LearnedRulesSection: View {
    @State private var rules: [UserLearnedRule] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Learned Rules".localized)
            
            Text("Translation rules learned from your corrections.".localized)
                .font(.system(size: 13, design: .serif))
                .foregroundColor(.secondary)
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Spacer()
                }
                .padding()
            } else if rules.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text("No rules learned yet".localized)
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundColor(.secondary)
                    Text("Edit translations and click Improve to start learning.".localized)
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(rules) { rule in
                        RuleCard(rule: rule, onDelete: {
                            deleteRule(rule)
                        })
                    }
                }
            }
        }
        .onAppear {
            loadRules()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LearnedRuleAdded"))) { _ in
            loadRules()
        }
    }
    
    private func loadRules() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedRules = LearningManager.shared.getAllRules()
            DispatchQueue.main.async {
                rules = loadedRules
                isLoading = false
            }
        }
    }
    
    private func deleteRule(_ rule: UserLearnedRule) {
        do {
            try LearningManager.shared.deleteRule(id: rule.id)
            print("DEBUG: Successfully deleted rule: \(rule.id)")
            loadRules()
        } catch {
            print("ERROR: Failed to delete rule: \(error)")
        }
    }
}

struct RuleCard: View {
    let rule: UserLearnedRule
    let onDelete: () -> Void
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(rule.category.displayName)
                            .font(.system(size: 11, weight: .medium, design: .serif))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(3)
                        
                        Text(formatDate(rule.createdAt))
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    
                    Text(rule.reasoning)
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(.primary)
                        .lineLimit(isExpanded ? nil : 2)
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                Divider().opacity(0.3)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Original:".localized)
                            .font(.system(size: 11, weight: .medium, design: .serif))
                            .foregroundColor(.secondary)
                        Text(rule.originalText)
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    
                    HStack {
                        Text("AI:".localized)
                            .font(.system(size: 11, weight: .medium, design: .serif))
                            .foregroundColor(.secondary)
                        Text(rule.aiTranslation)
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    
                    HStack {
                        Text("Your correction:".localized)
                            .font(.system(size: 11, weight: .medium, design: .serif))
                            .foregroundColor(.secondary)
                        Text(rule.userCorrection)
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }
            }
            
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(isExpanded ? "Show less".localized : "Show more".localized)
                        .font(.system(size: 11, design: .serif))
                        .foregroundColor(.secondary.opacity(0.7))
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.primary.opacity(0.02))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

extension RuleCategory {
    var displayName: String {
        switch self {
        case .attributeToVerb: return "Attribute→Verb"
        case .metaphor: return "Metaphor"
        case .terminology: return "Terminology"
        case .style: return "Style"
        case .other: return "Other"
        }
    }
}

struct CustomDropdown: View {
    @Binding var selection: String
    let options: [String]
    var displayNames: [String]? = nil
    
    @State private var isExpanded = false
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selection = option
                }) {
                    Text(displayName(for: option))
                }
            }
        } label: {
            HStack {
                Text(displayName(for: selection))
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(.primary)
                Spacer()
                // Removed redundant chevron
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .frame(width: 160)
            .background(AppColors.primary.opacity(0.05))
            .cornerRadius(4)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColors.primary.opacity(0.1), lineWidth: 0.5))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
    
    private func displayName(for option: String) -> String {
        if let displayNames = displayNames, let index = options.firstIndex(of: option) {
            return displayNames[index]
        }
        return option
    }
}

struct ElegantToggle: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isOn.toggle()
            }
        }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isOn ? AppColors.primary : AppColors.primary.opacity(0.15))
                    .frame(width: 32, height: 18)
                
                Circle()
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .padding(2)
                    .frame(width: 18, height: 18)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ShortcutRecorder: View {
    @State private var isRecording = false
    @State private var currentShortcut: String = ""
    @State private var monitor: Any?
    
    var body: some View {
        Button(action: {
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        }) {
            HStack {
                if isRecording {
                    Text("Press keys...".localized)
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(.accentColor)
                    Spacer()
                    Image(systemName: "record.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)
                        .symbolEffect(.pulse)
                } else {
                    Text(currentShortcut.isEmpty ? "Record Shortcut".localized : currentShortcut)
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(.primary)
                    Spacer()
                    if !currentShortcut.isEmpty {
                        Button(action: {
                            resetShortcut()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .frame(width: 160)
            .background(isRecording ? AppColors.primary.opacity(0.1) : AppColors.primary.opacity(0.05))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isRecording ? AppColors.primary.opacity(0.3) : AppColors.primary.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            updateDisplay()
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        // Add a local monitor to capture keys
        // We use .keyDown to capture the combination
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyDown(event)
            return nil // Consume the event
        }
    }
    
    private func stopRecording() {
        isRecording = false
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
    
    private func resetShortcut() {
        GlobalShortcutManager.shared.updateShortcut(keyCode: 16, modifiers: [.command, .control])
        updateDisplay()
    }
    
    private func updateDisplay() {
        let keyCode = UserDefaults.standard.integer(forKey: "global_shortcut_key")
        let modifiers = UserDefaults.standard.integer(forKey: "global_shortcut_modifiers")
        
        if keyCode != 0 {
            currentShortcut = shortcutString(keyCode: UInt16(keyCode), modifiers: NSEvent.ModifierFlags(rawValue: UInt(modifiers)))
        } else {
            currentShortcut = "⌘⌃Y" // Default
        }
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode
        
        // Ignore standalone modifier presses
        if event.type == .flagsChanged {
            return
        }
        
        // Escape to cancel
        if keyCode == 53 {
            stopRecording()
            return
        }
        
        // Save shortcut
        GlobalShortcutManager.shared.updateShortcut(keyCode: keyCode, modifiers: flags)
        updateDisplay()
        stopRecording()
    }
    
    private func shortcutString(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> String {
        var string = ""
        if modifiers.contains(.command) { string += "⌘" }
        if modifiers.contains(.control) { string += "⌃" }
        if modifiers.contains(.option) { string += "⌥" }
        if modifiers.contains(.shift) { string += "⇧" }
        
        // Simple key mapping
        switch keyCode {
        case 0: string += "A"
        case 1: string += "S"
        case 2: string += "D"
        case 3: string += "F"
        case 4: string += "H"
        case 5: string += "G"
        case 6: string += "Z"
        case 7: string += "X"
        case 8: string += "C"
        case 9: string += "V"
        case 11: string += "B"
        case 12: string += "Q"
        case 13: string += "W"
        case 14: string += "E"
        case 15: string += "R"
        case 16: string += "Y"
        case 17: string += "T"
        case 18: string += "1"
        case 19: string += "2"
        case 20: string += "3"
        case 21: string += "4"
        case 22: string += "6"
        case 23: string += "5"
        case 24: string += "="
        case 25: string += "9"
        case 26: string += "7"
        case 27: string += "-"
        case 28: string += "8"
        case 29: string += "0"
        case 30: string += "]"
        case 31: string += "O"
        case 32: string += "U"
        case 33: string += "["
        case 34: string += "I"
        case 35: string += "P"
        case 37: string += "L"
        case 38: string += "J"
        case 39: string += "'"
        case 40: string += "K"
        case 41: string += ";"
        case 42: string += "\\"
        case 43: string += ","
        case 44: string += "/"
        case 45: string += "N"
        case 46: string += "M"
        case 47: string += "."
        case 50: string += "`"
        default: string += "?"
        }
        
        return string
    }
}

