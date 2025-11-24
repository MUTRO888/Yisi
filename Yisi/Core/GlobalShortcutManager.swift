import Cocoa

class GlobalShortcutManager: ObservableObject {
    private var monitor: Any?
    @Published var triggerCount = 0
    
    // The callback to trigger when the shortcut is pressed
    var onShortcutTriggered: (() -> Void)?
    
    init() {
        // Default shortcut: Command + Control + Y (for Yisi)
        // In a real app, this would be configurable
        startMonitoring()
    }
    
    func startMonitoring() {
        // We need to request accessibility permissions for this to work globally
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            print("Accessibility access not granted")
        }
        
        // Monitor for key down events
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleEvent(event)
        }
    }
    
    private func handleEvent(_ event: NSEvent) {
        // Check for Command + Control + Y
        // Modifier flags: .command and .control
        // Key code for 'Y' is 16 (QWERTY)
        
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags == [.command, .control] && event.keyCode == 16 {
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
