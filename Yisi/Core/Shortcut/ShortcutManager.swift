import Cocoa

class GlobalShortcutManager: ObservableObject {
    static let shared = GlobalShortcutManager()
    
    private var monitor: Any?
    @Published var triggerCount = 0
    
    // MARK: - Callbacks
    
    /// 翻译快捷键回调
    var onShortcutTriggered: (() -> Void)?
    
    /// 截图快捷键回调
    var onScreenshotTriggered: (() -> Void)?
    
    // MARK: - Translate Shortcut
    
    private var currentKeyCode: UInt16
    private var currentModifiers: NSEvent.ModifierFlags
    
    // MARK: - Screenshot Shortcut
    
    private var screenshotKeyCode: UInt16
    private var screenshotModifiers: NSEvent.ModifierFlags
    
    private init() {
        // Default translate shortcut: Command + Control + Y (keyCode 16)
        let savedKeyCode = UserDefaults.standard.integer(forKey: "global_shortcut_key")
        let savedModifiers = UserDefaults.standard.integer(forKey: "global_shortcut_modifiers")
        
        if savedKeyCode != 0 {
            self.currentKeyCode = UInt16(savedKeyCode)
            self.currentModifiers = NSEvent.ModifierFlags(rawValue: UInt(savedModifiers))
        } else {
            self.currentKeyCode = 16 // Y
            self.currentModifiers = [.command, .control]
        }
        
        // Default screenshot shortcut: Command + Shift + X (keyCode 7)
        let savedScreenshotKey = UserDefaults.standard.integer(forKey: "screenshot_shortcut_key")
        let savedScreenshotModifiers = UserDefaults.standard.integer(forKey: "screenshot_shortcut_modifiers")
        
        if savedScreenshotKey != 0 {
            self.screenshotKeyCode = UInt16(savedScreenshotKey)
            self.screenshotModifiers = NSEvent.ModifierFlags(rawValue: UInt(savedScreenshotModifiers))
        } else {
            self.screenshotKeyCode = 7 // X
            self.screenshotModifiers = [.command, .shift]
        }
        
        startMonitoring()
    }
    
    // MARK: - Update Shortcuts
    
    func updateShortcut(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        self.currentKeyCode = keyCode
        self.currentModifiers = modifiers
        
        UserDefaults.standard.set(Int(keyCode), forKey: "global_shortcut_key")
        UserDefaults.standard.set(Int(modifiers.rawValue), forKey: "global_shortcut_modifiers")
    }
    
    func updateScreenshotShortcut(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        self.screenshotKeyCode = keyCode
        self.screenshotModifiers = modifiers
        
        UserDefaults.standard.set(Int(keyCode), forKey: "screenshot_shortcut_key")
        UserDefaults.standard.set(Int(modifiers.rawValue), forKey: "screenshot_shortcut_modifiers")
    }
    
    // MARK: - Getters for UI
    
    var currentScreenshotKeyCode: UInt16 { screenshotKeyCode }
    var currentScreenshotModifiers: NSEvent.ModifierFlags { screenshotModifiers }
    
    // MARK: - Monitoring
    
    func startMonitoring() {
        // We need to request accessibility permissions for this to work globally
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            print("Accessibility access not granted")
        }
        
        // Monitor for key down events
        if monitor != nil {
            NSEvent.removeMonitor(monitor!)
        }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleEvent(event)
        }
    }
    
    private func handleEvent(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        // Check translate shortcut
        if flags == currentModifiers && event.keyCode == currentKeyCode {
            print("Global shortcut triggered!")
            DispatchQueue.main.async {
                self.triggerCount += 1
                self.onShortcutTriggered?()
            }
            return
        }
        
        // Check screenshot shortcut
        if flags == screenshotModifiers && event.keyCode == screenshotKeyCode {
            print("Screenshot shortcut triggered!")
            DispatchQueue.main.async {
                self.onScreenshotTriggered?()
            }
        }
    }
    
    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
