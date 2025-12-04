import Cocoa

/// Yisi 项目全域通用的滚动视图
/// 规则：
/// 1. 默认透明背景
/// 2. 强制使用 Overlay 样式（仅滚动时显示，自动隐藏）
/// 3. 集成自定义 Scroller（无轨道背景）
class YisiScrollView: NSScrollView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    private func configure() {
        // 1. 自身透明
        self.drawsBackground = false
        self.backgroundColor = .clear
        self.borderType = .noBorder
        
        // 2. 内容容器透明（关键，否则会有白底）
        self.contentView.drawsBackground = false
        self.contentView.backgroundColor = .clear
        
        // 3. 滚动行为配置
        self.hasVerticalScroller = true
        self.hasHorizontalScroller = false
        self.autohidesScrollers = true
        
        // 4. 核心样式：Overlay (悬浮且自动隐藏)
        self.scrollerStyle = .overlay
        
        // 5. 注入自定义 Scroller
        self.verticalScroller = YisiTransparentScroller()
    }
}

/// 配套的 Scroller：负责剥离轨道背景
private class YisiTransparentScroller: NSScroller {
    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        // 不绘制任何轨道背景，实现完全透明
    }
    
    // 显式声明兼容 Overlay 模式
    override class var isCompatibleWithOverlayScrollers: Bool {
        return true
    }
}
