import Cocoa
import Carbon

private func hotKeyEventHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event = event else { return OSStatus(eventNotHandledErr) }

    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr else { return status }
    guard hotKeyID.signature == GlobalShortcutManager.HotKeyConfig.signature else {
        return OSStatus(eventNotHandledErr)
    }

    guard let userData = userData else { return OSStatus(eventNotHandledErr) }
    let manager = Unmanaged<GlobalShortcutManager>.fromOpaque(userData).takeUnretainedValue()

    switch hotKeyID.id {
    case GlobalShortcutManager.HotKeyConfig.translateID:
        DispatchQueue.main.async {
            manager.triggerCount += 1
            manager.onShortcutTriggered?()
        }
    case GlobalShortcutManager.HotKeyConfig.screenshotID:
        DispatchQueue.main.async {
            manager.onScreenshotTriggered?()
        }
    default:
        return OSStatus(eventNotHandledErr)
    }
    return noErr
}

class GlobalShortcutManager: ObservableObject {
    static let shared = GlobalShortcutManager()

    enum HotKeyConfig {
        static let signature: FourCharCode = {
            let chars: [UInt8] = [0x59, 0x49, 0x53, 0x49] // "YISI"
            return FourCharCode(chars[0]) << 24
                 | FourCharCode(chars[1]) << 16
                 | FourCharCode(chars[2]) << 8
                 | FourCharCode(chars[3])
        }()
        static let translateID: UInt32 = 1
        static let screenshotID: UInt32 = 2
    }

    private var eventHandler: EventHandlerRef?
    private var translateHotKeyRef: EventHotKeyRef?
    private var screenshotHotKeyRef: EventHotKeyRef?

    @Published var triggerCount = 0

    var onShortcutTriggered: (() -> Void)?
    var onScreenshotTriggered: (() -> Void)?

    private var translateKeyCode: UInt16
    private var translateModifiers: NSEvent.ModifierFlags
    private var screenshotKeyCode: UInt16
    private var screenshotModifiers: NSEvent.ModifierFlags

    private init() {
        let t = Self.loadShortcut(
            keyKey: AppDefaults.Keys.globalShortcutKey,
            modKey: AppDefaults.Keys.globalShortcutModifiers,
            defaultKey: AppDefaults.globalShortcutKeyCode,
            defaultMods: AppDefaults.globalShortcutMods
        )
        translateKeyCode = t.keyCode
        translateModifiers = t.modifiers

        let s = Self.loadShortcut(
            keyKey: AppDefaults.Keys.screenshotShortcutKey,
            modKey: AppDefaults.Keys.screenshotShortcutModifiers,
            defaultKey: AppDefaults.screenshotShortcutKeyCode,
            defaultMods: AppDefaults.screenshotShortcutMods
        )
        screenshotKeyCode = s.keyCode
        screenshotModifiers = s.modifiers
    }

    private static func loadShortcut(
        keyKey: String, modKey: String,
        defaultKey: UInt16, defaultMods: NSEvent.ModifierFlags
    ) -> (keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        let savedKey = UserDefaults.standard.integer(forKey: keyKey)
        let savedMods = UserDefaults.standard.integer(forKey: modKey)
        if savedKey != 0 {
            return (UInt16(savedKey), NSEvent.ModifierFlags(rawValue: UInt(savedMods)))
        }
        return (defaultKey, defaultMods)
    }

    // MARK: - Public API

    func updateShortcut(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        translateKeyCode = keyCode
        translateModifiers = modifiers
        UserDefaults.standard.set(Int(keyCode), forKey: AppDefaults.Keys.globalShortcutKey)
        UserDefaults.standard.set(Int(modifiers.rawValue), forKey: AppDefaults.Keys.globalShortcutModifiers)
        registerTranslateHotKey()
    }

    func updateScreenshotShortcut(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        screenshotKeyCode = keyCode
        screenshotModifiers = modifiers
        UserDefaults.standard.set(Int(keyCode), forKey: AppDefaults.Keys.screenshotShortcutKey)
        UserDefaults.standard.set(Int(modifiers.rawValue), forKey: AppDefaults.Keys.screenshotShortcutModifiers)
        registerScreenshotHotKey()
    }

    var currentScreenshotKeyCode: UInt16 { screenshotKeyCode }
    var currentScreenshotModifiers: NSEvent.ModifierFlags { screenshotModifiers }

    // MARK: - Carbon Hot Key Registration

    func startMonitoring() {
        stopMonitoring()
        installEventHandler()
        registerTranslateHotKey()
        registerScreenshotHotKey()
    }

    private func installEventHandler() {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyEventHandler,
            1,
            &eventType,
            selfPointer,
            &eventHandler
        )
    }

    private func registerTranslateHotKey() {
        unregisterTranslateHotKey()
        var hotKeyID = EventHotKeyID(
            signature: HotKeyConfig.signature,
            id: HotKeyConfig.translateID
        )
        let carbonKey = UInt32(translateKeyCode)
        let carbonMods = carbonModifiers(from: translateModifiers)

        RegisterEventHotKey(
            carbonKey,
            carbonMods,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &translateHotKeyRef
        )
    }

    private func unregisterTranslateHotKey() {
        if let ref = translateHotKeyRef {
            UnregisterEventHotKey(ref)
            translateHotKeyRef = nil
        }
    }

    private func registerScreenshotHotKey() {
        unregisterScreenshotHotKey()
        var hotKeyID = EventHotKeyID(
            signature: HotKeyConfig.signature,
            id: HotKeyConfig.screenshotID
        )
        let carbonKey = UInt32(screenshotKeyCode)
        let carbonMods = carbonModifiers(from: screenshotModifiers)

        RegisterEventHotKey(
            carbonKey,
            carbonMods,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &screenshotHotKeyRef
        )
    }

    private func unregisterScreenshotHotKey() {
        if let ref = screenshotHotKeyRef {
            UnregisterEventHotKey(ref)
            screenshotHotKeyRef = nil
        }
    }

    private func stopMonitoring() {
        unregisterTranslateHotKey()
        unregisterScreenshotHotKey()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var mods: UInt32 = 0
        if flags.contains(.command) { mods |= UInt32(cmdKey) }
        if flags.contains(.option)  { mods |= UInt32(optionKey) }
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        if flags.contains(.shift)   { mods |= UInt32(shiftKey) }
        return mods
    }

    deinit {
        stopMonitoring()
    }
}
