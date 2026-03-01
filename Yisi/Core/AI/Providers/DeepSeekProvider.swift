import Foundation

class DeepSeekProvider: AIProvider {
    var provider: APIProvider = .deepseek

    // MARK: - ReasoningCapability

    func isReasoningModel(_ model: String) -> Bool {
        let lower = model.lowercased()
        return lower.contains("deepseek-reasoner") || lower.contains("deepseek-r1")
    }

    func configureReasoning(body: inout [String: Any], model: String, enabled: Bool) {
        guard isReasoningModel(model) else { return }
        // deepseek-reasoner always emits <think> tags; no API parameter needed.
        // Increase token budget so reasoning has room.
        if enabled {
            body["max_tokens"] = 16384
        }
    }

    // MARK: - AIProvider

    func send(messages: [AIMessage], config: AIRequestConfig) async throws -> String {
        let apiUrl = "https://api.deepseek.com/chat/completions"
        guard let url = URL(string: apiUrl) else {
            throw NSError(domain: "AIError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        let apiMessages = messages.map { msg -> [String: Any] in
            return ["role": msg.role.rawValue, "content": msg.content.text]
        }

        var body: [String: Any] = [
            "model": config.model,
            "messages": apiMessages,
            "max_tokens": config.maxTokens
        ]

        // deepseek-reasoner does not accept temperature / top_p
        if !isReasoningModel(config.model) {
            body["temperature"] = max(config.temperature, 0.01)
        }

        configureReasoning(body: &body, model: config.model, enabled: config.enableNativeReasoning)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 120

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "DeepSeekProvider", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "DeepSeek HTTP \(statusCode): \(errorText)"])
        }

        return try parseResponse(data: data)
    }

    // MARK: - Private Helpers

    private func parseResponse(data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any] else {
            throw NSError(domain: "DeepSeekProvider", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }

        if let content = message["content"] as? String {
            return stripThinkTags(content)
        }

        if let contentArray = message["content"] as? [[String: Any]] {
            for item in contentArray {
                if let type = item["type"] as? String, type == "text",
                   let text = item["text"] as? String {
                    return stripThinkTags(text)
                }
            }
            for item in contentArray {
                if let text = item["text"] as? String, !text.isEmpty {
                    return stripThinkTags(text)
                }
            }
        }

        throw NSError(domain: "DeepSeekProvider", code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
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
