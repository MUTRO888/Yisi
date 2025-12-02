import SwiftUI
import Cocoa

struct DynamicHeightTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    var placeholder: String
    var font: NSFont = .systemFont(ofSize: 15, weight: .medium)
    
    func makeNSView(context: Context) -> NSTextView {
        let textView = PlainTextView()
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator
        textView.font = font
        textView.textColor = .labelColor
        
        // Alignment fixes
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        
        // Rich text disabling
        textView.isRichText = false
        textView.importsGraphics = false
        
        return textView
    }
    
    // Custom TextView to enforce plain text paste
    class PlainTextView: NSTextView {
        override func paste(_ sender: Any?) {
            pasteAsPlainText(sender)
        }
    }
    
    func updateNSView(_ textView: NSTextView, context: Context) {
        if textView.string != text {
            textView.string = text
        }
        
        // Calculate height
        if let layoutManager = textView.layoutManager, let textContainer = textView.textContainer {
            layoutManager.ensureLayout(for: textContainer)
            let usedRect = layoutManager.usedRect(for: textContainer)
            let newHeight = max(24, usedRect.height) // Min height
            
            if abs(height - newHeight) > 1 {
                DispatchQueue.main.async {
                    height = newHeight
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: DynamicHeightTextEditor
        
        init(_ parent: DynamicHeightTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}
