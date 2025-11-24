import SwiftUI

struct SettingsView: View {
    @AppStorage("gemini_api_key") private var geminiKey: String = ""
    @AppStorage("openai_api_key") private var openaiKey: String = ""
    @AppStorage("api_provider") private var selectedProvider: String = "Gemini"
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
                TabButton(title: "API", icon: "key", isSelected: selectedTab == 0) { selectedTab = 0 }
                TabButton(title: "Shortcuts", icon: "command", isSelected: selectedTab == 1) { selectedTab = 1 }
                TabButton(title: "Prompts", icon: "text.quote", isSelected: selectedTab == 2) { selectedTab = 2 }
            }
            .padding(.horizontal)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if selectedTab == 0 {
                        ApiSection(
                            openaiKey: $openaiKey,
                            geminiKey: $geminiKey,
                            selectedProvider: $selectedProvider
                        )
                    } else if selectedTab == 1 {
                        Text("Shortcut configuration coming soon.")
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

struct ApiSection: View {
    @Binding var openaiKey: String
    @Binding var geminiKey: String
    @Binding var selectedProvider: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("API Provider")
                .font(.headline)
            
            Picker("", selection: $selectedProvider) {
                Text("Gemini").tag("Gemini")
                Text("OpenAI").tag("OpenAI")
            }
            .pickerStyle(.segmented)
            
            Divider()
                .padding(.vertical, 5)
            
            if selectedProvider == "Gemini" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gemini API Key")
                        .font(.subheadline)
                    
                    SecureField("Enter your Gemini API key", text: $geminiKey)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("Get your key from Google AI Studio")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("OpenAI API Key")
                        .font(.subheadline)
                    
                    SecureField("sk-...", text: $openaiKey)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("Get your key from OpenAI Platform")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Keys are stored in UserDefaults for development convenience.")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
                .padding(.top, 5)
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

