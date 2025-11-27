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
    @State private var selectedTopTab: Int = 0 // 0: History, 1: Settings
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation
            HStack(spacing: 32) {
                TopTabButton(title: "History", isSelected: selectedTopTab == 0) { selectedTopTab = 0 }
                TopTabButton(title: "Settings", isSelected: selectedTopTab == 1) { selectedTopTab = 1 }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            // Removed opaque background to allow frosted effect
            
            Divider().opacity(0.2)
            
            // Content Area
            ZStack(alignment: .topLeading) {
                // Removed opaque background color
                
                if selectedTopTab == 0 {
                    HistoryView()
                } else {
                    SettingsContent()
                }
            }
        }
        .frame(width: 550, height: 420)
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
    }
}

struct TopTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .medium : .regular, design: .serif))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                // Active Indicator
                Rectangle()
                    .fill(isSelected ? Color.primary.opacity(0.7) : Color.clear)
                    .frame(height: 1)
                    .frame(width: 20)
            }
        }
        .buttonStyle(.plain)
    }
}

struct HistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.secondary.opacity(0.3))
            Text("No History")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(.secondary)
            Text("Your recent translations will appear here.")
                .font(.system(size: 12, design: .serif))
                .foregroundColor(.secondary.opacity(0.7))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SettingsContent: View {
    @State private var selectedSection: String = "General"
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 12) {
                SidebarButton(title: "General", isSelected: selectedSection == "General") { selectedSection = "General" }
                SidebarButton(title: "Prompts", isSelected: selectedSection == "Prompts") { selectedSection = "Prompts" }
                SidebarButton(title: "Shortcuts", isSelected: selectedSection == "Shortcuts") { selectedSection = "Shortcuts" }
                Spacer()
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .frame(width: 140)
            .background(Color.primary.opacity(0.02))
            
            Divider().opacity(0.5)
            
            // Section Content
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    if selectedSection == "General" {
                        GeneralSection()
                    } else if selectedSection == "Prompts" {
                        PromptsSection()
                    } else if selectedSection == "Shortcuts" {
                        ShortcutsSection()
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct SidebarButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .medium : .regular, design: .serif))
                .foregroundColor(isSelected ? .primary : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isSelected ? Color.primary.opacity(0.04) : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct GeneralSection: View {
    @AppStorage("gemini_api_key") private var geminiKey: String = ""
    @AppStorage("openai_api_key") private var openaiKey: String = ""
    @AppStorage("zhipu_api_key") private var zhipuKey: String = ""
    @AppStorage("api_provider") private var apiProvider: String = "Gemini"
    @AppStorage("close_mode") private var closeMode: String = "clickOutside"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // API Configuration
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "API Service")
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Provider")
                            .font(.system(size: 13, design: .serif))
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        
                        CustomDropdown(selection: $apiProvider, options: ["Gemini", "OpenAI", "Zhipu AI"])
                    }
                    
                    if apiProvider == "Gemini" {
                        APIKeyInput(label: "API Key", text: $geminiKey, placeholder: "Gemini API Key")
                    } else if apiProvider == "OpenAI" {
                        APIKeyInput(label: "API Key", text: $openaiKey, placeholder: "OpenAI API Key")
                    } else if apiProvider == "Zhipu AI" {
                        APIKeyInput(label: "API Key", text: $zhipuKey, placeholder: "Zhipu API Key")
                    }
                }
            }
            
            Divider().opacity(0.3)
            
            // Window Behavior
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Behavior")
                
                HStack {
                    Text("Close Mode")
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    
                    CustomDropdown(selection: $closeMode, options: ClosingMode.allCases.map { $0.rawValue }, displayNames: ClosingMode.allCases.map { $0.displayName })
                }
                
                Divider().opacity(0.2)
                
                HStack {
                    Text("Layout")
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    
                    Button(action: {
                        LayoutEditorManager.shared.openEditor()
                    }) {
                        Text("Customize Popup Layout")
                            .font(.system(size: 13, design: .serif))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

class LayoutEditorManager {
    static let shared = LayoutEditorManager()
    var editorWindow: NSWindow?
    
    func openEditor() {
        editorWindow?.close()
        
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.frame
        
        // Load existing frame or default
        var initialFrame = CGRect(x: screenRect.midX - 200, y: screenRect.midY - 150, width: 400, height: 300)
        
        if let savedData = UserDefaults.standard.data(forKey: "popup_frame_rect"),
           let savedRect = try? JSONDecoder().decode(CGRect.self, from: savedData) {
            // Convert Cocoa (Bottom-Left) to SwiftUI (Top-Left)
            // Cocoa Y is from bottom. SwiftUI Y is from top.
            // swiftUI_Y = screenHeight - (cocoaY + height)
            let swiftUI_Y = screenRect.height - (savedRect.origin.y + savedRect.height)
            initialFrame = CGRect(x: savedRect.origin.x, y: swiftUI_Y, width: savedRect.width, height: savedRect.height)
        } else {
             // Default center (SwiftUI coords)
             // screenRect.midY is center.
             // Top-Left Y = center Y - height/2? No.
             // SwiftUI (0,0) is top-left.
             // Center Y in SwiftUI is screenHeight / 2.
             // So y = screenHeight/2 - 150.
             initialFrame = CGRect(x: screenRect.width/2 - 200, y: screenRect.height/2 - 150, width: 400, height: 300)
        }
        
        let contentView = LayoutEditorView(
            initialFrame: initialFrame,
            screenFrame: CGRect(x: 0, y: 0, width: screenRect.width, height: screenRect.height),
            onSave: { [weak self] frame in
                // Convert SwiftUI (Top-Left) to Cocoa (Bottom-Left)
                // cocoaY = screenHeight - (swiftUI_Y + height)
                let cocoaY = screenRect.height - (frame.origin.y + frame.height)
                let cocoaRect = CGRect(x: frame.origin.x, y: cocoaY, width: frame.width, height: frame.height)
                
                if let data = try? JSONEncoder().encode(cocoaRect) {
                    UserDefaults.standard.set(data, forKey: "popup_frame_rect")
                }
                
                DispatchQueue.main.async {
                    self?.editorWindow?.close()
                    self?.editorWindow = nil
                }
            },
            onCancel: { [weak self] in
                DispatchQueue.main.async {
                    self?.editorWindow?.close()
                    self?.editorWindow = nil
                }
            }
        )
        
        let window = NSWindow(
            contentRect: screenRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        editorWindow = window
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .medium, design: .serif))
            .foregroundColor(.primary.opacity(0.8))
            .textCase(.uppercase)
            .kerning(0.5)
    }
}

struct APIKeyInput: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack(alignment: .center) {
            Text(label)
                .font(.system(size: 13, design: .serif))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            SecureField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 13))
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color.primary.opacity(0.03))
                .cornerRadius(4)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
        }
    }
}

struct PromptsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Prompts")
            
            Text("Customize the system prompts used for translation.")
                .font(.system(size: 13, design: .serif))
                .foregroundColor(.secondary)
            
            Text("Coming soon")
                .font(.system(size: 12, design: .serif))
                .foregroundColor(.secondary.opacity(0.5))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.02))
                .cornerRadius(6)
        }
    }
}

struct ShortcutsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Shortcuts")
            
            HStack {
                Text("Activate")
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)
                
                ShortcutRecorder()
            }
            
            Text("Press the key combination you want to use to activate Yisi.")
                .font(.system(size: 12, design: .serif))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.top, 4)
        }
    }
}

struct CustomDropdown: View {
    @Binding var selection: String
    let options: [String]
    var displayNames: [String]? = nil
    
    @State private var isExpanded = false
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selection = option
                }) {
                    Text(displayName(for: option))
                }
            }
        } label: {
            HStack {
                Text(displayName(for: selection))
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(.primary)
                Spacer()
                // Removed redundant chevron
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .frame(width: 160)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(4)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
    
    private func displayName(for option: String) -> String {
        if let displayNames = displayNames, let index = options.firstIndex(of: option) {
            return displayNames[index]
        }
        return option
    }
}

struct ShortcutRecorder: View {
    @State private var isRecording = false
    @State private var currentShortcut: String = ""
    @State private var monitor: Any?
    
    var body: some View {
        Button(action: {
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        }) {
            HStack {
                if isRecording {
                    Text("Press keys...")
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(.accentColor)
                    Spacer()
                    Image(systemName: "record.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)
                        .symbolEffect(.pulse)
                } else {
                    Text(currentShortcut.isEmpty ? "Record Shortcut" : currentShortcut)
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(.primary)
                    Spacer()
                    if !currentShortcut.isEmpty {
                        Button(action: {
                            resetShortcut()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .frame(width: 160)
            .background(isRecording ? Color.accentColor.opacity(0.05) : Color.primary.opacity(0.03))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isRecording ? Color.accentColor.opacity(0.3) : Color.primary.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            updateDisplay()
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        // Add a local monitor to capture keys
        // We use .keyDown to capture the combination
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyDown(event)
            return nil // Consume the event
        }
    }
    
    private func stopRecording() {
        isRecording = false
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
    
    private func resetShortcut() {
        GlobalShortcutManager.shared.updateShortcut(keyCode: 16, modifiers: [.command, .control])
        updateDisplay()
    }
    
    private func updateDisplay() {
        let keyCode = UserDefaults.standard.integer(forKey: "global_shortcut_key")
        let modifiers = UserDefaults.standard.integer(forKey: "global_shortcut_modifiers")
        
        if keyCode != 0 {
            currentShortcut = shortcutString(keyCode: UInt16(keyCode), modifiers: NSEvent.ModifierFlags(rawValue: UInt(modifiers)))
        } else {
            currentShortcut = "⌘⌃Y" // Default
        }
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode
        
        // Ignore standalone modifier presses
        if event.type == .flagsChanged {
            return
        }
        
        // Escape to cancel
        if keyCode == 53 {
            stopRecording()
            return
        }
        
        // Save shortcut
        GlobalShortcutManager.shared.updateShortcut(keyCode: keyCode, modifiers: flags)
        updateDisplay()
        stopRecording()
    }
    
    private func shortcutString(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> String {
        var string = ""
        if modifiers.contains(.command) { string += "⌘" }
        if modifiers.contains(.control) { string += "⌃" }
        if modifiers.contains(.option) { string += "⌥" }
        if modifiers.contains(.shift) { string += "⇧" }
        
        // Simple key mapping
        switch keyCode {
        case 0: string += "A"
        case 1: string += "S"
        case 2: string += "D"
        case 3: string += "F"
        case 4: string += "H"
        case 5: string += "G"
        case 6: string += "Z"
        case 7: string += "X"
        case 8: string += "C"
        case 9: string += "V"
        case 11: string += "B"
        case 12: string += "Q"
        case 13: string += "W"
        case 14: string += "E"
        case 15: string += "R"
        case 16: string += "Y"
        case 17: string += "T"
        case 18: string += "1"
        case 19: string += "2"
        case 20: string += "3"
        case 21: string += "4"
        case 22: string += "6"
        case 23: string += "5"
        case 24: string += "="
        case 25: string += "9"
        case 26: string += "7"
        case 27: string += "-"
        case 28: string += "8"
        case 29: string += "0"
        case 30: string += "]"
        case 31: string += "O"
        case 32: string += "U"
        case 33: string += "["
        case 34: string += "I"
        case 35: string += "P"
        case 37: string += "L"
        case 38: string += "J"
        case 39: string += "'"
        case 40: string += "K"
        case 41: string += ";"
        case 42: string += "\\"
        case 43: string += ","
        case 44: string += "/"
        case 45: string += "N"
        case 46: string += "M"
        case 47: string += "."
        case 50: string += "`"
        default: string += "?"
        }
        
        return string
    }
}

