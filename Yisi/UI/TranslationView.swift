import SwiftUI

struct TranslationView: View {
    @State var originalText: String
    @State private var translatedText: String = ""
    @State private var isTranslating: Bool = false
    @State private var sourceLanguage: String = "English"
    @State private var targetLanguage: String = "简体中文"
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Original Text Area
            ZStack(alignment: .topLeading) {
                if originalText.isEmpty {
                    Text("Type to translate...")
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                
                TextEditor(text: $originalText)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .lineSpacing(4)
                    .foregroundColor(.primary.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .scrollContentBackground(.hidden) // Remove default background
                    .focused($isInputFocused)
                    .onChange(of: originalText) {
                        // Optional: Debounce auto-translate if desired, 
                        // but for now we stick to explicit trigger or initial load
                    }
                    // Handle Command+Enter to translate
                    .onReceive(NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification)) { obj in
                         // This is a bit hacky in SwiftUI for key events in TextEditor.
                         // A better way is usually using an NSViewRepresentable for NSTextView
                         // to handle keyDown events properly.
                         // For simplicity in this iteration, we'll rely on a button or the initial load.
                    }
            }
            .padding(15)
            .frame(height: 150)
            
            Divider()
                .background(Color.primary.opacity(0.1))
            
            // Translated Text Area
            ScrollView {
                if isTranslating {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(height: 50)
                        Spacer()
                    }
                } else {
                    Text(translatedText)
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .lineSpacing(4)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .textSelection(.enabled)
                        .onTapGesture {
                            copyToClipboard(translatedText)
                        }
                }
            }
            .frame(maxHeight: 300)
            
            // Footer / Controls
            HStack {
                LanguageButton(text: sourceLanguage)
                
                Button(action: swapLanguages) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                
                LanguageButton(text: targetLanguage)
                
                Spacer()
                
                if originalText.isEmpty || !translatedText.isEmpty {
                    Text("Esc to close")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.5))
                } else {
                    Button("Translate") {
                        Task { await performTranslation() }
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.primary.opacity(0.03))
        }
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .task {
            if !originalText.isEmpty {
                await performTranslation()
            } else {
                isInputFocused = true
            }
        }
    }
    
    private func performTranslation() async {
        guard !originalText.isEmpty else { return }
        isTranslating = true
        do {
            translatedText = try await TranslationService.shared.translate(originalText, targetLanguage: targetLanguage)
        } catch {
            translatedText = "Error: \(error.localizedDescription)"
        }
        isTranslating = false
    }
    
    private func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp
        if !originalText.isEmpty {
            Task {
                await performTranslation()
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

struct LanguageButton: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(4)
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
