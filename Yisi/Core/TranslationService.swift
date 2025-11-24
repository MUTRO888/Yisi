import Foundation

class TranslationService: ObservableObject {
    static let shared = TranslationService()
    
    private init() {}
    
    func translate(_ text: String, targetLanguage: String = "Simplified Chinese") async throws -> String {
        guard let apiKeyData = KeychainHelper.shared.read(service: "com.yisi.app", account: "openai_api_key"),
              let apiKey = String(data: apiKeyData, encoding: .utf8), !apiKey.isEmpty else {
            return "Please set your API Key in Settings."
        }
        
        // Construct the prompt
        let prompt = "Translate the following text to \(targetLanguage). Only return the translated text, no explanations.\n\n\(text)"
        
        // JSON Body
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful translator."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        // Request
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Execute
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorText = String(data: data, encoding: .utf8) {
                throw NSError(domain: "TranslationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorText)"])
            }
            throw NSError(domain: "TranslationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown API Error"])
        }
        
        // Parse Response
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return "Failed to parse translation."
    }
}
