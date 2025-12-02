import Foundation

/// PromptCoordinator: 提示词协调器
/// 职责：
/// - 根据当前模式选择合适的 Builder
/// - 统一的入口点，简化调用方逻辑
/// - 清晰的职责分离
class PromptCoordinator {
    
    // MARK: - Builders
    
    private let translationBuilder = TranslationPromptBuilder()
    private let presetBuilder = PresetPromptBuilder()
    private let customBuilder = CustomPromptBuilder()
    
    // MARK: - Singleton
    
    static let shared = PromptCoordinator()
    private init() {}
    
    // MARK: - Public Interface
    
    /// 根据模式生成对应的系统提示词
    /// - Parameter mode: 提示词模式（翻译/预设/临时自定义）
    /// - Returns: 完整的系统提示词
    func generateSystemPrompt(for mode: PromptMode, withLearnedRules: Bool = true) -> String {
        switch mode {
        case .defaultTranslation:
            // 翻译模式：使用翻译Builder + Learned Rules
            return translationBuilder.buildSystemPrompt(withLearnedRules: withLearnedRules, preset: nil)
            
        case .userPreset(let preset):
            // 预设模式：使用预设Builder（不含Learned Rules）
            return presetBuilder.buildSystemPrompt(preset: preset)
            
        case .temporaryCustom:
            // 临时自定义：这个需要从外部传入input/output
            // 暂时返回默认，后续会调整
            return customBuilder.buildSystemPrompt(inputContext: nil, outputRequirement: nil)
        }
    }
    
    /// 生成临时自定义任务的系统提示词
    /// - Parameters:
    ///   - inputContext: 用户输入的任务理解
    ///   - outputRequirement: 用户期望的输出
    /// - Returns: 完整的系统提示词
    func generateCustomPrompt(inputContext: String?, outputRequirement: String?) -> String {
        return customBuilder.buildSystemPrompt(inputContext: inputContext, outputRequirement: outputRequirement)
    }
    
    /// 生成用户提示词（包含文本和语言信息）
    /// - Parameters:
    ///   - text: 待处理的文本
    ///   - sourceLanguage: 源语言
    ///   - targetLanguage: 目标语言
    /// - Returns: 用户提示词
    func generateUserPrompt(text: String, sourceLanguage: String, targetLanguage: String) -> String {
        var prompt = "Translate the following text to \(targetLanguage)."
        if sourceLanguage != "Auto Detect" {
            prompt = "Translate the following text from \(sourceLanguage) to \(targetLanguage)."
        }
        
        prompt += "\n\nInput Text:\n\(text)"
        
        return prompt
    }
}
