import Cocoa
import SwiftUI

struct TranslationView: View {
    @State var originalText: String
    var errorMessage: String?
    @State private var translatedText: String = ""
    @State private var isTranslating: Bool = false
    @State private var sourceLanguage: Language
    @State private var targetLanguage: Language
    @FocusState private var isInputFocused: Bool
    @AppStorage("close_mode") private var closeMode: String = "clickOutside"
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var isEditingTranslation: Bool = false
    @State private var editedTranslation: String = ""
    @State private var isImproving: Bool = false
    @State private var originalAiTranslation: String = ""
    @State private var savedOriginalText: String = ""
    @AppStorage("enable_improve_feature") private var enableImproveFeature: Bool = false
    @State private var showAnalysisResult: Bool = false
    @State private var analysisReasoning: String = ""
    @State private var showImproveSuccess: Bool = false
    
    @AppStorage("enable_custom_mode_popup") private var enableCustomModePopup: Bool = false  // Legacy, now="preset_mode_enabled"
    @AppStorage("preset_mode_enabled") private var presetModeEnabled: Bool = false
    @AppStorage("selected_preset_id") private var selectedPresetId: String = DEFAULT_TRANSLATION_PRESET_ID
    @State private var customInputPerception: String = ""
    @State private var customOutputInstruction: String = ""
    @State private var inputPerceptionHeight: CGFloat = 24
    @State private var outputInstructionHeight: CGFloat = 24
    
    // Computed property for dynamic output placeholder
    var outputPlaceholder: String {
        let mode = determineMode()
        switch mode {
        case .defaultTranslation:
            return "翻译结果将显示在这里...".localized
        case .temporaryCustom:
            return "处理结果将显示在这里...".localized
        case .userPreset:
            return "输出结果将显示在这里...".localized
        }
    }
    
    // Determine current mode based on settings
    func determineMode() -> PromptMode {
        if !presetModeEnabled {
            return .temporaryCustom
        }
        
        if selectedPresetId == DEFAULT_TRANSLATION_PRESET_ID {
            return .defaultTranslation
        }
        
        // Find user preset
        if let data = UserDefaults.standard.data(forKey: "saved_presets"),
           let presets = try? JSONDecoder().decode([PromptPreset].self, from: data),
           let selectedUUID = UUID(uuidString: selectedPresetId),
           let preset = presets.first(where: { $0.id == selectedUUID }) {
            return .userPreset(preset)
        }
        
        return .defaultTranslation  // fallback
    }
    
    init(originalText: String, errorMessage: String? = nil) {
        self.originalText = originalText
        self.errorMessage = errorMessage
        
        let defaultSource = UserDefaults.standard.string(forKey: "default_source_language") ?? Language.auto.rawValue
        let defaultTarget = UserDefaults.standard.string(forKey: "default_target_language") ?? Language.simplifiedChinese.rawValue
        
        _sourceLanguage = State(initialValue: Language(rawValue: defaultSource) ?? .auto)
        _targetLanguage = State(initialValue: Language(rawValue: defaultTarget) ?? .simplifiedChinese)
    }
    
    var body: some View {
        VStack(spacing: 0) {

            
            // Custom Mode Input Fields (Only visible in Temporary Custom Mode)
            if determineMode() == .temporaryCustom {
                VStack(alignment: .leading, spacing: 16) {
                    // Narrative Input Structure
                    HStack(alignment: .top, spacing: 6) {
                        Text("I perceive this as")
                            .font(.system(size: 16, weight: .light, design: .serif))
                            .foregroundColor(.secondary)
                            // .padding(.top, 2) Removed for alignment with zero-inset editor
                        
                        NarrativeTextField(
                            text: $customInputPerception,
                            height: $inputPerceptionHeight,
                            placeholder: "Ancient Poetry"
                        )
                        .frame(minWidth: 120)
                        
                        Text(",")
                            .font(.system(size: 16, weight: .light, design: .serif))
                            .foregroundColor(.secondary)
                            // .padding(.top, 2)
                    }
                    
                    HStack(alignment: .top, spacing: 6) {
                        Text("please")
                            .font(.system(size: 16, weight: .light, design: .serif))
                            .foregroundColor(.secondary)
                            // .padding(.top, 2)
                        
                        NarrativeTextField(
                            text: $customOutputInstruction,
                            height: $outputInstructionHeight,
                            placeholder: "translate to modern English"
                        )
                        .frame(minWidth: 180)
                        
                        Text(".")
                            .font(.system(size: 16, weight: .light, design: .serif))
                            .foregroundColor(.secondary)
                            // .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .padding(.trailing, closeMode == "xButton" ? 40 : 0) // Reserve space for gravity orb
                .background(Color.primary.opacity(0.01)) // Almost invisible background
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: inputPerceptionHeight)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: outputInstructionHeight)
            }
            
            Divider().opacity(0.3)

            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                    Text(errorMessage).font(.system(size: 13, weight: .medium)).foregroundColor(.primary)
                    Spacer()
                    Button("Open Settings".localized) {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    }.buttonStyle(.borderedProminent).controlSize(.small)
                }.padding().background(Color.orange.opacity(0.1))
            }
            
            // Analysis Result Banner - REMOVED
            

            
            Divider().opacity(0.5)
            
            // Language Selectors - Top Position (Only in Default Translation Mode)
            if determineMode() == .defaultTranslation {
                HStack {
                    HStack(spacing: 8) {
                        LanguageSelector(selection: $sourceLanguage, languages: Language.sourceLanguages)
                        
                        Button(action: swapLanguages) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                        .help("Swap languages".localized)
                        
                        LanguageSelector(selection: $targetLanguage, languages: Language.targetLanguages)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.02))
                .transition(.opacity)
            }
            
            Divider().opacity(0.3)
            
            // Main Content Area - Consistent Custom Editors
            HStack(spacing: 0) {
                CustomTextEditor(text: $originalText, placeholder: "Type or paste text..".localized)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Rectangle().fill(Color.primary.opacity(0.05)).frame(width: 1)
                
                // Output area - Using CustomTextEditor for consistency
                ZStack(alignment: .topLeading) {
                    if isEditingTranslation {
                        CustomTextEditor(text: $editedTranslation, placeholder: outputPlaceholder)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        MacEditorView(text: .constant(translatedText))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(isTranslating ? 0 : 1) // Hide text while translating to prevent overlap
                            .overlay(alignment: .topLeading) {
                                Group {
                                    if isTranslating {
                                        HarmonicFlowView(text: originalText)
                                            .padding(.horizontal, 25)
                                            .padding(.vertical, 20)
                                    } else if translatedText.isEmpty {
                                        Text(outputPlaceholder)
                                            .font(.system(size: 16, weight: .light, design: .serif))
                                            .foregroundColor(.secondary.opacity(0.5))
                                            .padding(.horizontal, 25)
                                            .padding(.vertical, 20)
                                            .allowsHitTesting(false)
                                    }
                                }
                                .clipped() // Ensure content doesn't overflow the output box
                            }
                    }
                }
                .background(Color.primary.opacity(0.02))
            }
            
            // Bottom Bar
            HStack {
                
                Spacer()
                
                // Right Side: Actions
                HStack(spacing: 12) {
                    // Yisi Button (The Living Verb)
                    YisiButton(isLoading: isTranslating || isImproving) {
                        Task { await performTranslation() }
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                }
            }.padding(16).background(Color.primary.opacity(0.03))
        }.background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
        .overlay(alignment: .topTrailing) {
            if closeMode == "xButton" {
                CloseButton {
                    WindowManager.shared.close()
                }
                .padding(8) // Move closer to the edge (was 12)
                .offset(x: 4, y: -4) // Push slightly out
                .transition(.scale.combined(with: .opacity))
            }
        }
        .background(WindowAccessor(window: $window))
        .onExitCommand {
            if closeMode == "escKey" {
                WindowManager.shared.close()
            }
        }.task {
            // Only auto-translate if NOT in custom mode
            // In custom mode, user needs to input their requirements first
            if !originalText.isEmpty && determineMode() != .temporaryCustom {
                await performTranslation()
            }
        }
        .onChange(of: inputPerceptionHeight) { newValue in
            adjustWindowHeight(delta: newValue - 24) // 24 is base height
        }
        .onChange(of: outputInstructionHeight) { newValue in
            adjustWindowHeight(delta: newValue - 24)
        }
    }
    
    @State private var window: NSWindow?
    @State private var lastInputHeight: CGFloat = 24
    @State private var lastOutputHeight: CGFloat = 24
    
    private func adjustWindowHeight(delta: CGFloat) {
        guard let window = window else { return }
        
        // Calculate total delta based on both fields
        // We need to track the previous height to know the incremental change
        // But here we are getting the absolute height from the binding
        
        // Better approach:
        // Calculate total desired height of inputs
        let totalInputHeight = inputPerceptionHeight + outputInstructionHeight
        let baseInputHeight: CGFloat = 48 // 24 + 24
        
        // The growth needed
        // The growth needed
        // let growth = totalInputHeight - baseInputHeight
        
        // We also need to know the current window height to apply the difference?
        // No, we should probably just resize the window based on the content change.
        // But SwiftUI updates happen frequently.
        
        // Let's rely on the fact that we want the window to grow by the *change* in height.
        // We need to store the previous total height.
        
        let currentTotal = inputPerceptionHeight + outputInstructionHeight
        let previousTotal = lastInputHeight + lastOutputHeight
        let diff = currentTotal - previousTotal
        
        if diff != 0 {
            var frame = window.frame
            frame.size.height += diff
            frame.origin.y -= diff // Grow upwards (Cocoa coords) or downwards?
            // Cocoa origin is bottom-left.
            // To grow downwards (keeping top fixed), we need to decrease origin.y by the growth amount.
            // To grow upwards (keeping bottom fixed), we just increase height.
            // Usually we want to grow downwards for a dropdown/input at top.
            
            window.setFrame(frame, display: true, animate: true)
            
            lastInputHeight = inputPerceptionHeight
            lastOutputHeight = outputInstructionHeight
        }
    }
    
    private func performTranslation() async {
        guard !originalText.isEmpty else { return }
        isTranslating = true
        do {
            let mode = determineMode()
            
            translatedText = try await AIService.shared.processText(
                originalText,
                mode: mode,
                sourceLanguage: sourceLanguage.rawValue, 
                targetLanguage: targetLanguage.rawValue,
                userPerception: mode == .temporaryCustom ? customInputPerception : nil,
                userInstruction: mode == .temporaryCustom ? customOutputInstruction : nil
            )
            savedOriginalText = originalText  // Save for improve feature
        } catch {
            print("❌ TRANSLATION ERROR:")
            print("   Error: \(error)")
            print("   Localized: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("   Domain: \(nsError.domain)")
                print("   Code: \(nsError.code)")
                print("   UserInfo: \(nsError.userInfo)")
            }
            translatedText = "Error: \(error.localizedDescription)"
        }
        isTranslating = false
    }
    
    
    private func improveWithAI() async {
        print("DEBUG: improveWithAI called")
        guard !savedOriginalText.isEmpty && !originalAiTranslation.isEmpty && !editedTranslation.isEmpty else {
            print("DEBUG: Missing data for improve: original=\(savedOriginalText.isEmpty), ai=\(originalAiTranslation.isEmpty), edited=\(editedTranslation.isEmpty)")
            return
        }
        isImproving = true
        print("DEBUG: Starting analysis...")
        do {
            let rule = try await LearningManager.shared.analyzeCorrection(
                originalText: savedOriginalText,
                aiTranslation: originalAiTranslation,
                userCorrection: editedTranslation
            )
            print("DEBUG: Analysis complete. Rule received: \(rule.id)")
            
            // Successfully saved rule, update UI
            await MainActor.run {
                print("DEBUG: Updating UI on MainActor")
                translatedText = editedTranslation
                isEditingTranslation = false
                editedTranslation = ""
                
                // Show success indicator
                showImproveSuccess = true
                
                // Post notification to refresh Settings
                NotificationCenter.default.post(name: NSNotification.Name("LearnedRuleAdded"), object: nil)
                
                // Auto-hide after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showImproveSuccess = false
                    }
                }
            }
        } catch {
            // Show error in console
            print("Failed to improve: \(error.localizedDescription)")
            if let data = (error as NSError).userInfo["data"] as? Data,
               let jsonString = String(data: data, encoding: .utf8) {
                print("Raw response: \(jsonString)")
            }
        }
        isImproving = false
    }
    
    private func swapLanguages() {
        if sourceLanguage == .auto {
            sourceLanguage = targetLanguage
            targetLanguage = .english
        } else {
            let temp = sourceLanguage
            // Ensure the target language is valid for source (always true as source is superset)
            // Ensure the source language is valid for target (Auto is not valid target)
            if temp == .auto {
                 // Should be covered by first if, but for safety
                 sourceLanguage = targetLanguage
                 targetLanguage = .english
            } else {
                // Check if the current source is a valid target (it should be unless it's auto)
                if Language.targetLanguages.contains(temp) {
                     sourceLanguage = targetLanguage
                     targetLanguage = temp
                } else {
                    // Fallback if something weird happens
                    sourceLanguage = targetLanguage
                    targetLanguage = .english
                }
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

struct CustomTextEditor: View {
    @Binding var text: String
    var placeholder: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            MacEditorView(text: $text)
                .focused($isFocused)
            
            // Hide placeholder if text is not empty OR if the field is focused (to prevent overlap with input method candidates)
            if text.isEmpty && !isFocused {
                Text(placeholder)
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .foregroundColor(.secondary.opacity(0.5))
                    .padding(.horizontal, 25)
                    .padding(.vertical, 20)
                    .allowsHitTesting(false)
            }
        }.background(Color.clear)
        .onTapGesture {
            isFocused = true
        }
    }
}



struct MacEditorView: NSViewRepresentable {
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.contentView.drawsBackground = false
        scrollView.contentView.backgroundColor = .clear
        scrollView.wantsLayer = true
        scrollView.layer?.backgroundColor = NSColor.clear.cgColor
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        
        // Use custom transparent scroller
        scrollView.verticalScroller = TransparentScroller()
        scrollView.verticalScroller?.controlSize = .mini

        let textView = NSTextView()
        textView.autoresizingMask = [.width, .height]
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.font = AppFont.shared.font
        textView.textColor = .labelColor
        textView.isRichText = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainerInset = NSSize(width: 20, height: 20)
        textView.delegate = context.coordinator
        scrollView.documentView = textView
        return scrollView
    }
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            _text = text
        }
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
        }
    }
}

struct OutputTextView: NSViewRepresentable {
    let text: String
    let isEmpty: Bool

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.contentView.drawsBackground = false
        scrollView.contentView.backgroundColor = .clear
        scrollView.wantsLayer = true
        scrollView.layer?.backgroundColor = NSColor.clear.cgColor
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        
        // Use custom transparent scroller
        scrollView.verticalScroller = TransparentScroller()
        scrollView.verticalScroller?.controlSize = .mini

        let textView = NSTextView()
        textView.autoresizingMask = [.width, .height]
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isSelectable = true

        textView.font = AppFont.shared.font

        textView.textColor = .labelColor
        textView.isRichText = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainerInset = NSSize(width: 20, height: 20)
        textView.textContainerInset = NSSize(width: 20, height: 20)
        textView.string = isEmpty ? "Translation will appear here...".localized : text

        if isEmpty {
            textView.textColor = .secondaryLabelColor
        }

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        textView.string = isEmpty ? "Translation will appear here...".localized : text
        textView.textColor = isEmpty ? .secondaryLabelColor : .labelColor
    }
}

struct LanguageSelector: View {
    @Binding var selection: Language
    let languages: [Language]
    
    var body: some View {
        Menu {
            ForEach(languages) { language in
                Button(language.displayName) {
                    selection = language
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selection.displayName).font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
            }
        }.menuStyle(.borderlessButton).fixedSize()
    }
}

struct LanguageButton: View {
    let text: String
    var body: some View {
        Text(text).font(.system(size: 12, weight: .medium)).foregroundColor(.secondary).padding(.horizontal, 8).padding(.vertical, 4).background(Color.primary.opacity(0.05)).cornerRadius(4)
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
// Add this component after OutputTextView and before LanguageSelector in TranslationView.swift

struct EditableOutputView: NSViewRepresentable {
    @Binding var text: String
    let originalText: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.contentView.drawsBackground = false
        scrollView.contentView.backgroundColor = .clear
        scrollView.wantsLayer = true
        scrollView.layer?.backgroundColor = NSColor.clear.cgColor
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        
        scrollView.verticalScroller = TransparentScroller()
        scrollView.verticalScroller?.controlSize = .mini

        let textView = NSTextView()
        textView.autoresizingMask = [.width, .height]
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.isEditable = true
        textView.isSelectable = true

        textView.font = AppFont.shared.font

        textView.textColor = .labelColor
        textView.isRichText = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainerInset = NSSize(width: 20, height: 20)
        textView.string = text
        textView.delegate = context.coordinator

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            _text = text
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
        }
    }
}



struct CloseButton: View {
    let action: () -> Void
    @State private var isHovering: Bool = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .medium)) // Slightly larger for better clickability
                .foregroundColor(.secondary)
                .opacity(isHovering ? 1.0 : 0.4) // Ghostly when idle, solid when hovered
                .scaleEffect(isHovering ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
                .frame(width: 24, height: 24) // Touch target remains accessible
                .contentShape(Rectangle()) // Ensure the whole frame is clickable
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// A custom text field that looks like a blank line in a sentence


struct YisiButton: View {
    let isLoading: Bool
    let action: () -> Void
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(isLoading ? 0.1 : 0.8))
                    .animation(.easeInOut(duration: 0.3), value: isLoading)
                
                // Text "Yisi"
                Text("Yisi")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundColor(isLoading ? Color.primary : Color(nsColor: .windowBackgroundColor))
                    // Breathing Animation
                    .opacity(isLoading ? 0.5 : 1)
                    .scaleEffect(isLoading ? 0.95 : 1)
                    .animation(isLoading ? Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: isLoading)
            }
            .frame(width: 60, height: 28)
            .shadow(color: Color.black.opacity(isHovering && !isLoading ? 0.1 : 0), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct NarrativeTextField: View {
    @Binding var text: String
    @Binding var height: CGFloat
    var placeholder: String
    
    var body: some View {
        DynamicHeightTextEditor(
            text: $text,
            height: $height,
            placeholder: placeholder,
            font: AppFont.shared.font
        )
        .frame(height: height)
    }
}

struct AppFont {
    static let shared = AppFont()
    let font: NSFont
    
    private init() {
        let descriptor = NSFont.systemFont(ofSize: 16, weight: .light).fontDescriptor.withDesign(.serif)
        if let descriptor = descriptor {
            self.font = NSFont(descriptor: descriptor, size: 16) ?? .systemFont(ofSize: 16, weight: .light)
        } else {
            self.font = .systemFont(ofSize: 16, weight: .light)
        }
    }
}

struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?
    
    func makeNSView(context: Context) -> NSView {
        let view = WindowAccessorView()
        view.onWindowChange = { [weak view] in
            self.window = view?.window
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    class WindowAccessorView: NSView {
        var onWindowChange: (() -> Void)?
        
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            onWindowChange?()
        }
    }
}
