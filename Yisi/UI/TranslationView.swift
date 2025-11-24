import SwiftUI

struct TranslationView: View {
    @State var originalText: String
    var errorMessage: String? // Added error message property
    
    @State private var translatedText: String = ""
    @State private var isTranslating: Bool = false
    @State private var sourceLanguage: String = "English"
    @State private var targetLanguage: String = "简体中文"
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Permission Warning
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    Button("Open Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
            }
            
            // Main Content Area
            HStack(spacing: 0) {
                // Left: Input
                VStack(alignment: .leading, spacing: 12) {
                    LanguageSelector(selection: $sourceLanguage)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    CustomTextEditor(text: $originalText, placeholder: "Type or paste text...")
                        .font(.system(size: 16, weight: .light, design: .serif))
                        .padding(.horizontal, 15)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Divider
                Rectangle()
                    .fill(Color.primary.opacity(0.05))
                    .frame(width: 1)
                    .padding(.vertical, 20)
                
                // Right: Output
                VStack(alignment: .leading, spacing: 12) {
                    LanguageSelector(selection: $targetLanguage)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    ScrollView {
                        Text(translatedText.isEmpty ? "Translation will appear here..." : translatedText)
                            .font(.system(size: 16, weight: .light, design: .serif))
                            .foregroundColor(translatedText.isEmpty ? .secondary.opacity(0.5) : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.primary.opacity(0.02))
            }
            
            // Footer
            HStack {
                if isTranslating {
                    ProgressView()
                        .scaleEffect(0.6)
                        .padding(.trailing, 8)
                }
                
                Spacer()
                
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(translatedText, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
                .opacity(translatedText.isEmpty ? 0 : 1)
                
                Button(action: { Task { await performTranslation() } }) {
                    Text("Translate")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.primary.opacity(0.8))
                        .foregroundColor(Color(nsColor: .windowBackgroundColor))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(16)
            .background(Color.primary.opacity(0.03))
        }
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .onExitCommand {
            WindowManager.shared.close()
        }
        .task {
            if !originalText.isEmpty {
                await performTranslation()
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
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

struct CustomTextEditor: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.secondary.opacity(0.5))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 0)
            }
            
            TextEditor(text: $text)
                .scrollContentBackground(.hidden) // Removes white background
                .background(Color.clear)
        }
    }
}

struct LanguageSelector: View {
    @Binding var selection: String
    
    var body: some View {
        Menu {
            Button("English") { selection = "English" }
            Button("简体中文") { selection = "简体中文" }
            Button("Japanese") { selection = "Japanese" }
            Button("French") { selection = "French" }
            Button("Spanish") { selection = "Spanish" }
        } label: {
            HStack(spacing: 4) {
                Text(selection)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
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
