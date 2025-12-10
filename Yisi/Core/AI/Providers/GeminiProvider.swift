import Foundation

class GeminiProvider: AIProvider {
    var provider: APIProvider = .gemini
    
    // MARK: - ReasoningCapability 实现
    
    /// Gemini 推理模型判断
    /// - Gemini-2.5 系列具备推理能力
    func isReasoningModel(_ model: String) -> Bool {
        return model.lowercased().contains("gemini-2.5")
    }
    
    /// Gemini 推理参数配置
    /// - 通过 thinking_config 控制推理模式
    /// - 只在启用时配置，不配置则使用默认行为
    func configureReasoning(body: inout [String: Any], model: String, enabled: Bool) {
        guard isReasoningModel(model) && enabled else { return }
        
        // Gemini 只在启用时注入 thinking_config
        var genConfig = body["generationConfig"] as? [String: Any] ?? [:]
        genConfig["thinking_config"] = [
            "include_thoughts": false,
            "thinking_budget": 1024
        ]
        body["generationConfig"] = genConfig
        
        print("DEBUG Gemini: Thinking mode ENABLED for model \(model)")
    }
    
    // MARK: - AIProvider 实现
    
    func send(messages: [AIMessage], config: AIRequestConfig) async throws -> String {
        let apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/\(config.model):generateContent?key=\(config.apiKey)"
        guard let url = URL(string: apiUrl) else {
            throw NSError(domain: "AIError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // 1. 构建 Gemini 特有的 Payload
        var contents: [[String: Any]] = []
        var systemInstruction: [String: Any]? = nil
        
        for msg in messages {
            if msg.role == .system {
                systemInstruction = ["parts": [["text": msg.content.text]]]
            } else {
                var parts: [[String: Any]] = []
                if !msg.content.text.isEmpty {
                    parts.append(["text": msg.content.text])
                }
                if let imageData = msg.content.image {
                    parts.append([
                        "inline_data": [
                            "mime_type": "image/png",
                            "data": imageData.base64EncodedString()
                        ]
                    ])
                }
                let role = msg.role == .user ? "user" : "model"
                contents.append(["role": role, "parts": parts])
            }
        }
        
        // 2. 配置 Generation Config
        var genConfig: [String: Any] = [
            "response_mime_type": "application/json",
            "temperature": config.temperature,
            "maxOutputTokens": max(2048, config.maxTokens)
        ]
        
        var body: [String: Any] = [
            "contents": contents,
            "generationConfig": genConfig
        ]
        if let sys = systemInstruction {
            body["system_instruction"] = sys
        }
        
        // 3. 配置推理参数（使用协议方法）
        configureReasoning(body: &body, model: config.model, enabled: config.enableNativeReasoning)
        
        // 4. 发送请求
        return try await executeRequest(url: url, body: body)
    }
    
    // MARK: - Private Helpers
    
    private func executeRequest(url: URL, body: [String: Any]) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 90
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "GeminiProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: errorText])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let firstPart = parts.first,
           let text = firstPart["text"] as? String {
            return text
        }
        
        throw NSError(domain: "GeminiProvider", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
    }
}
