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
}
