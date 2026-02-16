#!/usr/bin/env swift

// generate_icon.swift
// Standalone script: renders the Yisi app icon to a 1024x1024 PNG.
// Usage: swift scripts/generate_icon.swift
// Output: ./icon_1024x1024.png

import SwiftUI
import AppKit

// MARK: - Color Hex Extension (self-contained copy)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Static Icon View (no animation, no @State)

struct StaticYisiAppIcon: View {
    // Full canvas size (output PNG)
    let canvasSize: CGFloat = 1024
    // Visible icon shape (Apple HIG: ~80% of canvas)
    private var iconSize: CGFloat { canvasSize * 0.80 }
    private var cornerRadius: CGFloat { iconSize * 0.22 }

    var body: some View {
        ZStack {
            // Transparent canvas
            Color.clear

            // Icon shape centered within canvas
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "555386"),
                        Color(hex: "474575")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

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

                VStack(alignment: .leading, spacing: iconSize * 0.09) {
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: iconSize * 0.55, height: iconSize * 0.09)

                    Capsule()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: iconSize * 0.36, height: iconSize * 0.09)

                    Capsule()
                        .fill(Color.white)
                        .frame(width: iconSize * 0.22, height: iconSize * 0.09)
                        .shadow(color: .white.opacity(0.6), radius: iconSize * 0.075, x: 0, y: 0)
                }
            }
            .frame(width: iconSize, height: iconSize)
            .cornerRadius(cornerRadius)
        }
        .frame(width: canvasSize, height: canvasSize)
    }
}

// MARK: - Render & Export

@available(macOS 13.0, *)
@MainActor
func renderIcon() -> Bool {
    let view = StaticYisiAppIcon()
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1.0

    guard let cgImage = renderer.cgImage else {
        fputs("ERROR: ImageRenderer failed to produce a CGImage.\n", stderr)
        return false
    }

    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        fputs("ERROR: Failed to encode PNG data.\n", stderr)
        return false
    }

    let outputURL = URL(fileURLWithPath: "icon_1024x1024.png")
    do {
        try pngData.write(to: outputURL)
        print("Rendered icon to \(outputURL.path) (\(cgImage.width)x\(cgImage.height))")
        return true
    } catch {
        fputs("ERROR: Failed to write PNG file: \(error.localizedDescription)\n", stderr)
        return false
    }
}

// MARK: - Entry Point

if #available(macOS 13.0, *) {
    DispatchQueue.main.async {
        if !renderIcon() {
            exit(1)
        }
        exit(0)
    }
    dispatchMain()
} else {
    fputs("ERROR: macOS 13.0+ is required for ImageRenderer.\n", stderr)
    exit(1)
}
