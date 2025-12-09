import Foundation

class OpenAIProvider: AIProvider {
    var provider: APIProvider = .openai
    
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
            "response_format": ["type": "json_object"]
        ]
        
        // O1 系列暂不支持 max_tokens (使用 max_completion_tokens)，这里做简单兼容
        if !config.model.lowercased().contains("o1") {
            body["max_tokens"] = config.maxTokens
        }
        
        // 3. 发送请求
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
