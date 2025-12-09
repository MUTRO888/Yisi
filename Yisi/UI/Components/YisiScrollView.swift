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
        // 0. 启用 Layer 支持（关键：混合渲染中 overlay 样式需要 layer-backing）
        self.wantsLayer = true
        self.contentView.wantsLayer = true
        
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

/// 配套的 Scroller：强制实现 Overlay 自动隐藏行为
private class YisiTransparentScroller: NSScroller {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        // 强制 Overlay 模式（无视系统设置）
        self.scrollerStyle = .overlay
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.scrollerStyle = .overlay
    }
    
    // 不绘制轨道背景（实现透明轨道）
    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        // 空实现：完全透明轨道
    }
    
    // 声明兼容 Overlay 模式
    override class var isCompatibleWithOverlayScrollers: Bool {
        return true
    }
}
