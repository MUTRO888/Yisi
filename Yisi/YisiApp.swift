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
        
        // Capture text or use empty string for manual input
        let text = TextCaptureService.shared.captureSelectedText() ?? ""
        print("Captured text: '\(text)'")
        
        DispatchQueue.main.async {
            WindowManager.shared.show(text: text)
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
    @Published var menuBarIconName = "circle" // Standby icon
    
    func showSettings() {
        // TODO: Implement Settings Window
        print("Show Settings")
    }
}
