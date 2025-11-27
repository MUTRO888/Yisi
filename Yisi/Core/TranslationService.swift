import Foundation

enum APIProvider: String {
    case openai = "OpenAI"
    case gemini = "Gemini"
    case zhipu = "Zhipu AI"
}

class TranslationService: ObservableObject {
    static let shared = TranslationService()
    
    private init() {}
    
    func translate(_ text: String, sourceLanguage: String = "Auto Detect", targetLanguage: String = "简体中文") async throws -> String {
        let provider = getAPIProvider()
        
        switch provider {
        case .openai:
            return try await translateWithOpenAI(text, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
        case .gemini:
            return try await translateWithGemini(text, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
        case .zhipu:
            return try await translateWithZhipu(text, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
        }
    }
    
    private func getAPIProvider() -> APIProvider {
        // Check UserDefaults first (new way)
        if let providerString = UserDefaults.standard.string(forKey: "api_provider"),
           let provider = APIProvider(rawValue: providerString) {
            return provider
        }
        
        // Fallback to Keychain (old way)
        if let data = KeychainHelper.shared.read(service: "com.yisi.app", account: "api_provider"),
           let providerString = String(data: data, encoding: .utf8),
           let provider = APIProvider(rawValue: providerString) {
            return provider
        }
        
        return .gemini
    }
    
    private func translateWithOpenAI(_ text: String, sourceLanguage: String, targetLanguage: String) async throws -> String {
        guard let apiKey = UserDefaults.standard.string(forKey: "openai_api_key"), !apiKey.isEmpty else {
            return "Please set your OpenAI API Key in Settings."
        }
        
        var prompt = "Translate the following text to \(targetLanguage). Only return the translated text, no explanations.\n\n\(text)"
        if sourceLanguage != "Auto Detect" {
            prompt = "Translate the following text from \(sourceLanguage) to \(targetLanguage). Only return the translated text, no explanations.\n\n\(text)"
        }
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful translator."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorText = String(data: data, encoding: .utf8) {
                throw NSError(domain: "TranslationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorText)"])
            }
            throw NSError(domain: "TranslationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown API Error"])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return "Failed to parse translation."
    }
    
    private func translateWithGemini(_ text: String, sourceLanguage: String, targetLanguage: String) async throws -> String {
        guard let apiKey = UserDefaults.standard.string(forKey: "gemini_api_key"), !apiKey.isEmpty else {
            return "Please set your Gemini API Key in Settings."
        }
        
        var prompt = "Translate the following text to \(targetLanguage). Only return the translated text, no explanations.\n\n\(text)"
        if sourceLanguage != "Auto Detect" {
            prompt = "Translate the following text from \(sourceLanguage) to \(targetLanguage). Only return the translated text, no explanations.\n\n\(text)"
        }
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=\(apiKey)") else {
            throw NSError(domain: "TranslationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorText = String(data: data, encoding: .utf8) {
                throw NSError(domain: "TranslationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorText)"])
            }
            throw NSError(domain: "TranslationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown API Error"])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let firstPart = parts.first,
           let text = firstPart["text"] as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return "Failed to parse translation."
    }
    
    private func translateWithZhipu(_ text: String, sourceLanguage: String, targetLanguage: String) async throws -> String {
        guard let apiKey = UserDefaults.standard.string(forKey: "zhipu_api_key"), !apiKey.isEmpty else {
            return "Please set your Zhipu API Key in Settings."
        }
        
        var prompt = "Translate the following text to \(targetLanguage). Only return the translated text, no explanations.\n\n\(text)"
        if sourceLanguage != "Auto Detect" {
            prompt = "Translate the following text from \(sourceLanguage) to \(targetLanguage). Only return the translated text, no explanations.\n\n\(text)"
        }
        
        let body: [String: Any] = [
            "model": "glm-4.5-air",
            "messages": [
                ["role": "system", "content": "You are a helpful translator."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: URL(string: "https://open.bigmodel.cn/api/paas/v4/chat/completions")!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorText = String(data: data, encoding: .utf8) {
                throw NSError(domain: "TranslationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorText)"])
            }
            throw NSError(domain: "TranslationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown API Error"])
        }
        
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
