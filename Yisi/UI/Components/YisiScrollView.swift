import Cocoa

/// Yisi 项目全域通用的滚动视图
/// 规则：
/// 1. 默认透明背景
/// 2. 强制使用 Overlay 样式（仅滚动时显示，自动隐藏）
/// 3. 集成自定义 Scroller（无轨道背景）
/// 4. 暴力锁定属性，防止系统或外部修改
class YisiScrollView: NSScrollView {
    
    // MARK: - Explicit Property Locks
    // 通过重写属性 Setter，彻底阻断任何试图修改样式的尝试
    
    override var scrollerStyle: NSScroller.Style {
        get { .overlay }
        set { super.scrollerStyle = .overlay }
    }
    
    override var autohidesScrollers: Bool {
        get { true }
        set { super.autohidesScrollers = true }
    }
    
    override var hasVerticalScroller: Bool {
        get { true }
        set { super.hasVerticalScroller = true }
    }
    
    override var hasHorizontalScroller: Bool {
        get { false }
        set { super.hasHorizontalScroller = false }
    }
    
    override var drawsBackground: Bool {
        get { false }
        set { super.drawsBackground = false }
    }
    
    // MARK: - Initialization
    
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
        super.drawsBackground = false
        self.backgroundColor = .clear
        self.borderType = .noBorder
        
        // 2. 内容容器透明
        self.contentView.drawsBackground = false
        self.contentView.backgroundColor = .clear
        
        // 3. 注入自定义 Scroller
        let scroller = YisiTransparentScroller()
        self.verticalScroller = scroller
        
        // 4. 初始属性设置 (虽然 Setter 已经被锁定，但首次设置是个好习惯)
        super.scrollerStyle = .overlay
        super.autohidesScrollers = true
        super.hasVerticalScroller = true
        super.hasHorizontalScroller = false
        self.scrollerKnobStyle = .default
    }
    
    // 确保 Layer 后备存储始终启用
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.wantsLayer = true
        self.contentView.wantsLayer = true
    }
}

/// 配套的 Scroller：强制实现 Overlay 自动隐藏行为
private class YisiTransparentScroller: NSScroller {
    
    // 锁定样式
    override var scrollerStyle: NSScroller.Style {
        get { .overlay }
        set { super.scrollerStyle = .overlay }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.wantsLayer = true
        super.scrollerStyle = .overlay
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
