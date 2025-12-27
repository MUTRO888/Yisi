import SwiftUI
import Combine

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @AppStorage("app_language") var language: String = "zh" {
        didSet {
            objectWillChange.send()
        }
    }
    
    private init() {}
    
    func localized(_ key: String) -> String {
        let dict = language == "zh" ? zhStrings : enStrings
        return dict[key] ?? key
    }
    
    private let enStrings: [String: String] = [
        // General
        "Settings": "Settings",
        "History": "History",
        "General": "General",
        "Prompts": "Prompts",
        "Shortcuts": "Shortcuts",
        "About": "About",
        "Quit": "Quit",
        
        // API
        "API Service": "API Service",
        "API Service (Image)": "API Service (Image)",
        "Provider": "Provider",
        "API Key": "API Key",
        "Model": "Model",
        
        // Behavior
        "Behavior": "Behavior",
        "Close Mode": "Close Mode",
        "Click Outside": "Click Outside",
        "X Button": "X Button",
        "Esc Key": "Esc Key",
        "Layout": "Layout",
        "Customize Popup Layout": "Customize Popup Layout",
        "Drag the window to position it. Drag the corner to resize.": "Drag the window to position it. Drag the corner to resize.",
        "Cancel": "Cancel",
        "Save": "Save",
        
        // Language & Appearance
        "Language": "Language",
        "Appearance": "Appearance",
        "System": "System",
        "Light": "Light",
        "Dark": "Dark",
        "English": "English",
        "Simplified Chinese": "Simplified Chinese",
        
        // Default Path
        "Default Path": "Default Translation Path",
        "Source": "Source",
        "Target": "Target",
        
        // Image Mode
        "Image": "Image",
        "Apply to Image Mode": "Apply to image mode",
        "Screenshot": "Screenshot",
        "Click to upload image": "Click to upload image",
        "or drag & drop": "or drag & drop",
        "Recognizing image...": "Recognizing image...",
        "AI recognition result will appear here...": "AI recognition result will appear here...",
        "Select an image to recognize": "Select an image to recognize",
        "Select": "Select",
        
        // Screenshot Overlay HUD
        "Drag to select · Double-click to upload · Right-click to cancel": "Drag to select · Double-click to upload · Right-click to cancel",
        
        // Prompts
        "Customize the system prompts used for translation.": "Customize the system prompts used for translation.",
        "Coming soon": "Coming soon",
        
        // Preset Mode
        "启用预设模式": "Enable Preset Mode",
        "关闭时为临时自定义模式；开启后选择预设": "Off: Temporary custom mode; On: Select preset",
        "选择预设": "Select Preset",
        "默认翻译": "Default Translation",
        "自定义预设": "Custom Presets",
        "暂无自定义预设": "No custom presets yet",
        "New Preset": "New Preset",
        "Edit Preset": "Edit Preset",
        "Name": "Name",
        "e.g. Code Audit": "e.g. Code Audit",
        "Input Perception": "Input Perception",
        "Output Instruction": "Output Instruction",
        
        // Custom Prompt Area
        "I perceive this as": "I perceive this as",
        "please": "please",
        "Ancient Poetry": "Ancient Poetry",
        "translate to modern English": "translate to modern English",
        
        // Deep Thinking
        "Thinking": "Thinking",
        "Enable deep reasoning for AI": "Enable deep reasoning for AI",
        
        // Learned Rules
        "Learned Rules": "Learned Rules",
        
        // Shortcuts
        "Activate": "Activate",
        "Record Shortcut": "Record Shortcut",
        "Press keys...": "Press keys...",
        "Press the key combination you want to use to activate Yisi.": "Press the key combination you want to use to activate Yisi.",
        "Press the key combination you want to use.": "Press the key combination you want to use.",
        
        // History
        "No History": "No History",
        "Your recent translations will appear here.": "Your recent translations will appear here.",
        "All": "All",
        "Today": "Today",
        "Yesterday": "Yesterday",
        "This Week": "This Week",
        "Older": "Older",
        
        // Translation View
        "Type or paste text..": "Type or paste text..",
        "Type or paste text...": "Type or paste text...",
        "Translation will appear here...": "Translation will appear here...",
        "翻译结果将显示在这里...": "Translation will appear here...",
        "处理结果将显示在这里...": "Processing result will appear here...",
        "输出结果将显示在这里...": "Output will appear here...",
        "Translate": "Translate",
        "Swap languages": "Swap languages",
        "Open Settings": "Open Settings",
        "Accessibility permission required to capture text.": "Accessibility permission required to capture text.",
        "Auto Detect": "Auto Detect",
        "Traditional Chinese": "Traditional Chinese",
        "Japanese": "Japanese",
        "Korean": "Korean",
        "French": "French",
        "Spanish": "Spanish",
        "German": "German",
        "Russian": "Russian",
        "Arabic": "Arabic",
        "Thai": "Thai",
        "Vietnamese": "Vietnamese",
        
        // Settings - Translation
        "Improve": "Improve",
        "Enable translation improvement": "Edit translations and generate personalized learning rules",
        
        // History additional
        "Load More": "Load More",
        "View Image": "View Image",
        "%d days ago": "%d days ago",
        "Clear All": "Clear All",
        "Clear History": "Clear History",
        "Clear": "Clear",
        "Are you sure you want to delete all history items? This action cannot be undone.": "Are you sure you want to delete all history items? This action cannot be undone.",
        
        // Preset description
        "Standard translation mode, supports Learned Rules": "Standard translation mode, supports Learned Rules",
        
        // Learned Rules content
        "Translation rules learned from your corrections.": "Translation rules learned from your corrections.",
        "No rules learned yet": "No rules learned yet",
        "Edit translations and click Improve to start learning.": "Edit translations and click Improve to start learning."
    ]
    
    private let zhStrings: [String: String] = [
        // General
        "Settings": "设置",
        "History": "历史记录",
        "General": "通用",
        "Prompts": "提示词",
        "Shortcuts": "快捷键",
        "About": "关于",
        "Quit": "退出",
        
        // API
        "API Service": "API 服务",
        "API Service (Image)": "API 服务（图片）",
        "Provider": "提供商",
        "API Key": "API 密钥",
        "Model": "模型",
        
        // Behavior
        "Behavior": "行为",
        "Close Mode": "关闭方式",
        "Click Outside": "点击外部",
        "X Button": "关闭按钮",
        "Esc Key": "Esc 键",
        "Layout": "布局",
        "Customize Popup Layout": "自定义弹窗布局",
        "Drag the window to position it. Drag the corner to resize.": "拖动窗口以调整位置。拖动角落以调整大小。",
        "Cancel": "取消",
        "Save": "保存",
        
        // Language & Appearance
        "Language": "语言",
        "Appearance": "外观",
        "System": "跟随系统",
        "Light": "浅色",
        "Dark": "深色",
        "English": "English",
        "Simplified Chinese": "简体中文",
        
        // Default Path
        "Default Path": "默认翻译路径",
        "Source": "源语言",
        "Target": "目标语言",
        
        // Image Mode
        "Image": "图片",
        "Apply to Image Mode": "应用于图片模式",
        "Screenshot": "截图",
        "Click to upload image": "点击上传图片",
        "or drag & drop": "或拖放图片",
        "Recognizing image...": "正在识别图片...",
        "AI recognition result will appear here...": "AI 识别结果将显示在这里...",
        "Select an image to recognize": "选择要识别的图片",
        "Select": "选择",
        
        // Screenshot Overlay HUD
        "Drag to select · Double-click to upload · Right-click to cancel": "拖拽选区 · 双击上传 · 右键取消",
        
        // Prompts
        "Customize the system prompts used for translation.": "自定义用于翻译的系统提示词。",
        "Coming soon": "即将推出",
        
        // Preset Mode
        "启用预设模式": "启用预设模式",
        "关闭时为临时自定义模式；开启后选择预设": "关闭时为临时自定义模式；开启后选择预设",
        "选择预设": "选择预设",
        "默认翻译": "默认翻译",
        "自定义预设": "自定义预设",
        "暂无自定义预设": "暂无自定义预设",
        "New Preset": "新建预设",
        "Edit Preset": "编辑预设",
        "Name": "名称",
        "e.g. Code Audit": "例如：代码审计",
        "Input Perception": "输入感知",
        "Output Instruction": "输出指令",
        
        // Custom Prompt Area
        "I perceive this as": "这是",
        "please": "请",
        "Ancient Poetry": "古诗词",
        "translate to modern English": "翻译成现代中文",
        
        // Deep Thinking
        "Thinking": "深度思考",
        "Enable deep reasoning for AI": "启用 AI 深度推理",
        
        // Learned Rules (keep as English term)
        "Learned Rules": "Learned Rules",
        
        // Shortcuts
        "Activate": "激活",
        "Record Shortcut": "录制快捷键",
        "Press keys...": "按下按键...",
        "Press the key combination you want to use to activate Yisi.": "按下您想要用于激活 Yisi 的组合键。",
        "Press the key combination you want to use.": "按下您想要使用的组合键。",
        
        // History
        "No History": "暂无历史",
        "Your recent translations will appear here.": "您最近的翻译将显示在这里。",
        "All": "全部",
        "Today": "今天",
        "Yesterday": "昨天",
        "This Week": "本周",
        "Older": "更早",
        
        // Translation View
        "Type or paste text..": "输入或粘贴文本..",
        "Type or paste text...": "输入或粘贴文本...",
        "Translation will appear here...": "翻译结果将显示在这里...",
        "翻译结果将显示在这里...": "翻译结果将显示在这里...",
        "处理结果将显示在这里...": "处理结果将显示在这里...",
        "输出结果将显示在这里...": "输出结果将显示在这里...",
        "Translate": "翻译",
        "Swap languages": "交换语言",
        "Open Settings": "打开设置",
        "Accessibility permission required to capture text.": "需要辅助功能权限以捕获文本。",
        "Auto Detect": "自动检测",
        "Traditional Chinese": "繁体中文",
        "Japanese": "日语",
        "Korean": "韩语",
        "French": "法语",
        "Spanish": "西班牙语",
        "German": "德语",
        "Russian": "俄语",
        "Arabic": "阿拉伯语",
        "Thai": "泰语",
        "Vietnamese": "越南语",
        
        // Settings - Translation  
        "Improve": "智能优化",
        "Enable translation improvement": "支持编辑译文并生成个性化学习规则",
        
        // History additional
        "Load More": "加载更多",
        "View Image": "查看图片",
        "%d days ago": "%d 天前",
        "Clear All": "清空全部",
        "Clear History": "清空历史",
        "Clear": "清空",
        "Are you sure you want to delete all history items? This action cannot be undone.": "确定要删除所有历史记录吗？此操作无法撤销。",
        
        // Preset description
        "Standard translation mode, supports Learned Rules": "标准翻译模式，支持 Learned Rules",
        
        // Learned Rules content
        "Translation rules learned from your corrections.": "从您的修正中学习到的翻译规则。",
        "No rules learned yet": "尚未学习到规则",
        "Edit translations and click Improve to start learning.": "编辑译文并点击智能优化开始学习。"
    ]
}

extension String {
    var localized: String {
        LocalizationManager.shared.localized(self)
    }
}
