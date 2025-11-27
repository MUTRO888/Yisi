import SwiftUI

@main
struct YisiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @AppStorage("app_theme") private var appTheme: String = "system"
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the dock icon to make it a true background app
        NSApp.setActivationPolicy(.accessory)
        
        setupMenuBar()
        setupShortcutHandler()
        checkAccessibilityPermissions()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            if let image = createFlowIcon() {
                button.image = image
            } else {
                button.image = NSImage(systemSymbolName: "brain", accessibilityDescription: "Yisi")
            }
            button.action = #selector(toggleSettings)
            button.target = self
        }
    }
    
    private func createFlowIcon() -> NSImage? {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        let scale = size.width / 24.0
        let path = NSBezierPath()
        
        // Top curve: M4 10C8 6, 16 6, 20 10
        path.move(to: NSPoint(x: 4 * scale, y: 14 * scale)) // Flip Y for AppKit
        path.curve(
            to: NSPoint(x: 20 * scale, y: 14 * scale),
            controlPoint1: NSPoint(x: 8 * scale, y: 18 * scale),
            controlPoint2: NSPoint(x: 16 * scale, y: 18 * scale)
        )
        
        // Bottom curve: M20 14C16 18, 8 18, 4 14
        path.move(to: NSPoint(x: 20 * scale, y: 10 * scale))
        path.curve(
            to: NSPoint(x: 4 * scale, y: 10 * scale),
            controlPoint1: NSPoint(x: 16 * scale, y: 6 * scale),
            controlPoint2: NSPoint(x: 8 * scale, y: 6 * scale)
        )
        
        NSColor.controlTextColor.setStroke()
        path.lineWidth = 1.5
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
        
        image.unlockFocus()
        image.isTemplate = true
        
        return image
    }
    
    private func setupShortcutHandler() {
        GlobalShortcutManager.shared.onShortcutTriggered = { [weak self] in
            self?.handleShortcut()
        }
    }
    
    @objc func toggleSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 550, height: 420),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = "Yisi Settings"
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.isMovableByWindowBackground = true
            window.isOpaque = false
            window.backgroundColor = .clear
            
            let settingsView = SettingsView()
            
            window.contentView = NSHostingView(rootView: settingsView)
            window.isReleasedWhenClosed = false
            
            settingsWindow = window
        }
        
        if let window = settingsWindow {
            if !window.isVisible {
                window.center()
            }
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private func handleShortcut() {
        print("Shortcut detected in App")
        
        Task {
            let result = await TextCaptureService.shared.captureSelectedText()
            
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
                    break
                case .other(let msg):
                    print("Capture error: \(msg)")
                }
            }
            
            let finalText = text
            let finalError = error
            
            await MainActor.run {
                WindowManager.shared.show(text: finalText, error: finalError)
            }
        }
    }
    
    private func checkAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            print("Accessibility access not granted. Prompting user...")
        }
    }
}

class AppState: ObservableObject {
    @Published var isThinking = false
}

extension ColorScheme {
    init?(from string: String) {
        switch string {
        case "light": self = .light
        case "dark": self = .dark
        default: return nil
        }
    }
}
