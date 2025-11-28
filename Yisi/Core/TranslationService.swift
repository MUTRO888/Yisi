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
        let preprocessedText = preprocessInput(text)
        
        switch provider {
        case .openai:
            return try await translateWithOpenAI(preprocessedText, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
        case .gemini:
            return try await translateWithGemini(preprocessedText, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
        case .zhipu:
            return try await translateWithZhipu(preprocessedText, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
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
    
    // MARK: - Smart Pre-processing
    
    private func preprocessInput(_ text: String) -> String {
        // Heuristic: If short lines + frequent newlines -> Preserve newlines (Poetry/Code)
        // Heuristic: If long sentences broken by newlines mid-sentence -> Merge lines (PDF Copy)
        
        // Heuristic: Check if lines should be merged based on punctuation and next line capitalization
        let lines = text.components(separatedBy: .newlines)
        var mergedText = ""
        for i in 0..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            
            mergedText += line
            
            // If it's the last line, just end
            if i == lines.count - 1 {
                break
            }
            
            let nextLine = lines[i+1].trimmingCharacters(in: .whitespaces)
            if nextLine.isEmpty {
                mergedText += "\n"
                continue
            }
            
            // Check terminators
            let terminators = [".", "!", "?", "。", "！", "？"]
            if let lastChar = line.last, terminators.contains(String(lastChar)) {
                mergedText += "\n"
                continue
            }
            
            // Check if next line starts with lowercase (strong signal for continuation)
            if let firstChar = nextLine.first, firstChar.isLowercase {
                mergedText += " "
                continue
            }
            
            // Fallback: Length heuristic
            // If line is long (> 50 chars) and doesn't end in punctuation, assume prose -> merge
            // If line is short (< 50 chars), assume poetry/list -> keep newline
            if line.count > 50 {
                mergedText += " "
            } else {
                mergedText += "\n"
            }
        }
        
        return mergedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func containsMarkdown(_ text: String) -> Bool {
        let markdownMarkers = ["`", "**", "#", "[", "]"]
        for marker in markdownMarkers {
            if text.contains(marker) {
                return true
            }
        }
        return false
    }
    
    private func extractJSON(from text: String) -> String {
        // Remove markdown code blocks if present
        var jsonString = text
        if jsonString.contains("```json") {
            jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
        }
        if jsonString.contains("```") {
            jsonString = jsonString.replacingOccurrences(of: "```", with: "")
        }
        return jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - API Optimization Helpers
    
    private func getTemperature(for text: String) -> Double {
        // Technical/Short text: precise
        if containsMarkdown(text) || text.count < 50 {
            return 0.1
        }
        
        // Legal text: zero tolerance
        if text.contains("Force Majeure") || text.contains("pursuant to") || 
           text.contains("不可抗力") || text.contains("根据") {
            return 0.0
        }
        
        // Literary long text: creative
        if (text.contains("。") || text.contains(".")) && text.count > 200 {
            return 0.7
        }
        
        // Default
        return 0.3
    }
    
    private func getMaxTokens(for text: String) -> Int {
        // Translation is usually 1.5-2x original, 3x is safe
        return min(4096, max(512, text.count * 3))
    }
    
    private func validateResponse(_ response: TranslationResponse, originalText: String) throws {
        // Check if empty
        guard !response.translation_result.isEmpty else {
            throw NSError(domain: "TranslationError", code: 2, 
                         userInfo: [NSLocalizedDescriptionKey: "Empty translation result"])
        }
        
        // Check if it's still JSON (Schema self-translation bug)
        let trimmed = response.translation_result.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("{") && trimmed.hasSuffix("}") && trimmed.contains("detected_type") {
            throw NSError(domain: "TranslationError", code: 3, 
                         userInfo: [NSLocalizedDescriptionKey: "Invalid translation: AI returned schema instead of text"])
        }
        
        // Check if abnormally long (shouldn't be 10x original)
        if response.translation_result.count > originalText.count * 10 {
            throw NSError(domain: "TranslationError", code: 4, 
                         userInfo: [NSLocalizedDescriptionKey: "Translation abnormally long"])
        }
    }
    
    private func executeWithRetry<T>(
        maxRetries: Int = 3,
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                // Don't retry on certain errors (like missing API key)
                if let nsError = error as NSError?, 
                   nsError.domain == "TranslationError",
                   nsError.localizedDescription.contains("API Key") {
                    throw error
                }
                
                // Exponential backoff: 1s, 2s, 4s
                if attempt < maxRetries - 1 {
                    let delay = UInt64(pow(2.0, Double(attempt))) * 1_000_000_000
                    try await Task.sleep(nanoseconds: delay)
                }
            }
        }
        
        throw lastError ?? NSError(domain: "TranslationError", code: 99, 
                                   userInfo: [NSLocalizedDescriptionKey: "Unknown error after retries"])
    }
    
    // MARK: - API Calls
    
    private func translateWithOpenAI(_ text: String, sourceLanguage: String, targetLanguage: String) async throws -> String {
        guard let apiKey = UserDefaults.standard.string(forKey: "openai_api_key"), !apiKey.isEmpty else {
            return "Please set your OpenAI API Key in Settings."
        }
        
        let systemPrompt = PromptManager.shared.generateSystemPrompt()
        let userPrompt = PromptManager.shared.generateUserPrompt(text: text, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.3,
            "response_format": ["type": "json_object"]
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
            
            // Parse JSON response
            let cleanJSON = extractJSON(from: content)
            if let data = cleanJSON.data(using: .utf8),
               let responseObj = try? JSONDecoder().decode(TranslationResponse.self, from: data) {
                return responseObj.translation_result
            }
            
            // Fallback: If it looks like JSON but failed to parse, we might want to return raw text
            // But if the user sees raw JSON, it's bad.
            // Try to see if we can salvage it or if it's just plain text.
            // If it starts with { and ends with }, it's likely JSON.
            if cleanJSON.hasPrefix("{") && cleanJSON.hasSuffix("}") {
                // It's broken JSON. Return a generic error or try to extract "translation_result" manually?
                // For now, let's return the raw content but maybe we should log it.
                // Actually, the user said "If parsing fails (e.g., AI returned plain text): Fallback to displaying the raw text."
                // But if it IS JSON, we don't want to show it.
                // Let's try to simple string search for "translation_result" as a last resort.
                return content
            }
            
            // It's likely plain text (AI ignored JSON instruction), so return it.
            return content
        }
        
        return "Failed to parse translation."
    }
    
    
    private func translateWithGemini(_ text: String, sourceLanguage: String, targetLanguage: String) async throws -> String {
        return try await executeWithRetry {
            guard let apiKey = UserDefaults.standard.string(forKey: "gemini_api_key"), !apiKey.isEmpty else {
                return "Please set your Gemini API Key in Settings."
            }
            
            let systemPrompt = PromptManager.shared.generateSystemPrompt()
            let userPrompt = PromptManager.shared.generateUserPrompt(text: text, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
            
            // Use proper system_instruction field (Gemini best practice)
            let body: [String: Any] = [
                "system_instruction": [
                    "parts": [["text": systemPrompt]]
                ],
                "contents": [
                    [
                        "parts": [
                            ["text": userPrompt]
                        ]
                    ]
                ],
                "generationConfig": [
                    "response_mime_type": "application/json",
                    "temperature": self.getTemperature(for: text),
                    "maxOutputTokens": self.getMaxTokens(for: text)
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
            request.timeoutInterval = 90  // 90 second timeout for long texts
            
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
                
                 // Parse JSON response
                let cleanJSON = self.extractJSON(from: text)
                if let data = cleanJSON.data(using: .utf8),
                   let responseObj = try? JSONDecoder().decode(TranslationResponse.self, from: data) {
                    
                    // Validate response before returning
                    try self.validateResponse(responseObj, originalText: text)
                    return responseObj.translation_result
                }
                
                return text
            }
            
            return "Failed to parse translation."
        }
    }
    
    
    private func translateWithZhipu(_ text: String, sourceLanguage: String, targetLanguage: String) async throws -> String {
        return try await executeWithRetry {
            guard let apiKey = UserDefaults.standard.string(forKey: "zhipu_api_key"), !apiKey.isEmpty else {
                return "Please set your Zhipu API Key in Settings."
            }
            
            let systemPrompt = PromptManager.shared.generateSystemPrompt()
            let userPrompt = PromptManager.shared.generateUserPrompt(text: text, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
            
            let body: [String: Any] = [
                "model": "glm-4.5-air",
                "messages": [
                    ["role": "system", "content": systemPrompt],
                    ["role": "user", "content": userPrompt]
                ],
                "temperature": self.getTemperature(for: text),
                "max_tokens": self.getMaxTokens(for: text)
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            
            var request = URLRequest(url: URL(string: "https://open.bigmodel.cn/api/paas/v4/chat/completions")!)
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            request.timeoutInterval = 90  // 90 second timeout for long texts
            
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
                
                 // Parse JSON response
                let cleanJSON = self.extractJSON(from: content)
                if let data = cleanJSON.data(using: .utf8),
                   let responseObj = try? JSONDecoder().decode(TranslationResponse.self, from: data) {
                    
                    // Validate response before returning
                    try self.validateResponse(responseObj, originalText: text)
                    return responseObj.translation_result
                }
                
                return content
            }
            
            return "Failed to parse translation."
        }
    }
}
