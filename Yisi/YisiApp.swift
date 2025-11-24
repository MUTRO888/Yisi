import SwiftUI

@main
struct YisiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var shortcutManager = GlobalShortcutManager()
    
    var body: some Scene {
        MenuBarExtra(isInserted: .constant(true)) {
            SettingsView()
        } label: {
            YisiIcon(isThinking: appState.isThinking)
        }
        .menuBarExtraStyle(.window)
        .onChange(of: shortcutManager.triggerCount) {
            handleShortcut()
        }
    }
    
    private func handleShortcut() {
        print("Shortcut detected in App")
        
        let result = TextCaptureService.shared.captureSelectedText()
        
        var text = ""
        var error: String? = nil
        
        switch result {
        case .success(let capturedText):
            text = capturedText
        case .failure(let captureError):
            switch captureError {
            case .permissionDenied:
                error = "Accessibility permission required to capture text."
            case .noFocusedElement, .noSelection:
                // These are normal if no text is selected, just show empty window
                break
            case .other(let msg):
                print("Capture error: \(msg)")
            }
        }
        
        DispatchQueue.main.async {
            WindowManager.shared.show(text: text, error: error)
        }
    }
    
    init() {
        checkAccessibilityPermissions()
    }
    
    private func checkAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            print("Accessibility access not granted. Prompting user...")
            // In a real app, we might want to show a specific onboarding window here
            // For now, the system prompt should appear, or we can rely on the user checking settings
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the dock icon to make it a true background app
        NSApp.setActivationPolicy(.accessory)
    }
}

class AppState: ObservableObject {
    @Published var isThinking = false
}
