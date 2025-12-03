import SwiftUI
import Cocoa

struct TransparentScrollView<Content: View>: NSViewRepresentable {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        
        // Use our custom scroller
        scrollView.verticalScroller = TransparentScroller()
        
        // Hosting View
        let hostingView = ResizingHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set document view
        scrollView.documentView = hostingView
        
        // Constraints
        // We want the content to match the width of the scroll view
        // And let the height be determined by the content
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor)
        ])
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        if let hostingView = scrollView.documentView as? ResizingHostingView<Content> {
            hostingView.rootView = content
            // Force layout update to handle dynamic content size changes
            hostingView.layout()
        }
    }
}

class ResizingHostingView<Content: View>: NSHostingView<Content> {
    override func layout() {
        super.layout()
        let size = self.fittingSize
        if size.height > 0 && self.frame.height != size.height {
            self.frame.size.height = size.height
        }
    }
}
