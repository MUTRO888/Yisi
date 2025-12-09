import SwiftUI

struct AppColors {
    // Core Palette
    static let yisiPurple = Color(hex: "555386")
    static let yisiDeep = Color(hex: "413F6B")
    static let yisiLight = Color(hex: "7A78AD")
    static let mist = Color(hex: "EBEAF5")
    static let inkMain = Color(hex: "1F1E2E")
    
    // Glass Effects
    static let glassMenu = Color.white.opacity(0.65)
    static let glassCard = Color.white.opacity(0.85)
    
    // Semantic Mapping
    static let primary = yisiPurple
    static let secondary = yisiLight
    static let background = mist
    static let text = inkMain
    static let selection = mist
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
