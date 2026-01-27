import Cocoa
import SwiftUI

/// Screen Capture Manager
/// Implements Shottr-style "Non-Activating Silent Screenshot" architecture.
/// Key design: App remains inactive during capture to avoid window occlusion.
class ScreenCaptureManager {
    static let shared = ScreenCaptureManager()
    
    private var overlayWindow: NSPanel?
    private var overlayView: ScreenCaptureOverlayView?
    
    /// Global ESC key monitor (required since app is not activated)
    private var globalKeyMonitor: Any?
    
    /// Reference to the screen where overlay is displayed (for coordinate conversion)
    private var captureScreen: NSScreen?
    
    /// Capture completion callback
    var onCaptureComplete: ((NSImage) -> Void)?
    
    /// Double-click upload callback
    var onOpenUploadWindow: (() -> Void)?
    
    private init() {}
    
    // MARK: - Public API
    
    /// Start capture mode on the screen containing the mouse cursor
    func startCapture(completion: @escaping (NSImage) -> Void) {
        onCaptureComplete = completion
        
        dismissCapture()
        
        // Detect which screen contains the mouse cursor
        let mouseLocation = NSEvent.mouseLocation
        guard let targetScreen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
                ?? NSScreen.main else {
            return
        }
        captureScreen = targetScreen
        
        let screenRect = targetScreen.frame
        
        // Create non-activating panel covering the target screen
        let panel = NSPanel(
            contentRect: screenRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.level = .screenSaver
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        
        // Create overlay view (uses screen-local coordinates)
        let overlayView = ScreenCaptureOverlayView(frame: CGRect(origin: .zero, size: screenRect.size))
        overlayView.onSelectionComplete = { [weak self] rect in
            self?.captureRegion(rect)
        }
        overlayView.onCancel = { [weak self] in
            self?.dismissCapture()
        }
        overlayView.onOpenUploadWindow = { [weak self] in
            self?.dismissCapture()
            self?.onOpenUploadWindow?()
        }
        
        panel.contentView = overlayView
        
        // CRITICAL: orderFrontRegardless displays the window WITHOUT activating the app
        // This keeps focus on the previously active application
        panel.orderFrontRegardless()
        
        // Since app is NOT activated, we cannot receive keyboard events via responder chain
        // Must use global event monitor for ESC key
        registerGlobalKeyMonitor()
        
        self.overlayWindow = panel
        self.overlayView = overlayView
    }
    
    /// Dismiss capture mode and clean up resources
    func dismissCapture() {
        unregisterGlobalKeyMonitor()
        overlayWindow?.close()
        overlayWindow = nil
        overlayView = nil
        captureScreen = nil
    }
    
    // MARK: - Capture Logic
    
    /// Capture the selected region
    private func captureRegion(_ localRect: CGRect) {
        guard let screen = captureScreen else {
            dismissCapture()
            return
        }
        
        // Step 1: Hide overlay immediately
        overlayWindow?.orderOut(nil)
        
        // Step 2: Wait for WindowServer to refresh the screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            
            // Step 3: Convert coordinates
            // localRect is in overlay's coordinate system (origin at bottom-left of screen)
            // CGWindowListCreateImage uses screen coordinates with origin at top-left
            
            let screenHeight = screen.frame.height
            let screenOrigin = screen.frame.origin
            
            // Convert to global screen coordinates (top-left origin)
            let globalRect = CGRect(
                x: screenOrigin.x + localRect.origin.x,
                y: screenHeight - localRect.origin.y - localRect.height,
                width: localRect.width,
                height: localRect.height
            )
            
            // Step 4: Capture the screen region
            if let cgImage = self.captureScreenRegion(globalRect) {
                let nsImage = NSImage(cgImage: cgImage, size: localRect.size)
                
                // Step 5: NOW activate the app to show results
                NSApp.activate(ignoringOtherApps: true)
                self.onCaptureComplete?(nsImage)
            }
            
            self.dismissCapture()
        }
    }
    
    /// Capture screen region using CGWindowListCreateImage
    @available(macOS, deprecated: 14.0, message: "Using deprecated API for broader macOS compatibility")
    private func captureScreenRegion(_ rect: CGRect) -> CGImage? {
        return CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution]
        )
    }
    
    // MARK: - Global Key Monitor
    
    private func registerGlobalKeyMonitor() {
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // ESC key = keyCode 53
            if event.keyCode == 53 {
                DispatchQueue.main.async {
                    self?.dismissCapture()
                }
            }
        }
    }
    
    private func unregisterGlobalKeyMonitor() {
        if let monitor = globalKeyMonitor {
            NSEvent.removeMonitor(monitor)
            globalKeyMonitor = nil
        }
    }
}
