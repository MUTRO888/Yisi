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

    func captureSelectedText() -> Result<String, CaptureError> {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        if !AXIsProcessTrustedWithOptions(options) {
            return .failure(.permissionDenied)
        }
        
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?
        
        let error = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        if error == .success, let focusedElement = focusedElement {
            let element = focusedElement as! AXUIElement
            var selectedText: AnyObject?
            
            let textError = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText)
            
            if textError == .success, let text = selectedText as? String {
                return .success(text)
            } else {
                return .failure(.noSelection)
            }
        } else {
            return .failure(.noFocusedElement)
        }
    }
}
