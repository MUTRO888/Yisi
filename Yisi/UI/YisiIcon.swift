import SwiftUI

struct YisiIcon: View {
    var isThinking: Bool
    
    var body: some View {
        ZStack {
            // The Flow of Dialogue Icon
            // ViewBox 0 0 24 24
            Canvas { context, size in
                let w = size.width
                _ = size.height
                let scale = w / 24.0
                
                var path = Path()
                // Top curve: M4 10C8 6, 16 6, 20 10
                path.move(to: CGPoint(x: 4 * scale, y: 10 * scale))
                path.addCurve(
                    to: CGPoint(x: 20 * scale, y: 10 * scale),
                    control1: CGPoint(x: 8 * scale, y: 6 * scale),
                    control2: CGPoint(x: 16 * scale, y: 6 * scale)
                )
                
                // Bottom curve: M20 14C16 18, 8 18, 4 14
                path.move(to: CGPoint(x: 20 * scale, y: 14 * scale))
                path.addCurve(
                    to: CGPoint(x: 4 * scale, y: 14 * scale),
                    control1: CGPoint(x: 16 * scale, y: 18 * scale),
                    control2: CGPoint(x: 8 * scale, y: 18 * scale)
                )
                
                context.stroke(path, with: .color(.primary), lineWidth: 1.5 * scale)
            }
            .frame(width: 22, height: 22) // Standard menu bar icon size
            
            if isThinking {
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(isThinking ? 360 : 0))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isThinking)
            }
        }
    }
}
