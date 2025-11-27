import SwiftUI

enum ClosingMode: String, CaseIterable, Identifiable {
    case clickOutside = "clickOutside"
    case xButton = "xButton"
    case escKey = "escKey"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .clickOutside: return "Click Outside"
        case .xButton: return "X Button"
        case .escKey: return "Esc Key"
        }
    }
}

struct SettingsView: View {
    @AppStorage("gemini_api_key") private var geminiKey: String = ""
    @AppStorage("close_mode") private var closeMode: String = "clickOutside"
    @State private var selectedTab: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Quit Yisi")
            }
            .padding()
            .background(Color.primary.opacity(0.05))
            
            HStack(spacing: 20) {
                TabButton(title: "General", icon: "gearshape", isSelected: selectedTab == 0) { selectedTab = 0 }
                TabButton(title: "History", icon: "clock", isSelected: selectedTab == 1) { selectedTab = 1 }
                TabButton(title: "Prompts", icon: "text.quote", isSelected: selectedTab == 2) { selectedTab = 2 }
            }
            .padding(.horizontal)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if selectedTab == 0 {
                        GeneralSection(
                            geminiKey: $geminiKey,
                            closeMode: $closeMode
                        )
                    } else if selectedTab == 1 {
                        Text("Translation history coming soon.")
                            .foregroundColor(.secondary)
                    } else {
                        Text("Prompt templates coming soon.")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .frame(height: 300)
        }
        .frame(width: 350)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
    }
}

struct GeneralSection: View {
    @Binding var geminiKey: String
    @Binding var closeMode: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // API Configuration
            VStack(alignment: .leading, spacing: 8) {
                Text("API Configuration")
                    .font(.headline)
                
                Text("Gemini API Key")
                    .font(.subheadline)
                
                SecureField("Enter your Gemini API key", text: $geminiKey)
                    .textFieldStyle(.roundedBorder)
                
                Text("Get your key from Google AI Studio")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Window Behavior
            VStack(alignment: .leading, spacing: 8) {
                Text("Window Behavior")
                    .font(.headline)
                
                Text("Closing Method")
                    .font(.subheadline)
                
                Picker("", selection: $closeMode) {
                    ForEach(ClosingMode.allCases) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                
                Text("Choose how you want to close the translation window.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .primary : .secondary)
            .frame(width: 60)
        }
        .buttonStyle(.plain)
    }
}

