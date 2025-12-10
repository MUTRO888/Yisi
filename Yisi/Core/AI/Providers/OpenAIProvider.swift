import Foundation

class OpenAIProvider: AIProvider {
    var provider: APIProvider = .openai
    
    // MARK: - ReasoningCapability 实现
    
    /// OpenAI 推理模型判断
    /// - O1 系列：o1, o1-preview, o1-mini, o1-pro
    /// - O3 系列：o3, o3-mini
    /// - O4-mini 系列
    func isReasoningModel(_ model: String) -> Bool {
        let lower = model.lowercased()
        return lower.hasPrefix("o1") || 
               lower.hasPrefix("o3") || 
               lower.hasPrefix("o4")
    }
    
    /// 判断是否支持 reasoning_effort 参数
    /// - O1-mini 不支持 reasoning_effort
    private func supportsReasoningEffort(_ model: String) -> Bool {
        let lower = model.lowercased()
        // o1-mini 不支持 reasoning_effort
        if lower == "o1-mini" {
            return false
        }
        return isReasoningModel(model)
    }
    
    /// OpenAI 推理参数配置
    /// - O1/O3 系列使用 reasoning_effort 参数控制推理强度 ("low"/"medium"/"high")
    /// - 推理模型不支持 max_tokens，需使用 max_completion_tokens
    /// - 推理模型不支持 temperature 参数（固定为 1）
    func configureReasoning(body: inout [String: Any], model: String, enabled: Bool) {
        guard isReasoningModel(model) else { return }
        
        // 推理模型不支持 max_tokens，需要使用 max_completion_tokens
        if let maxTokens = body["max_tokens"] {
            body.removeValue(forKey: "max_tokens")
            body["max_completion_tokens"] = maxTokens
        }
        
        // 推理模型不支持 temperature 参数
        body.removeValue(forKey: "temperature")
        
        // 配置 reasoning_effort（仅支持的模型）
        if supportsReasoningEffort(model) {
            // low = 快速响应，medium = 平衡，high = 最深度推理
            body["reasoning_effort"] = enabled ? "high" : "low"
            print("DEBUG OpenAI: Reasoning effort \(enabled ? "HIGH" : "LOW") for model \(model)")
        } else {
            print("DEBUG OpenAI: Model \(model) does not support reasoning_effort parameter")
        }
    }
    
    // MARK: - AIProvider 实现
    
    func send(messages: [AIMessage], config: AIRequestConfig) async throws -> String {
        let apiUrl = "https://api.openai.com/v1/chat/completions"
        guard let url = URL(string: apiUrl) else {
            throw NSError(domain: "AIError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // 1. 构建 Messages
        let apiMessages = messages.map { msg -> [String: Any] in
            var content: Any = msg.content.text
            
            // 多模态支持
            if let imageData = msg.content.image {
                content = [
                    ["type": "text", "text": msg.content.text],
                    ["type": "image_url", "image_url": ["url": "data:image/png;base64,\(imageData.base64EncodedString())"]]
                ]
            }
            
            return ["role": msg.role.rawValue, "content": content]
        }
        
        // 2. 构建 Body
        var body: [String: Any] = [
            "model": config.model,
            "messages": apiMessages,
            "temperature": config.temperature,
            "max_tokens": config.maxTokens,
            "response_format": ["type": "json_object"]
        ]
        
        // 3. 配置推理参数（使用协议方法）
        configureReasoning(body: &body, model: config.model, enabled: config.enableNativeReasoning)
        
        // 4. 发送请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 120  // 推理模式可能需要更长时间
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // DEBUG: 打印原始响应
        if let rawResponse = String(data: data, encoding: .utf8) {
            print("DEBUG OpenAI Raw Response: \(rawResponse.prefix(500))")
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "OpenAIProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: errorText])
        }
        
        // 5. 解析响应
        return try parseResponse(data: data)
    }
    
    // MARK: - Private Helpers
    
    /// 解析 OpenAI API 响应
    /// - 标准响应：choices[].message.content
    /// - 推理模型响应：可能包含 reasoning_content（暂不支持获取）
    private func parseResponse(data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any] else {
            throw NSError(domain: "OpenAIProvider", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
        
        // 标准响应：content 是字符串
        if let content = message["content"] as? String {
            return content
        }
        
        // 多部分响应（未来可能支持）
        if let contentArray = message["content"] as? [[String: Any]] {
            for item in contentArray {
                if let type = item["type"] as? String, type == "text",
                   let text = item["text"] as? String {
                    return text
                }
            }
        }
        
        throw NSError(domain: "OpenAIProvider", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
    }
}

