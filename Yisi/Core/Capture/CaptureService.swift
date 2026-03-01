import Cocoa

class TextCaptureService {
    static let shared = TextCaptureService()
    
    private init() {}
    
    enum CaptureError: Error {
        case permissionDenied
        case noSelection
    }

    func captureSelectedText() async -> Result<String, CaptureError> {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        guard AXIsProcessTrustedWithOptions(options) else {
            return .failure(.permissionDenied)
        }
        
        // Try Accessibility API first (fastest, least intrusive)
        if let text = captureViaAccessibility(), !text.isEmpty {
            return .success(text)
        }
        
        // Fallback to clipboard simulation
        if let text = await captureViaClipboard(), !text.isEmpty {
            return .success(text)
        }
        
        return .failure(.noSelection)
    }
    
    // MARK: - Accessibility API
    
    /// Public synchronous accessor for immediate AX text capture.
    /// Must be called on the main thread while the source app still has focus.
    func captureViaAccessibilityPublic() -> String? {
        guard AXIsProcessTrusted() else { return nil }
        return captureViaAccessibility()
    }
    
    private func captureViaAccessibility() -> String? {
        let systemWide = AXUIElementCreateSystemWide()
        var focused: AnyObject?
        
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let element = focused as! AXUIElement? else {
            return nil
        }
        
        var selectedText: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText) == .success,
              let text = selectedText as? String else {
            return nil
        }
        
        return text
    }
    
    // MARK: - Clipboard Simulation
    
    private func captureViaClipboard() async -> String? {
        let pasteboard = NSPasteboard.general
        let savedItems = saveClipboard(pasteboard)
        let originalCount = pasteboard.changeCount
        
        // Try AppleScript (works for editable fields)
        executeAppleScriptCopy()
        if let text = await waitForClipboardChange(originalCount, maxAttempts: 3, intervalMs: 20) {
            restoreClipboard(pasteboard, items: savedItems)
            return text
        }
        
        // Fallback to CGEvent
        executeCGEventCopy()
        let text = await waitForClipboardChange(originalCount, maxAttempts: 5, intervalMs: 30)
        restoreClipboard(pasteboard, items: savedItems)
        return text
    }
    
    private func waitForClipboardChange(_ originalCount: Int, maxAttempts: Int, intervalMs: Int) async -> String? {
        let pasteboard = NSPasteboard.general
        for _ in 0..<maxAttempts {
            try? await Task.sleep(nanoseconds: UInt64(intervalMs) * 1_000_000)
            if pasteboard.changeCount != originalCount {
                return pasteboard.string(forType: .string)
            }
        }
        return nil
    }
    
    private func saveClipboard(_ pasteboard: NSPasteboard) -> [NSPasteboardItem] {
        guard let items = pasteboard.pasteboardItems else { return [] }
        return items.compactMap { item in
            let newItem = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    newItem.setData(data, forType: type)
                }
            }
            return newItem
        }
    }
    
    private func restoreClipboard(_ pasteboard: NSPasteboard, items: [NSPasteboardItem]) {
        guard !items.isEmpty else { return }
        pasteboard.clearContents()
        pasteboard.writeObjects(items)
    }
    
    // MARK: - Copy Simulation Methods
    
    private func executeAppleScriptCopy() {
        let script = """
        tell application "System Events"
            keystroke "c" using command down
        end tell
        """
        NSAppleScript(source: script)?.executeAndReturnError(nil)
    }
    
    private func executeCGEventCopy() {
        let source = CGEventSource(stateID: .hidSystemState)
        let events: [(key: CGKeyCode, down: Bool, flags: CGEventFlags)] = [
            (0x37, true, .maskCommand),   // Cmd down
            (0x08, true, .maskCommand),   // C down
            (0x08, false, .maskCommand),  // C up
            (0x37, false, [])             // Cmd up
        ]
        
        for e in events {
            let event = CGEvent(keyboardEventSource: source, virtualKey: e.key, keyDown: e.down)
            event?.flags = e.flags
            event?.post(tap: .cghidEventTap)
        }
    }
}
