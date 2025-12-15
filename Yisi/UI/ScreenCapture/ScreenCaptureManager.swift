import Cocoa
import SwiftUI

/// 屏幕截图管理器
/// 负责全屏 Overlay 窗口的生命周期管理
class ScreenCaptureManager {
    static let shared = ScreenCaptureManager()
    
    private var overlayWindow: NSPanel?
    private var overlayView: ScreenCaptureOverlayView?
    
    /// 截图完成回调
    var onCaptureComplete: ((NSImage) -> Void)?
    
    /// 用户选择打开上传窗口的回调（双击触发）
    var onOpenUploadWindow: (() -> Void)?
    
    private init() {}
    
    /// 显示截图 Overlay
    func startCapture(completion: @escaping (NSImage) -> Void) {
        // 保存回调
        onCaptureComplete = completion
        
        // 关闭已有窗口
        dismissCapture()
        
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.frame
        
        // 创建全屏透明 Panel
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
        
        // 创建 Overlay View
        let overlayView = ScreenCaptureOverlayView(frame: screenRect)
        overlayView.onSelectionComplete = { [weak self] rect in
            self?.captureRegion(rect)
        }
        overlayView.onCancel = { [weak self] in
            self?.dismissCapture()
        }
        overlayView.onOpenUploadWindow = { [weak self] in
            print("DEBUG: onOpenUploadWindow triggered in OverlayView")
            self?.dismissCapture()
            print("DEBUG: About to call Manager.onOpenUploadWindow, is nil? \(self?.onOpenUploadWindow == nil)")
            self?.onOpenUploadWindow?()
        }
        
        panel.contentView = overlayView
        panel.makeKeyAndOrderFront(nil)
        
        // 激活应用以接收键盘事件
        NSApp.activate(ignoringOtherApps: true)
        
        self.overlayWindow = panel
        self.overlayView = overlayView
    }
    
    /// 关闭截图 Overlay
    func dismissCapture() {
        overlayWindow?.close()
        overlayWindow = nil
        overlayView = nil
    }
    
    /// 截取指定区域
    private func captureRegion(_ rect: CGRect) {
        // 先关闭 Overlay 避免截到 Overlay 本身
        overlayWindow?.orderOut(nil)
        
        // 稍微延迟确保 Overlay 完全隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            // 转换坐标系：SwiftUI/AppKit 从左下角开始，CGWindowList 从左上角开始
            guard let screen = NSScreen.main else {
                self.dismissCapture()
                return
            }
            
            let screenHeight = screen.frame.height
            let cgRect = CGRect(
                x: rect.origin.x,
                y: screenHeight - rect.origin.y - rect.height,
                width: rect.width,
                height: rect.height
            )
            
            // 使用 CGWindowListCreateImage 截图
            // Note: CGWindowListCreateImage is deprecated in macOS 14.0 but still functional.
            // We keep it for broader compatibility with older macOS versions.
            // ScreenCaptureKit alternative requires macOS 12.3+ and more complex setup.
            if let cgImage = self.captureScreenRegion(cgRect) {
                let nsImage = NSImage(cgImage: cgImage, size: rect.size)
                self.onCaptureComplete?(nsImage)
            }
            
            self.dismissCapture()
        }
    }
    
    /// Helper function to capture screen region
    /// Using @available to acknowledge the deprecation while maintaining compatibility
    @available(macOS, deprecated: 14.0, message: "Using deprecated API for broader macOS compatibility")
    private func captureScreenRegion(_ rect: CGRect) -> CGImage? {
        return CGWindowListCreateImage(
            rect,
            .optionOnScreenBelowWindow,
            kCGNullWindowID,
            [.bestResolution]
        )
    }
}
