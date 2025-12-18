import Cocoa

class GlobalShortcutManager: ObservableObject {
    static let shared = GlobalShortcutManager()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    @Published var triggerCount = 0
    
    var onShortcutTriggered: (() -> Void)?
    var onScreenshotTriggered: (() -> Void)?
    
    private var translateShortcut: Shortcut
    private var screenshotShortcut: Shortcut
    
    private struct Shortcut {
        var keyCode: UInt16
        var modifiers: NSEvent.ModifierFlags
        
        func matches(keyCode: UInt16, flags: CGEventFlags) -> Bool {
            guard self.keyCode == keyCode else { return false }
            
            var eventModifiers: NSEvent.ModifierFlags = []
            if flags.contains(.maskCommand) { eventModifiers.insert(.command) }
            if flags.contains(.maskControl) { eventModifiers.insert(.control) }
            if flags.contains(.maskAlternate) { eventModifiers.insert(.option) }
            if flags.contains(.maskShift) { eventModifiers.insert(.shift) }
            
            let clean = eventModifiers.intersection(.deviceIndependentFlagsMask)
            let target = modifiers.intersection(.deviceIndependentFlagsMask)
            return clean == target
        }
    }
    
    private init() {
        translateShortcut = Self.loadShortcut(
            keyKey: "global_shortcut_key",
            modKey: "global_shortcut_modifiers",
            defaultKey: 16,  // Y
            defaultMods: [.command, .control]
        )
        
        screenshotShortcut = Self.loadShortcut(
            keyKey: "screenshot_shortcut_key",
            modKey: "screenshot_shortcut_modifiers",
            defaultKey: 7,   // X
            defaultMods: [.command, .shift]
        )
        
        startMonitoring()
    }
    
    private static func loadShortcut(keyKey: String, modKey: String, defaultKey: UInt16, defaultMods: NSEvent.ModifierFlags) -> Shortcut {
        let savedKey = UserDefaults.standard.integer(forKey: keyKey)
        let savedMods = UserDefaults.standard.integer(forKey: modKey)
        
        if savedKey != 0 {
            return Shortcut(keyCode: UInt16(savedKey), modifiers: NSEvent.ModifierFlags(rawValue: UInt(savedMods)))
        }
        return Shortcut(keyCode: defaultKey, modifiers: defaultMods)
    }
    
    // MARK: - Public API
    
    func updateShortcut(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        translateShortcut = Shortcut(keyCode: keyCode, modifiers: modifiers)
        UserDefaults.standard.set(Int(keyCode), forKey: "global_shortcut_key")
        UserDefaults.standard.set(Int(modifiers.rawValue), forKey: "global_shortcut_modifiers")
    }
    
    func updateScreenshotShortcut(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        screenshotShortcut = Shortcut(keyCode: keyCode, modifiers: modifiers)
        UserDefaults.standard.set(Int(keyCode), forKey: "screenshot_shortcut_key")
        UserDefaults.standard.set(Int(modifiers.rawValue), forKey: "screenshot_shortcut_modifiers")
    }
    
    var currentScreenshotKeyCode: UInt16 { screenshotShortcut.keyCode }
    var currentScreenshotModifiers: NSEvent.ModifierFlags { screenshotShortcut.modifiers }
    
    // MARK: - Event Tap
    
    func startMonitoring() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        AXIsProcessTrustedWithOptions(options)
        
        stopMonitoring()
        
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (_, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let manager = Unmanaged<GlobalShortcutManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(type: type, event: event)
            },
            userInfo: selfPointer
        )
        
        guard let tap = eventTap else { return }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
    
    private func stopMonitoring() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
        }
        eventTap = nil
        runLoopSource = nil
    }
    
    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        
        if translateShortcut.matches(keyCode: keyCode, flags: flags) {
            DispatchQueue.main.async {
                self.triggerCount += 1
                self.onShortcutTriggered?()
            }
            return nil  // Consume event to preserve text selection
        }
        
        if screenshotShortcut.matches(keyCode: keyCode, flags: flags) {
            DispatchQueue.main.async {
                self.onScreenshotTriggered?()
            }
            return nil
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    deinit {
        stopMonitoring()
    }
}
