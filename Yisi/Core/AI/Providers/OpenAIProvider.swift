import Foundation

class OpenAIProvider: AIProvider {
    var provider: APIProvider = .openai
    
    // MARK: - ReasoningCapability 实现
    
    /// OpenAI 推理模型判断
    /// - O1 系列：o1, o1-preview, o1-mini
    /// - O3 系列：o3, o3-mini
    func isReasoningModel(_ model: String) -> Bool {
        let lower = model.lowercased()
        return lower.contains("o1") || lower.contains("o3")
    }
    
    /// OpenAI 推理参数配置
    /// - O1/O3 系列使用 reasoning_effort 参数控制推理强度
    /// - 注意：O1 不支持 max_tokens，需使用 max_completion_tokens
    func configureReasoning(body: inout [String: Any], model: String, enabled: Bool) {
        guard isReasoningModel(model) else { return }
        
        // O1 系列不支持 max_tokens
        body.removeValue(forKey: "max_tokens")
        
        if enabled {
            // 启用时可设置 reasoning_effort（目前 O1 preview 可能不支持）
            // body["reasoning_effort"] = "medium"
            print("DEBUG OpenAI: Reasoning model \(model) - native reasoning always enabled")
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
        request.timeoutInterval = 60
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "OpenAIProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: errorText])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        
        throw NSError(domain: "OpenAIProvider", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
    }
}
