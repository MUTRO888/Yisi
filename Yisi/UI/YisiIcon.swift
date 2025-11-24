import SwiftUI
import AppKit

struct YisiIcon: View {
    var isThinking: Bool
    
    var body: some View {
        if let image = createFlowIcon() {
            Image(nsImage: image)
                .renderingMode(.template)
        } else {
            // Fallback
            Image(systemName: "bubble.left.and.bubble.right")
        }
    }
    
    private func createFlowIcon() -> NSImage? {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        let scale = size.width / 24.0
        let path = NSBezierPath()
        
        // Top curve: M4 10C8 6, 16 6, 20 10
        path.move(to: NSPoint(x: 4 * scale, y: 14 * scale)) // Flip Y for AppKit
        path.curve(
            to: NSPoint(x: 20 * scale, y: 14 * scale),
            controlPoint1: NSPoint(x: 8 * scale, y: 18 * scale),
            controlPoint2: NSPoint(x: 16 * scale, y: 18 * scale)
        )
        
        // Bottom curve: M20 14C16 18, 8 18, 4 14
        path.move(to: NSPoint(x: 20 * scale, y: 10 * scale))
        path.curve(
            to: NSPoint(x: 4 * scale, y: 10 * scale),
            controlPoint1: NSPoint(x: 16 * scale, y: 6 * scale),
            controlPoint2: NSPoint(x: 8 * scale, y: 6 * scale)
        )
        
        NSColor.controlTextColor.setStroke()
        path.lineWidth = 1.5
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
        
        image.unlockFocus()
        image.isTemplate = true
        
        return image
    }
}
