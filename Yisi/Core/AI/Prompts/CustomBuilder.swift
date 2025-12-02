import Foundation

/// CustomPromptBuilder: 临时自定义任务提示词构建器
/// 职责：
/// - 处理弹窗中用户即时输入的自定义任务
/// - 不包含 Learned Rules（这是用户的临时任务）
/// - 输出JSON格式：result
class CustomPromptBuilder {
    
    // MARK: - Public Interface
    
    /// 构建临时自定义任务的系统提示词
    /// - Parameters:
    ///   - inputContext: 用户定义的输入理解方式
    ///   - outputRequirement: 用户期望的输出要求
    /// - Returns: 完整的系统提示词
    func buildSystemPrompt(inputContext: String?, outputRequirement: String?) -> String {
        var prompt = buildRoleAndTask(inputContext: inputContext, outputRequirement: outputRequirement)
        prompt += buildEngineeringGuardrails()
        prompt += buildOutputFormat()
        
        return prompt
    }
    
    // MARK: - Private Builders
    
    private func buildRoleAndTask(inputContext: String?, outputRequirement: String?) -> String {
        let taskDefinition = inputContext ?? "Analyze the following text."
        let outputSpec = outputRequirement ?? "Provide a detailed response."
        
        return """
        [Role: Versatile Text Processing Engine]
        
        You are a flexible text processor capable of handling various tasks beyond translation.
        
        ### User-Defined Task
        
        **Input Context**: \(taskDefinition)
        
        **Output Requirement**: \(outputSpec)
        
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
          "thinking_process": "Your brief analysis",
          "result": "PLAIN TEXT answer only - NO HTML, NO LINKS, NO MARKUP"
        }
        ```
        
        REMEMBER: The "result" field must contain ONLY plain text. 
        
        Examples of correct output:
        - For author query: "作者：刘禹锡\\n题目：《酬乐天扬州初逢席上见赠》"
        - For explanation: "This code implements a binary search algorithm."
        
        NEVER output: "<a href=...>", "{title: ..., author: ...}", or nested JSON objects.
        """
    }
}
