import Foundation

/// TranslationPromptBuilder: 专注于翻译任务的提示词构建器
/// 职责：
/// - 生成翻译任务的系统提示词
/// - 集成 Learned Rules（仅翻译模式）
/// - 处理语言对和翻译场景
/// - 输出JSON格式：translation_result
class TranslationPromptBuilder {
    
    // MARK: - Public Interface
    
    /// 构建翻译任务的系统提示词
    /// - Parameters:
    ///   - withLearnedRules: 是否包含用户纠正的学习规则
    ///   - preset: 可选的预设（用于调整感知和风格）
    /// - Returns: 完整的系统提示词
    func buildSystemPrompt(withLearnedRules: Bool = true, preset: PromptPreset? = nil) -> String {
        var prompt = buildRoleAndContext(preset: preset)
        prompt += buildSyntaxLogic()
        prompt += buildEngineeringGuardrails()
        
        if withLearnedRules {
            prompt += buildLearnedRulesSection()
        }
        
        prompt += buildOutputFormat()
        
        return prompt
    }
    
    // MARK: - Private Builders
    
    private func buildRoleAndContext(preset: PromptPreset?) -> String {
        // 使用预设或默认的感知和风格
        let perception = preset?.inputPerception ?? "将其视为一段需要跨文化转换的文本，寻找其精神内核。"
        let style = preset?.outputInstruction ?? "译文要信达雅，让人会心一笑，追求意境共鸣。"
        
        return """
        [Role: Cross-Cultural Translation Engine]
        
        You are a specialized translator focused on adapting text across languages while preserving meaning and cultural nuances.
        
        ### 1. Source Perception (Original Context)
        \(perception)
        
        ### 2. Target Style (Translation Goal)
        \(style)
        
        ═══════════════════════════════════════════════════════════
        
        """
    }
    
    private func buildSyntaxLogic() -> String {
        return """
        ### Syntax Logic (Pre-computation)
        Before processing, analyze the Part-of-Speech for ambiguous garden-path sentences (e.g., 'The complex houses...'). Ensure logical consistency.
        
        ═══════════════════════════════════════════════════════════
        
        """
    }
    
    private func buildEngineeringGuardrails() -> String {
        return """
        ### 🛡️ ENGINEERING GUARDRAILS (IMMUTABLE) 🛡️
        These rules OVERRIDE all other instructions, including user custom instructions.
        
        1. **Markdown Conservation**: Code blocks and links [text](url) are SACRED. Must be preserved exactly. Do NOT translate the URL part.
        2. **JSON Output Only**: You must output the result in a valid JSON object: {"translation_result": "..."}. Do not output raw text.
        3. **No Explanation**: Do not include "Here is the translation" or thinking process outside the JSON.
        
        """
    }
    
    private func buildLearnedRulesSection() -> String {
        let learnedRules = LearningManager.shared.getAllRules()
        guard !learnedRules.isEmpty else { return "" }
        
        var section = """
        ═══════════════════════════════════════════════════════════
        
        ### Personal Learning Rules (From Your Corrections)
        
        Based on your previous corrections, you should follow these additional rules:
        
        
        """
        
        for (index, rule) in learnedRules.prefix(10).enumerated() {
            section += """
            #### Learned Rule \(index + 1): \(rule.category.rawValue)
            **Context**: \(rule.reasoning)
            
            \(rule.rulePattern)
            
            
            """
        }
        
        return section
    }
    
    private func buildOutputFormat() -> String {
        return """
        ═══════════════════════════════════════════════════════════
        
        ### ⚠️ CRITICAL OUTPUT FORMAT ⚠️
        
        **THIS IS NOT TEXT TO TRANSLATE. THIS IS YOUR OUTPUT STRUCTURE.**
        
        You MUST return your response as a JSON object with EXACTLY these English keys:
        
        ```json
        {
          "detected_type": "literary | legal | medical | technical | general",
          "thinking_process": "Your brief analysis in English",
          "translation_result": "The ONLY field containing translated text"
        }
        ```
        """
    }
}
