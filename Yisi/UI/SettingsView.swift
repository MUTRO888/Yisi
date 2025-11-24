import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var selectedTab: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Yisi")
                    .font(.system(size: 18, weight: .bold, design: .serif))
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
            
            // Tabs
            HStack(spacing: 20) {
                TabButton(title: "API", icon: "key", isSelected: selectedTab == 0) { selectedTab = 0 }
                TabButton(title: "Shortcuts", icon: "command", isSelected: selectedTab == 1) { selectedTab = 1 }
                TabButton(title: "Prompts", icon: "text.quote", isSelected: selectedTab == 2) { selectedTab = 2 }
            }
            .padding(.vertical, 10)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if selectedTab == 0 {
                        ApiSection(apiKey: $apiKey)
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
        .onAppear {
            loadApiKey()
        }
    }
    
    private func loadApiKey() {
        if let data = KeychainHelper.shared.read(service: "com.yisi.app", account: "openai_api_key"),
           let key = String(data: data, encoding: .utf8) {
            apiKey = key
        }
    }
    
    private func saveApiKey() {
        if let data = apiKey.data(using: .utf8) {
            KeychainHelper.shared.save(data, service: "com.yisi.app", account: "openai_api_key")
        }
    }
}

struct ApiSection: View {
    @Binding var apiKey: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("API Key")
                .font(.headline)
            
            SecureField("sk-...", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .onChange(of: apiKey) {
                    saveApiKey()
                }
            
            Text("Your key is stored securely in the macOS Keychain.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func saveApiKey() {
        if let data = apiKey.data(using: .utf8) {
            KeychainHelper.shared.save(data, service: "com.yisi.app", account: "openai_api_key")
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
