import Cocoa
import SwiftUI

class LightWindow: NSPanel {
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: backing,
            defer: flag
        )
        
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        
        // Hide traffic light buttons for a cleaner look
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

class WindowManager: ObservableObject {
    static let shared = WindowManager()
    private var window: LightWindow?
    private var localMonitor: Any?
    
    private init() {}
    
    func show(text: String, error: String? = nil) {
        if window == nil {
            let contentView = TranslationView(originalText: text, errorMessage: error)
            let hostingController = NSHostingController(rootView: contentView)
            
            let windowSize = NSSize(width: 750, height: 480)
            let screenRect = NSScreen.main?.visibleFrame ?? NSRect.zero
            let centerPoint = NSPoint(x: screenRect.midX - windowSize.width / 2,
                                      y: screenRect.midY - windowSize.height / 2)
            
            window = LightWindow(
                contentRect: NSRect(origin: centerPoint, size: windowSize),
                backing: .buffered,
                defer: false
            )
            window?.contentViewController = hostingController
            
            // Close on click outside
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
                if let window = self?.window, event.window != window {
                    self?.close()
                    return nil
                }
                return event
            }
        } else {
             let contentView = TranslationView(originalText: text, errorMessage: error)
             window?.contentViewController = NSHostingController(rootView: contentView)
        }
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func close() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        window?.close()
        window = nil
    }
}
