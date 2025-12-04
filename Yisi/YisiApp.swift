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
        // Design: "Pure Lines"
        // 3 lines, left aligned
        // Widths: 14, 9, 5
        // Height: 2
        // Gap: 2.5
        // Color: Black/Dark (System Text Color)
        
        let size = NSSize(width: 22, height: 22) // Match CSS .menubar-icon-shape
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        let ctx = NSGraphicsContext.current?.cgContext
        ctx?.setShouldAntialias(true)
        
        NSColor.controlTextColor.setFill() // Adapts to light/dark mode
        
        // Calculate vertical centering
        // Total height = 2*3 + 2.5*2 = 6 + 5 = 11
        // Top Y = (22 - 11) / 2 = 5.5
        
        let startY: CGFloat = 5.5
        let lineHeight: CGFloat = 2.0
        let gap: CGFloat = 2.5
        
        // Line 1 (Top) - Width 14
        // Note: Cocoa coords (0,0) is bottom-left.
        // To match CSS "Top", we draw from top down or just calculate Y.
        // Let's draw from top (higher Y) to bottom (lower Y).
        // Center Y is 11.
        // Top line Y = 11 + 2.5 + 2 = 15.5? No.
        // Let's just use the calculated startY from bottom.
        // Bottom line Y = 5.5
        // Middle line Y = 5.5 + 2 + 2.5 = 10.0
        // Top line Y = 10.0 + 2 + 2.5 = 14.5
        
        // Wait, CSS order is usually top-down.
        // .bar:nth-child(1) width 92% (in harmonic flow)
        // Here: .ml-1 width 14px (Top)
        // .ml-2 width 9px (Middle)
        // .ml-3 width 5px (Bottom)
        
        let topY = 5.5 + 4.5 + 4.5 // 14.5
        let midY = 5.5 + 4.5       // 10.0
        let botY = 5.5             // 5.5
        
        // Draw Top Line (Width 14)
        let path1 = NSBezierPath(roundedRect: NSRect(x: 4, y: topY, width: 14, height: lineHeight), xRadius: 1, yRadius: 1)
        path1.fill()
        
        // Draw Middle Line (Width 9)
        let path2 = NSBezierPath(roundedRect: NSRect(x: 4, y: midY, width: 9, height: lineHeight), xRadius: 1, yRadius: 1)
        path2.fill()
        
        // Draw Bottom Line (Width 5)
        let path3 = NSBezierPath(roundedRect: NSRect(x: 4, y: botY, width: 5, height: lineHeight), xRadius: 1, yRadius: 1)
        path3.fill()
        
        image.unlockFocus()
        image.isTemplate = true // Allows system to recolor it (e.g. white in dark mode menu bar)
        
        return image
    }
    
    private func setupShortcutHandler() {
        // 翻译快捷键
        GlobalShortcutManager.shared.onShortcutTriggered = { [weak self] in
            self?.handleShortcut()
        }
        
        // 截图快捷键
        GlobalShortcutManager.shared.onScreenshotTriggered = { [weak self] in
            self?.handleScreenshotShortcut()
        }
    }
    
    private func handleScreenshotShortcut() {
        print("Screenshot shortcut triggered")
        ScreenCaptureManager.shared.startCapture { [weak self] image in
            // 截图完成，显示翻译窗口（带图片上下文）
            DispatchQueue.main.async {
                WindowManager.shared.showWithImage(image: image)
            }
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
