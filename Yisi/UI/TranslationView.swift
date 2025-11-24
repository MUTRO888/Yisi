import Cocoa
import SwiftUI

struct TranslationView: View {
    @State var originalText: String
    var errorMessage: String?
    @State private var translatedText: String = ""
    @State private var isTranslating: Bool = false
    @State private var sourceLanguage: String = "English"
    @State private var targetLanguage: String = "简体中文"
    @FocusState private var isInputFocused: Bool
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                LanguageSelector(selection: $sourceLanguage)
                Image(systemName: "arrow.right").font(.system(size: 12, weight: .medium)).foregroundColor(.secondary.opacity(0.5))
                LanguageSelector(selection: $targetLanguage)
                Spacer()
            }.padding(.horizontal, 16).padding(.vertical, 12).background(Color.black.opacity(0.2))
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                    Text(errorMessage).font(.system(size: 13, weight: .medium)).foregroundColor(.primary)
                    Spacer()
                    Button("Open Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    }.buttonStyle(.borderedProminent).controlSize(.small)
                }.padding().background(Color.orange.opacity(0.1))
            }
            HStack(spacing: 0) {
                CustomTextEditor(text: $originalText, placeholder: "Type or paste text...").frame(maxWidth: .infinity, maxHeight: .infinity)
                Rectangle().fill(Color.primary.opacity(0.05)).frame(width: 1)
                OutputTextView(text: translatedText, isEmpty: translatedText.isEmpty).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.primary.opacity(0.02))
            }
            HStack {
                if isTranslating {
                    ProgressView().scaleEffect(0.6).padding(.trailing, 8)
                }
                Spacer()
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(translatedText, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc").font(.system(size: 12)).foregroundColor(.secondary)
                }.buttonStyle(.plain).padding(.trailing, 16).opacity(translatedText.isEmpty ? 0 : 1)
                Button(action: { Task { await performTranslation() } }) {
                    Text("Translate").font(.system(size: 13, weight: .medium)).padding(.horizontal, 16).padding(.vertical, 6).background(Color.primary.opacity(0.8)).foregroundColor(Color(nsColor: .windowBackgroundColor)).cornerRadius(6)
                }.buttonStyle(.plain).keyboardShortcut(.return, modifiers: .command)
            }.padding(16).background(Color.primary.opacity(0.03))
        }.background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.1), lineWidth: 0.5)).onExitCommand {
            WindowManager.shared.close()
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
            MacEditorView(text: $text)
            if text.isEmpty {
                Text(placeholder).font(.system(size: 16, weight: .light, design: .serif)).foregroundColor(.secondary.opacity(0.5)).padding(.horizontal, 25).padding(.vertical, 20).allowsHitTesting(false)
            }
        }.background(Color.clear)
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
        textView.string = isEmpty ? "Translation will appear here..." : text

        if isEmpty {
            textView.textColor = .secondaryLabelColor
        }

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        textView.string = isEmpty ? "Translation will appear here..." : text
        textView.textColor = isEmpty ? .secondaryLabelColor : .labelColor
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
                Text(selection).font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                Image(systemName: "chevron.down").font(.system(size: 8, weight: .bold)).foregroundColor(.secondary.opacity(0.7))
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
