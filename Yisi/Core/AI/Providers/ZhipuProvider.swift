import Foundation

class ZhipuProvider: AIProvider {
    var provider: APIProvider = .zhipu
    
    // MARK: - ReasoningCapability 实现
    
    /// Zhipu 推理模型判断
    /// - GLM-4.5 系列：glm-4.5, glm-4.5-air, glm-4.5-airx, glm-4.5-x
    /// - GLM-4.6 系列
    /// - GLM-4-Plus
    func isReasoningModel(_ model: String) -> Bool {
        let lower = model.lowercased()
        return lower.contains("glm-4.5") ||
               lower.contains("glm-4.6") ||
               lower.contains("glm-4-plus")
    }
    
    /// Zhipu 推理参数配置
    /// - thinking.type = "enabled"  开启思考模式
    /// - thinking.type = "disabled" 关闭思考模式（必须显式发送）
    func configureReasoning(body: inout [String: Any], model: String, enabled: Bool) {
        guard isReasoningModel(model) else { return }
        
        // Zhipu 默认开启动态思考，必须显式发送 disabled 来关闭
        body["thinking"] = ["type": enabled ? "enabled" : "disabled"]
        
        // Thinking 模式需要更多 token
        if enabled {
            body["max_tokens"] = 8192
        }
        
    }
    
    // MARK: - AIProvider 实现
    
    func send(messages: [AIMessage], config: AIRequestConfig) async throws -> String {
        let apiUrl = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
        guard let url = URL(string: apiUrl) else {
            throw NSError(domain: "AIError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // 1. 构建消息格式
        let apiMessages = messages.map { msg -> [String: Any] in
            var content: Any = msg.content.text
            if let imageData = msg.content.image {
                content = [
                    ["type": "text", "text": msg.content.text],
                    ["type": "image_url", "image_url": ["url": "data:image/png;base64,\(imageData.base64EncodedString())"]]
                ]
            }
            return ["role": msg.role.rawValue, "content": content]
        }
        
        // 2. 构建请求 body
        var body: [String: Any] = [
            "model": config.model,
            "messages": apiMessages,
            "temperature": config.temperature,
            "max_tokens": config.maxTokens
        ]
        
        // 3. 配置推理参数（使用协议方法）
        configureReasoning(body: &body, model: config.model, enabled: config.enableNativeReasoning)
        
        // 4. 发送请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 120
        
        let (data, response) = try await URLSession.shared.data(for: request)
        

        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "ZhipuProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: errorText])
        }
        
        // 5. 解析响应
        return try parseResponse(data: data)
    }
    
    // MARK: - Private Helpers
    
    private func parseResponse(data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any] else {
            throw NSError(domain: "ZhipuProvider", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
        
        // 标准响应：content 是字符串
        if let content = message["content"] as? String {
            return content
        }
        
        // Thinking 模式响应：content 可能是数组
        // [{\"type\": \"thinking\", \"thinking\": \"...\"}, {\"type\": \"text\", \"text\": \"...\"}]
        if let contentArray = message["content"] as? [[String: Any]] {
            // 优先查找 type == "text"
            for item in contentArray {
                if let type = item["type"] as? String, type == "text",
                   let text = item["text"] as? String {
                    return text
                }
            }
            // 备选：返回第一个有内容的项
            for item in contentArray {
                if let text = item["text"] as? String, !text.isEmpty {
                    return text
                }
            }
        }
        
        throw NSError(domain: "ZhipuProvider", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
    }
}
