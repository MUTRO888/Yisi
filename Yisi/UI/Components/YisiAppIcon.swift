import SwiftUI

struct YisiAppIcon: View {
    let size: CGFloat
    @State private var isHovered = false
    
    // Derived properties
    private var cornerRadius: CGFloat { size * 0.22 }
    
    // Animation constants
    private let animationDuration: Double = 1.2
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "555386"),
                    Color(hex: "474575")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Shadows
            .shadow(color: Color(hex: "474575").opacity(0.3), radius: 40, x: 0, y: 20)
            .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
            
            // Inner Highlight (Top)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            
            // Content
            VStack(alignment: .leading, spacing: size * 0.09) {
                // Bar 1
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: isHovered ? size * 0.55 * 1.15 : size * 0.55, height: size * 0.09)
                    .animation(isHovered ? .easeInOut(duration: animationDuration).repeatForever(autoreverses: true) : .default, value: isHovered)
                
                // Bar 2
                Capsule()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: isHovered ? size * 0.36 * 1.15 : size * 0.36, height: size * 0.09)
                    .animation(isHovered ? .easeInOut(duration: animationDuration).repeatForever(autoreverses: true).delay(0.15) : .default, value: isHovered)
                
                // Bar 3
                Capsule()
                    .fill(Color.white)
                    .frame(width: isHovered ? size * 0.22 * 1.1 : size * 0.22, height: size * 0.09)
                    .shadow(color: .white.opacity(0.6), radius: size * 0.075, x: 0, y: 0)
                    .animation(isHovered ? .easeInOut(duration: animationDuration).repeatForever(autoreverses: true).delay(0.3) : .default, value: isHovered)
            }
            // Removed offset to center the content visually as requested
            // .offset(x: -size * 0.065)
        }
        .frame(width: size, height: size)
        .cornerRadius(cornerRadius)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .offset(y: isHovered ? -5 : 0)
        .animation(.cubicBezier(0.34, 1.56, 0.64, 1.0), value: isHovered)
        .onHover { hover in
            isHovered = hover
        }
    }
}

// Cubic Bezier Animation Curve Extension
extension Animation {
    static func cubicBezier(_ controlPoint1: Double, _ controlPoint2: Double, _ controlPoint3: Double, _ controlPoint4: Double) -> Animation {
        return Animation.timingCurve(controlPoint1, controlPoint2, controlPoint3, controlPoint4)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all)
        YisiAppIcon(size: 200)
    }
}
