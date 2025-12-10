import Foundation

class GeminiProvider: AIProvider {
    var provider: APIProvider = .gemini
    
    // MARK: - ReasoningCapability 实现
    
    /// Gemini 推理模型判断
    /// - Gemini 3 系列：gemini-3-pro, gemini-3-pro-preview 等
    /// - Gemini 2.5 系列：gemini-2.5-pro, gemini-2.5-flash, gemini-2.5-flash-lite 等
    func isReasoningModel(_ model: String) -> Bool {
        let lower = model.lowercased()
        return lower.contains("gemini-3") ||
               lower.contains("gemini-2.5")
    }
    
    /// 判断是否为 Gemini 3 系列模型
    private func isGemini3Model(_ model: String) -> Bool {
        return model.lowercased().contains("gemini-3")
    }
    
    /// Gemini 推理参数配置
    /// - Gemini 3 系列：使用 thinkingLevel ("low"/"high")
    /// - Gemini 2.5 系列：使用 thinkingBudget (-1=动态, 0=关闭, >0=预算)
    /// - 需要显式配置来开启或关闭思考模式
    func configureReasoning(body: inout [String: Any], model: String, enabled: Bool) {
        guard isReasoningModel(model) else { return }
        
        var genConfig = body["generationConfig"] as? [String: Any] ?? [:]
        
        if isGemini3Model(model) {
            // Gemini 3 系列：无法完全关闭思考，只能设置 low/high
            // 注意：Gemini 3 Pro 不支持关闭思考功能
            genConfig["thinkingConfig"] = [
                "thinkingLevel": enabled ? "high" : "low"
            ]
            print("DEBUG Gemini: Thinking level \(enabled ? "HIGH" : "LOW") for model \(model)")
        } else {
            // Gemini 2.5 系列：可以通过 thinkingBudget 控制
            // -1 = 动态思考, 0 = 关闭思考, >0 = 指定预算
            if enabled {
                genConfig["thinkingConfig"] = [
                    "thinkingBudget": 8192  // 启用时使用较大预算
                ]
            } else {
                genConfig["thinkingConfig"] = [
                    "thinkingBudget": 0  // 显式关闭思考
                ]
            }
            print("DEBUG Gemini: Thinking mode \(enabled ? "ENABLED (budget: 8192)" : "DISABLED (budget: 0)") for model \(model)")
        }
        
        // Thinking 模式需要更多输出 token
        if enabled {
            genConfig["maxOutputTokens"] = 8192
        }
        
        body["generationConfig"] = genConfig
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
        let genConfig: [String: Any] = [
            "responseMimeType": "application/json",
            "temperature": config.temperature,
            "maxOutputTokens": max(2048, config.maxTokens)
        ]
        
        var body: [String: Any] = [
            "contents": contents,
            "generationConfig": genConfig
        ]
        if let sys = systemInstruction {
            body["systemInstruction"] = sys
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
        request.timeoutInterval = 120  // Thinking 模式可能需要更长时间
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // DEBUG: 打印原始响应
        if let rawResponse = String(data: data, encoding: .utf8) {
            print("DEBUG Gemini Raw Response: \(rawResponse.prefix(500))")
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "GeminiProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: errorText])
        }
        
        // 5. 解析响应
        return try parseResponse(data: data)
    }
    
    /// 解析 Gemini API 响应
    /// - 标准响应：parts 数组中的 text 字段
    /// - Thinking 模式：可能包含 thought 和 text 两种类型的 parts
    private func parseResponse(data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            throw NSError(domain: "GeminiProvider", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
        
        // Thinking 模式响应：可能包含 thought 和 text 两种 parts
        // 优先查找 text 类型的 part（跳过 thought）
        for part in parts {
            // 如果有 thought 字段，说明是思考内容，跳过
            if part["thought"] != nil {
                continue
            }
            // 返回 text 字段内容
            if let text = part["text"] as? String {
                return text
            }
        }
        
        // 备选：返回第一个有 text 的 part
        for part in parts {
            if let text = part["text"] as? String, !text.isEmpty {
                return text
            }
        }
        
        throw NSError(domain: "GeminiProvider", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
    }
}
