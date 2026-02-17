import SwiftUI

struct AboutView: View {
    @Environment(\.openURL) var openURL
    
    // Dynamic Data
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }
    
    private var currentYear: String {
        let year = Calendar.current.component(.year, from: Date())
        return String(year)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top Layout: Title + Icon
            HStack(alignment: .center, spacing: 20) {
                Text("Yisi")
                    .font(.system(size: 64, weight: .ultraLight))
                    .foregroundColor(.primary)
                    .tracking(-1) // Tighten tracking for large thin text

                YisiAppIcon(size: 80)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
            .padding(.bottom, 8) // Spacing between Title/Icon and Slogan

            // Slogan
            Text("Always room for improvement.")
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundColor(.primary)
                .padding(.bottom, 12) // Spacing between Slogan and Rights info
            
            // Middle: Copyright & License
            VStack(alignment: .leading, spacing: 6) {
                Text("© \(currentYear) Sonian Mu. All rights reserved.")
                    .font(.system(size: 11, design: .serif))
                    .foregroundColor(.secondary)
                
                Text("Released under the GNU GPLv3 License.")
                    .font(.system(size: 10, design: .serif))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(.bottom, 16) // Spacing between Rights and Buttons
            
            // Bottom: Buttons
            HStack(spacing: 16) {
                LinkButton(title: "Home".localized) {
                    // Replace with actual home URL if available, currently placeholder or github
                    openURL(URL(string: "https://github.com/MUTRO888/Yisi")!)
                }

                LinkButton(title: "GitHub".localized) {
                    openURL(URL(string: "https://github.com/MUTRO888/Yisi")!)
                }

                LinkButton(title: "Begin".localized) {
                    NotificationCenter.default.post(name: Notification.Name("ShowWelcome"), object: nil)
                }
            }
        }
        .frame(maxWidth: .infinity) // Centers the VStack horizontally in the parent
        .padding(.top, 40)
        .padding(.bottom, 60)
    }
}

struct LinkButton: View {
    let title: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Color.primary.opacity(0.05) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                )
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hover in
            isHovered = hover
        }
    }
}
