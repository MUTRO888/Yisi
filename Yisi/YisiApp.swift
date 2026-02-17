import SwiftUI
import ServiceManagement

@main
struct YisiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @AppStorage(AppDefaults.Keys.appTheme) private var appTheme: String = AppDefaults.appTheme
    
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
        AppDefaults.registerDefaults()
        NSApp.setActivationPolicy(.accessory)
        
        setupMenuBar()
        setupShortcutHandler()
        
        if !UserDefaults.standard.bool(forKey: AppDefaults.Keys.hasLaunchedBefore) {
            try? SMAppService.mainApp.register()
            UserDefaults.standard.set(true, forKey: AppDefaults.Keys.hasLaunchedBefore)
            DispatchQueue.main.async { [weak self] in
                self?.toggleSettings()
            }
        }
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            if let image = createFlowIcon() {
                button.image = image
            } else {
                button.image = NSImage(systemSymbolName: "brain", accessibilityDescription: "Yisi")
            }
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(handleMenuBarClick)
            button.target = self
        }
    }
    
    @objc private func handleMenuBarClick() {
        guard let event = NSApp.currentEvent else {
            toggleSettings()
            return
        }
        
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "History".localized, action: #selector(openHistory), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Settings".localized, action: #selector(openSettingsConfig), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit".localized, action: #selector(quitApp), keyEquivalent: ""))
            
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            toggleSettings()
        }
    }
    
    @objc private func openHistory() {
        toggleSettings()
        NotificationCenter.default.post(name: Notification.Name("SwitchToHistory"), object: nil)
    }
    
    @objc private func openSettingsConfig() {
        toggleSettings()
        NotificationCenter.default.post(name: Notification.Name("SwitchToSettings"), object: nil)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
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
        
        let lineHeight: CGFloat = 2.0
        
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
        
        // 截图界面双击 -> 打开图片上传窗口
        ScreenCaptureManager.shared.onOpenUploadWindow = {
            print("DEBUG: AppDelegate received onOpenUploadWindow callback")
            DispatchQueue.main.async {
                print("DEBUG: Calling showImageUploadWindow")
                WindowManager.shared.showImageUploadWindow()
            }
        }
    }
    
    private func handleScreenshotShortcut() {
        print("Screenshot shortcut triggered")
        ScreenCaptureManager.shared.startCapture { image in
            // 截图完成，显示翻译窗口（带图片上下文）
            DispatchQueue.main.async {
                WindowManager.shared.showWithImage(image: image)
            }
        }
    }
    
    @objc func toggleSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: AppDefaults.settingsWindowWidth, height: AppDefaults.settingsWindowHeight),
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
                case .noSelection:
                    break
                }
            }
            
            let finalText = text
            let finalError = error
            
            await MainActor.run {
                WindowManager.shared.show(text: finalText, error: finalError)
            }
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
