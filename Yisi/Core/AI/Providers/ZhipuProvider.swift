import Foundation

class ZhipuProvider: AIProvider {
    var provider: APIProvider = .zhipu
    
    func send(messages: [AIMessage], config: AIRequestConfig) async throws -> String {
        let apiUrl = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
        guard let url = URL(string: apiUrl) else {
            throw NSError(domain: "AIError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // 复用 OpenAI 的消息格式逻辑
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
        
        var body: [String: Any] = [
            "model": config.model,
            "messages": apiMessages,
            "temperature": config.temperature,
            // Thinking 模式需要更多 token，因为会返回 reasoning_content + content
            "max_tokens": (isReasoningModel(config.model) && config.enableNativeReasoning) ? 8192 : config.maxTokens
        ]
        
        // MARK: - Zhipu 推理模式控制
        // 对于 GLM-4.5/4.6/4-Plus 等推理模型，通过 thinking.type 参数控制
        // thinking.type = "enabled" 开启混合推理模式
        // thinking.type = "disabled" 关闭混合推理模式
        // 注意：这与 web_search 工具无关，web_search 是 tools 参数下的独立工具
        if isReasoningModel(config.model) && config.enableNativeReasoning {
            body["thinking"] = [
                "type": "enabled"
            ]
            print("DEBUG Zhipu: Thinking mode ENABLED for model \(config.model)")
        } else {
            print("DEBUG Zhipu: Thinking mode DISABLED (isReasoning=\(isReasoningModel(config.model)), enableNativeReasoning=\(config.enableNativeReasoning))")
        }
        // 注意：不需要显式发送 "disabled"，不传 thinking 参数即为默认行为
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 120  // Thinking 模式可能需要更长时间
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // DEBUG: 打印原始响应
        if let rawResponse = String(data: data, encoding: .utf8) {
            print("DEBUG Zhipu Raw Response: \(rawResponse.prefix(500))")
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "ZhipuProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: errorText])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any] {
            
            // 标准响应：content 是字符串
            if let content = message["content"] as? String {
                return content
            }
            
            // Thinking 模式响应：content 可能是数组 [{"type": "thinking", "thinking": "..."}, {"type": "text", "text": "..."}]
            if let contentArray = message["content"] as? [[String: Any]] {
                // 查找 type == "text" 的部分
                for item in contentArray {
                    if let type = item["type"] as? String, type == "text",
                       let text = item["text"] as? String {
                        return text
                    }
                }
                // 如果没有 text 类型，尝试返回第一个有内容的项
                for item in contentArray {
                    if let text = item["text"] as? String, !text.isEmpty {
                        return text
                    }
                    if let thinking = item["thinking"] as? String, !thinking.isEmpty {
                        // 如果只有 thinking 内容，返回它（虽然不太可能）
                        print("DEBUG: Only thinking content found, returning it")
                        return thinking
                    }
                }
            }
        }
        
        throw NSError(domain: "ZhipuProvider", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
    }
}
