 import Cocoa

class TextCaptureService {
    static let shared = TextCaptureService()
    
    private init() {}
    
    enum CaptureError: Error {
        case permissionDenied
        case noFocusedElement
        case noSelection
        case other(String)
    }

    func captureSelectedText() async -> Result<String, CaptureError> {
        // 1. Check permissions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        if !AXIsProcessTrustedWithOptions(options) {
            return .failure(.permissionDenied)
        }
        
        // 2. Try Accessibility API first (fastest, least intrusive)
        // AX calls should be fast, but running them on main thread is okay.
        if let axText = captureViaAccessibility(), !axText.isEmpty {
            print("Captured via AX: \(axText.prefix(20))...")
            return .success(axText)
        }
        
        // 3. Fallback to Cmd+C (Robust)
        print("AX failed or empty, falling back to Cmd+C...")
        if let copyText = await captureViaCopyShortcut(), !copyText.isEmpty {
            print("Captured via Cmd+C: \(copyText.prefix(20))...")
            return .success(copyText)
        }
        
        return .failure(.noSelection)
    }
    
    private func captureViaAccessibility() -> String? {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?
        
        let error = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        if error == .success, let focusedElement = focusedElement {
            let element = focusedElement as! AXUIElement
            var selectedText: AnyObject?
            
            let textError = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText)
            
            if textError == .success, let text = selectedText as? String {
                return text
            }
        }
        return nil
    }
    
    private func captureViaCopyShortcut() async -> String? {
        let pasteboard = NSPasteboard.general
        
        // 1. Save current clipboard content manually (NSPasteboardItem does not support copy())
        let oldItems = saveClipboard(pasteboard)
        let oldChangeCount = pasteboard.changeCount
        
        // 2. Simulate Cmd+C
        simulateCommandC()
        
        // 3. Wait for clipboard to update (with timeout)
        var attempts = 0
        while pasteboard.changeCount == oldChangeCount && attempts < 10 {
            try? await Task.sleep(nanoseconds: 50 * 1_000_000) // 50ms
            attempts += 1
        }
        
        // 4. Read new content
        var capturedText: String? = nil
        if pasteboard.changeCount != oldChangeCount {
            capturedText = pasteboard.string(forType: .string)
        }
        
        // 5. Restore old clipboard content
        if !oldItems.isEmpty {
            pasteboard.clearContents()
            pasteboard.writeObjects(oldItems)
        }
        
        return capturedText
    }
    
    private func saveClipboard(_ pasteboard: NSPasteboard) -> [NSPasteboardItem] {
        guard let items = pasteboard.pasteboardItems else { return [] }
        var savedItems: [NSPasteboardItem] = []
        
        for item in items {
            let newItem = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    newItem.setData(data, forType: type)
                }
            }
            savedItems.append(newItem)
        }
        return savedItems
    }
    
    private func simulateCommandC() {
        let source = CGEventSource(stateID: .hidSystemState)
        
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true) // kVK_Command
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)   // kVK_ANSI_C
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        cmdDown?.flags = .maskCommand
        cDown?.flags = .maskCommand
        cUp?.flags = .maskCommand
        cmdUp?.flags = []
        
        cmdDown?.post(tap: .cghidEventTap)
        cDown?.post(tap: .cghidEventTap)
        cUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
    }
}
