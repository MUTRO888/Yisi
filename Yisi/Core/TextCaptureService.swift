import Cocoa

class TextCaptureService {
    static let shared = TextCaptureService()
    
    private init() {}
    
    func captureSelectedText() -> String? {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?
        
        // Get the focused UI element
        let error = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        if error == .success, let focusedElement = focusedElement {
            let element = focusedElement as! AXUIElement
            var selectedText: AnyObject?
            
            // Get the selected text from the focused element
            let textError = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText)
            
            if textError == .success, let text = selectedText as? String {
                return text
            } else {
                print("Failed to get selected text: \(textError.rawValue)")
            }
        } else {
            print("Failed to get focused element: \(error.rawValue)")
        }
        
        return nil
    }
}
