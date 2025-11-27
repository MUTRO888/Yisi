import Cocoa

class GlobalShortcutManager: ObservableObject {
    static let shared = GlobalShortcutManager()
    
    private var monitor: Any?
    @Published var triggerCount = 0
    
    // The callback to trigger when the shortcut is pressed
    var onShortcutTriggered: (() -> Void)?
    
    private var currentKeyCode: UInt16
    private var currentModifiers: NSEvent.ModifierFlags
    
    private init() {
        // Default shortcut: Command + Control + Y (keyCode 16)
        let savedKeyCode = UserDefaults.standard.integer(forKey: "global_shortcut_key")
        let savedModifiers = UserDefaults.standard.integer(forKey: "global_shortcut_modifiers")
        
        if savedKeyCode != 0 {
            self.currentKeyCode = UInt16(savedKeyCode)
            self.currentModifiers = NSEvent.ModifierFlags(rawValue: UInt(savedModifiers))
        } else {
            self.currentKeyCode = 16 // Y
            self.currentModifiers = [.command, .control]
        }
        
        startMonitoring()
    }
    
    func updateShortcut(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        self.currentKeyCode = keyCode
        self.currentModifiers = modifiers
        
        UserDefaults.standard.set(Int(keyCode), forKey: "global_shortcut_key")
        UserDefaults.standard.set(Int(modifiers.rawValue), forKey: "global_shortcut_modifiers")
    }
    
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
        
        // Check if the pressed key and modifiers match the configured shortcut
        if flags == currentModifiers && event.keyCode == currentKeyCode {
            print("Global shortcut triggered!")
            DispatchQueue.main.async {
                self.triggerCount += 1
                self.onShortcutTriggered?()
            }
        }
    }
    
    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
