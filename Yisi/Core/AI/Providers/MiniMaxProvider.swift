import Foundation

class MiniMaxProvider: AIProvider {
    var provider: APIProvider = .minimax

    // MARK: - ReasoningCapability

    func isReasoningModel(_ model: String) -> Bool {
        let lower = model.lowercased()
        return lower.contains("minimax-m2.5") ||
               lower.contains("minimax-m2.1") ||
               lower.contains("minimax-m1")
    }

    func configureReasoning(body: inout [String: Any], model: String, enabled: Bool) {
        guard isReasoningModel(model) else { return }

        if enabled {
            body["thinking"] = ["type": "enabled", "budget_tokens": 8192]
            body["max_tokens"] = 16384
        }
    }

    // MARK: - AIProvider

    func send(messages: [AIMessage], config: AIRequestConfig) async throws -> String {
        let apiUrl = "https://api.minimaxi.com/anthropic/v1/messages"
        guard let url = URL(string: apiUrl) else {
            throw NSError(domain: "AIError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        // Separate system message from conversation messages (Anthropic format)
        var systemText: String?
        var conversationMessages: [[String: Any]] = []

        for msg in messages {
            if msg.role == .system {
                systemText = msg.content.text
            } else {
                conversationMessages.append([
                    "role": msg.role.rawValue,
                    "content": [["type": "text", "text": msg.content.text]]
                ])
            }
        }

        var body: [String: Any] = [
            "model": config.model,
            "messages": conversationMessages,
            "temperature": config.temperature,
            "max_tokens": config.maxTokens
        ]

        if let systemText = systemText {
            body["system"] = systemText
        }

        configureReasoning(body: &body, model: config.model, enabled: config.enableNativeReasoning)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 120

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown Error"
            print("DEBUG MiniMax: HTTP \(statusCode) - \(errorText.prefix(300))")
            throw NSError(domain: "MiniMaxProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "MiniMax HTTP \(statusCode): \(errorText)"])
        }

        print("DEBUG MiniMax: HTTP 200, body length = \(data.count)")
        return try parseResponse(data: data)
    }

    // MARK: - Private Helpers

    private func parseResponse(data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let raw = String(data: data, encoding: .utf8) ?? "(binary)"
            print("DEBUG MiniMax: raw response = \(raw.prefix(500))")
            throw NSError(domain: "MiniMaxProvider", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Response is not valid JSON"])
        }

        // Anthropic format: { content: [{ type: "thinking", thinking: "..." }, { type: "text", text: "..." }] }
        guard let contentArray = json["content"] as? [[String: Any]] else {
            print("DEBUG MiniMax: unexpected structure, keys = \(json.keys.sorted())")
            throw NSError(domain: "MiniMaxProvider", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Unexpected response structure from MiniMax"])
        }

        for item in contentArray {
            if let type = item["type"] as? String, type == "text",
               let text = item["text"] as? String {
                return stripThinkTags(text)
            }
        }

        // Fallback: return any non-empty text block
        for item in contentArray {
            if let text = item["text"] as? String, !text.isEmpty {
                return stripThinkTags(text)
            }
        }

        print("DEBUG MiniMax: content types = \(contentArray.compactMap { $0["type"] as? String })")
        throw NSError(domain: "MiniMaxProvider", code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "Could not extract text from MiniMax response"])
    }

    private func stripThinkTags(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"<think>[\s\S]*?</think>"#, options: []) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
