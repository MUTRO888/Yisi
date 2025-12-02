import SwiftUI

struct ThemeBackground: View {
    var body: some View {
        ZStack {
            // Base: Frosted Glass (Essential for "frosted transparent" requirement)
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            
            // Tint Overlay: Subtle gradients to provide the "Prominent Theme" without blocking transparency
            
            // 1. General Tint (Mist/Purple mix)
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.mist.opacity(0.1),
                    AppColors.yisiPurple.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 2. Top Left Highlight (Subtle Light)
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.15),
                    Color.white.opacity(0)
                ]),
                center: UnitPoint(x: 0.1, y: 0.2),
                startRadius: 0,
                endRadius: 300
            )
            
            // 3. Bottom Center Glow (The "Prominent" Yisi Purple)
            // Increased opacity slightly to be visible but still transparent
            RadialGradient(
                gradient: Gradient(colors: [
                    AppColors.yisiPurple.opacity(0.25),
                    AppColors.yisiPurple.opacity(0)
                ]),
                center: UnitPoint(x: 0.5, y: 1.0), // Moved up slightly
                startRadius: 0,
                endRadius: 500
            )
            
            // 4. Border/Stroke Effect (Inner Glow)
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            AppColors.yisiPurple.opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
    }
}
