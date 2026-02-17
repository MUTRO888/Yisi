import Cocoa

class GlobalShortcutManager: ObservableObject {
    static let shared = GlobalShortcutManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var permissionTimer: Timer?

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
            keyKey: AppDefaults.Keys.globalShortcutKey,
            modKey: AppDefaults.Keys.globalShortcutModifiers,
            defaultKey: AppDefaults.globalShortcutKeyCode,
            defaultMods: AppDefaults.globalShortcutMods
        )

        screenshotShortcut = Self.loadShortcut(
            keyKey: AppDefaults.Keys.screenshotShortcutKey,
            modKey: AppDefaults.Keys.screenshotShortcutModifiers,
            defaultKey: AppDefaults.screenshotShortcutKeyCode,
            defaultMods: AppDefaults.screenshotShortcutMods
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
        UserDefaults.standard.set(Int(keyCode), forKey: AppDefaults.Keys.globalShortcutKey)
        UserDefaults.standard.set(Int(modifiers.rawValue), forKey: AppDefaults.Keys.globalShortcutModifiers)
    }

    func updateScreenshotShortcut(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        screenshotShortcut = Shortcut(keyCode: keyCode, modifiers: modifiers)
        UserDefaults.standard.set(Int(keyCode), forKey: AppDefaults.Keys.screenshotShortcutKey)
        UserDefaults.standard.set(Int(modifiers.rawValue), forKey: AppDefaults.Keys.screenshotShortcutModifiers)
    }

    var currentScreenshotKeyCode: UInt16 { screenshotShortcut.keyCode }
    var currentScreenshotModifiers: NSEvent.ModifierFlags { screenshotShortcut.modifiers }

    // MARK: - Event Tap

    func startMonitoring() {
        permissionTimer?.invalidate()
        permissionTimer = nil
        stopMonitoring()

        guard AXIsProcessTrusted() else {
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
            AXIsProcessTrustedWithOptions(options)
            waitForAccessibilityPermission()
            return
        }

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

    private func waitForAccessibilityPermission() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            if AXIsProcessTrusted() {
                timer.invalidate()
                self?.permissionTimer = nil
                self?.startMonitoring()
            }
        }
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
            return nil
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
        permissionTimer?.invalidate()
        stopMonitoring()
    }
}
