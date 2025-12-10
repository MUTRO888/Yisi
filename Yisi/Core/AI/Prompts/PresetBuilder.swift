import Foundation

/// PresetPromptBuilder: 用户保存的自定义预设提示词构建器
/// 职责：
/// - 使用用户保存的预设配置
/// - 不包含 Learned Rules（这是用户定义的独立任务）
/// - 输出JSON格式：result
class PresetPromptBuilder {
    
    // MARK: - Public Interface
    
    /// 构建用户预设任务的系统提示词
    /// - Parameter preset: 用户保存的预设配置
    /// - Returns: 完整的系统提示词
    func buildSystemPrompt(preset: PromptPreset) -> String {
        var prompt = buildRoleAndTask(preset: preset)
        
        // AI 自动检测语言，用户指定优先
        prompt += buildLanguageGuidance()
        
        prompt += buildEngineeringGuardrails()
        prompt += buildOutputFormat()
        
        return prompt
    }
    
    // MARK: - Private Builders
    
    private func buildRoleAndTask(preset: PromptPreset) -> String {
        return """
        [Role: Specialized Text Processor]
        
        You are configured to process text according to user-defined parameters.
        
        ### User-Defined Configuration
        
        **Input Context**: \(preset.inputPerception)
        
        **Output Requirement**: \(preset.outputInstruction)
        
        ═══════════════════════════════════════════════════════════
        
        """
    }
    
    /// 构建语言引导（优先用户指定，否则 AI 自动检测）
    private func buildLanguageGuidance() -> String {
        return """
        ### 🌐 LANGUAGE GUIDANCE 🌐
        
        **语言选择优先级**：
        1. 如果用户在预设配置中明确指定了输出语言，请按配置要求输出
        2. 如果没有指定语言，请自动检测输入文本/图片的语言，并用**相同语言**回复
        
        ═══════════════════════════════════════════════════════════
        
        """
    }
    
    private func buildEngineeringGuardrails() -> String {
        return """
        ### 🛡️ ENGINEERING GUARDRAILS (IMMUTABLE) 🛡️
        
        1. **Plain Text Only**: Your result MUST be plain text. DO NOT use HTML tags, links, or any markup.
        2. **JSON Output Only**: You must output the result in a valid JSON object: {"result": "..."}. Do not output raw text.
        3. **No Meta-Commentary**: Do not include phrases like "Here is the result" outside the JSON.
        4. **Concise & Direct**: Answer directly without explanations unless specifically requested.
        
        """
    }
    
    private func buildOutputFormat() -> String {
        return """
        ═══════════════════════════════════════════════════════════
        
        ### ⚠️ CRITICAL OUTPUT FORMAT ⚠️
        
        You MUST return your response as a JSON object with EXACTLY these English keys:
        
        ```json
        {
          "task_type": "Brief description of what you did",
          "thinking_process": "Your brief analysis in English",
          "result": "PLAIN TEXT answer only - NO HTML, NO LINKS, NO MARKUP"
        }
        ```
        
        REMEMBER: The "result" field must contain ONLY plain text.
        """
    }
    
    /// 构建预设图片处理的提示词
    /// - Parameter preset: 用户保存的预设配置
    /// - Returns: 图片处理系统提示词
    func buildImagePrompt(preset: PromptPreset) -> String {
        return """
        [预设图片处理任务]
        
        ═══════════════════════════════════════════════════════════
        
        ### 上下文理解
        
        \(preset.inputPerception)
        
        ═══════════════════════════════════════════════════════════
        
        ### 处理要求
        
        \(preset.outputInstruction)
        
        ═══════════════════════════════════════════════════════════
        
        ### 🛡️ ENGINEERING GUARDRAILS 🛡️
        
        1. **Plain Text Result**: Your result MUST be plain text. NO special tokens, NO HTML.
        2. **JSON Output Only**: You MUST output in JSON format.
        3. **No Meta-Commentary**: Do not include phrases like "Here is the result" outside JSON.
        
        ═══════════════════════════════════════════════════════════
        
        ### ⚠️ CRITICAL OUTPUT FORMAT ⚠️
        
        You MUST return your response as a JSON object:
        
        ```json
        {
          "result": "Your answer in plain text - NO HTML, NO special tokens like <|begin_of_box|>"
        }
        ```
        """
    }
}
