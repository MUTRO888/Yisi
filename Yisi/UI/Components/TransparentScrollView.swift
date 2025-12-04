import SwiftUI
import Cocoa

// 1. 定義高度偏好鍵
struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// 2. 重構 TransparentScrollView
struct TransparentScrollView<Content: View>: NSViewRepresentable {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        
        // 保留透明滾動條樣式
        scrollView.verticalScroller = TransparentScroller()
        
        // 使用 AnyView 進行類型擦除，解決類型匹配問題
        let rootView = AnyView(EmptyView())
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        // NSHostingView 默認背景透明，無需設置 drawsBackground
        
        scrollView.documentView = hostingView
        
        // 創建高度約束並保存到 Coordinator
        let heightConstraint = hostingView.heightAnchor.constraint(equalToConstant: 0)
        // 降低優先級以避免佈局衝突（可選，但在動態高度中通常比較安全）
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
        
        context.coordinator.hostingView = hostingView
        context.coordinator.heightConstraint = heightConstraint
        
        // 設置約束：錨定 Top, Leading, Trailing，高度由 heightConstraint 控制
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            // 重要：寬度約束確保內容寬度與滾動視圖一致
            hostingView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor)
        ])
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        // 包裹內容以測量高度
        let wrappedContent = content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: ViewHeightKey.self, value: geo.size.height)
                }
            )
            .onPreferenceChange(ViewHeightKey.self) { newHeight in
                context.coordinator.updateHeight(newHeight)
            }
        
        // 更新 NSHostingView 的根視圖
        if let hostingView = scrollView.documentView as? NSHostingView<AnyView> {
            hostingView.rootView = AnyView(wrappedContent)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        weak var hostingView: NSView?
        var heightConstraint: NSLayoutConstraint?
        
        func updateHeight(_ height: CGFloat) {
            guard let constraint = heightConstraint else { return }
            
            // 向上取整並增加 1pt 緩衝，避免小數精度丟失導致文本截斷
            let adjustedHeight = ceil(height) + 1
            
            // 只有當高度發生顯著變化時才更新約束
            if abs(constraint.constant - adjustedHeight) > 0.1 {
                DispatchQueue.main.async {
                    constraint.constant = adjustedHeight
                    // 強制立即刷新佈局，確保滾動條位置正確
                    self.hostingView?.layoutSubtreeIfNeeded()
                }
            }
        }
    }
}
