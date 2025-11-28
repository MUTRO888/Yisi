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
            HStack(spacing: 12) {
                LanguageSelector(selection: $sourceLanguage, languages: Language.sourceLanguages)
                
                Button(action: swapLanguages) {
                    Image(systemName: "arrow.right.arrow.left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .help("Swap languages".localized)
                
                LanguageSelector(selection: $targetLanguage, languages: Language.targetLanguages)
                Spacer()
            }.padding(.horizontal, 16).padding(.vertical, 12).background(Color.black.opacity(0.2))
            
            // Close button for X mode
            if closeMode == "xButton" {
                HStack {
                    Spacer()
                    Button(action: {
                        WindowManager.shared.close()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }
                .frame(height: 0) // Zero height to overlay without taking space
                .offset(y: -20) // Adjust position to be in the corner
                .zIndex(100)
            }

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

            
            HStack(spacing: 0) {
                CustomTextEditor(text: $originalText, placeholder: "Type or paste text...".localized).frame(maxWidth: .infinity, maxHeight: .infinity)
                Rectangle().fill(Color.primary.opacity(0.05)).frame(width: 1)
                
                if isEditingTranslation {
                    EditableOutputView(text: $editedTranslation, originalText: translatedText).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.primary.opacity(0.02))
                } else {
                    OutputTextView(text: translatedText, isEmpty: translatedText.isEmpty).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.primary.opacity(0.02))
                }
            }
            HStack {
                if isTranslating || isImproving {
                    ProgressView().scaleEffect(0.6).padding(.trailing, 8)
                } else if showImproveSuccess {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                        Text("Success".localized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.trailing, 8)
                    .transition(.opacity)
                }
                Spacer()
                
                // Edit button (only if improve feature is enabled)
                if enableImproveFeature && !translatedText.isEmpty && !isEditingTranslation {
                    Button(action: {
                        isEditingTranslation = true
                        editedTranslation = translatedText
                        originalAiTranslation = translatedText
                    }) {
                        Text("Edit".localized).font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                    }.buttonStyle(.plain).padding(.trailing, 12)
                }
                
                // Save or Cancel buttons when editing
                if isEditingTranslation {
                    Button(action: {
                        isEditingTranslation = false
                        editedTranslation = ""
                    }) {
                        Text("Cancel".localized).font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                    }.buttonStyle(.plain).padding(.trailing, 12)
                }
                
                // Improve button (only show when edited and different from original)
                if isEditingTranslation && editedTranslation != originalAiTranslation && !editedTranslation.isEmpty {
                    Button(action: { Task { await improveWithAI() } }) {
                        Text("Improve".localized).font(.system(size: 13, weight: .medium)).padding(.horizontal, 12).padding(.vertical, 5).background(Color.blue.opacity(0.1)).foregroundColor(.blue).cornerRadius(5)
                    }.buttonStyle(.plain).padding(.trailing, 12)
                }
                
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(isEditingTranslation ? editedTranslation : translatedText, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc").font(.system(size: 12)).foregroundColor(.secondary)
                }.buttonStyle(.plain).padding(.trailing, 16).opacity(translatedText.isEmpty ? 0 : 1)
                
                Button(action: { Task { await performTranslation() } }) {
                    Text("Translate".localized).font(.system(size: 13, weight: .medium)).padding(.horizontal, 16).padding(.vertical, 6).background(Color.primary.opacity(0.8)).foregroundColor(Color(nsColor: .windowBackgroundColor)).cornerRadius(6)
                }.buttonStyle(.plain).keyboardShortcut(.return, modifiers: .command)
            }.padding(16).background(Color.primary.opacity(0.03))
        }.background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.1), lineWidth: 0.5)).onExitCommand {
            if closeMode == "escKey" {
                WindowManager.shared.close()
            }
        }.task {
            if !originalText.isEmpty {
                await performTranslation()
            }
        }
    }
    
    private func performTranslation() async {
        guard !originalText.isEmpty else { return }
        isTranslating = true
        do {
            translatedText = try await TranslationService.shared.translate(originalText, sourceLanguage: sourceLanguage.rawValue, targetLanguage: targetLanguage.rawValue)
            savedOriginalText = originalText  // Save for improve feature
        } catch {
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

// Custom scroller that removes the background track
class TransparentScroller: NSScroller {
    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        // Override to prevent drawing the white background track
        // We only want to draw the knob itself, not the track background
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
        let descriptor = NSFont.systemFont(ofSize: 16, weight: .light).fontDescriptor.withDesign(.serif)
        if let descriptor = descriptor {
            textView.font = NSFont(descriptor: descriptor, size: 16)
        } else {
            textView.font = .systemFont(ofSize: 16, weight: .light)
        }
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

        let descriptor = NSFont.systemFont(ofSize: 16, weight: .light).fontDescriptor.withDesign(.serif)
        if let descriptor = descriptor {
            textView.font = NSFont(descriptor: descriptor, size: 16)
        } else {
            textView.font = .systemFont(ofSize: 16, weight: .light)
        }

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

        let descriptor = NSFont.systemFont(ofSize: 16, weight: .light).fontDescriptor.withDesign(.serif)
        if let descriptor = descriptor {
            textView.font = NSFont(descriptor: descriptor, size: 16)
        } else {
            textView.font = .systemFont(ofSize: 16, weight: .light)
        }

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
