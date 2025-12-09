import SwiftUI

struct ThemeBackground: View {
    var body: some View {
        ZStack {
            // Base: Frosted Glass (Essential for "frosted transparent" requirement)
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            
            // Tint Overlay: Purely neutral/white to enhance the frosted look without color cast
            
            // 1. General Sheen (Subtle Purple Tint)
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.yisiPurple.opacity(0.03), // Just a hint of purple
                    Color.white.opacity(0.02)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 2. Top Left Highlight (Light Reflection)
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.1),
                    Color.white.opacity(0)
                ]),
                center: UnitPoint(x: 0.1, y: 0.2),
                startRadius: 0,
                endRadius: 300
            )
            
            // 3. Bottom Center Glow (Faint Purple Depth)
            RadialGradient(
                gradient: Gradient(colors: [
                    AppColors.yisiPurple.opacity(0.08), // Very subtle glow
                    AppColors.yisiPurple.opacity(0)
                ]),
                center: UnitPoint(x: 0.5, y: 1.0),
                startRadius: 0,
                endRadius: 400
            )
            
            // 4. Border/Stroke Effect (Clean Glass Edge)
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        }
    }
}
