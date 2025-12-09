import Foundation

class GeminiProvider: AIProvider {
    var provider: APIProvider = .gemini
    
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
                // Gemini User/Model 角色映射
                let role = msg.role == .user ? "user" : "model"
                contents.append(["role": role, "parts": parts])
            }
        }
        
        // 2. 配置 Generation Config (包含原生推理逻辑)
        var genConfig: [String: Any] = [
            "response_mime_type": "application/json",
            "temperature": config.temperature,
            "maxOutputTokens": max(2048, config.maxTokens)
        ]
        
        // 如果是推理模型且开启了原生推理 -> 注入 thinking_config
        if config.enableNativeReasoning && isReasoningModel(config.model) {
            genConfig["thinking_config"] = [
                "include_thoughts": false,
                "thinking_budget": 1024 // 或 -1
            ]
        }
        
        var body: [String: Any] = [
            "contents": contents,
            "generationConfig": genConfig
        ]
        if let sys = systemInstruction {
            body["system_instruction"] = sys
        }
        
        // 3. 发送请求
        return try await executeRequest(url: url, body: body)
    }
    
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
