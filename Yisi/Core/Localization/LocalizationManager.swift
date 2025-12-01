import SwiftUI
import Combine

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @AppStorage("app_language") var language: String = "en" {
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
        "Provider": "Provider",
        "API Key": "API Key",
        
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
        
        // Prompts
        "Customize the system prompts used for translation.": "Customize the system prompts used for translation.",
        "Coming soon": "Coming soon",
        
        // Shortcuts
        "Activate": "Activate",
        "Record Shortcut": "Record Shortcut",
        "Press keys...": "Press keys...",
        "Press the key combination you want to use to activate Yisi.": "Press the key combination you want to use to activate Yisi.",
        
        // History
        "No History": "No History",
        "Your recent translations will appear here.": "Your recent translations will appear here.",
        
        // Translation View
        "Type or paste text...": "Type or paste text...",
        "Translation will appear here...": "Translation will appear here...",
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
        "Vietnamese": "Vietnamese"
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
        "Provider": "提供商",
        "API Key": "API 密钥",
        
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
        
        // Prompts
        "Customize the system prompts used for translation.": "自定义用于翻译的系统提示词。",
        "Coming soon": "即将推出",
        
        // Shortcuts
        "Activate": "激活",
        "Record Shortcut": "录制快捷键",
        "Press keys...": "按下按键...",
        "Press the key combination you want to use to activate Yisi.": "按下您想要用于激活 Yisi 的组合键。",
        
        // History
        "No History": "暂无历史",
        "Your recent translations will appear here.": "您最近的翻译将显示在这里。",
        
        // Translation View
        "Type or paste text...": "输入或粘贴文本...",
        "Translation will appear here...": "翻译结果将显示在这里...",
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
        "Vietnamese": "越南语"
    ]
}

extension String {
    var localized: String {
        LocalizationManager.shared.localized(self)
    }
}
