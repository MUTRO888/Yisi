import Foundation

enum APIProvider: String {
    case openai = "OpenAI"
    case gemini = "Gemini"
    case zhipu = "Zhipu AI"
}

class TranslationService: ObservableObject {
    static let shared = TranslationService()
    
    private init() {}
    
    func translate(_ text: String, mode: PromptMode = .defaultTranslation, sourceLanguage: String = "Auto Detect", targetLanguage: String = "简体中文", userPerception: String? = nil, userInstruction: String? = nil) async throws -> String {
        let provider = getAPIProvider()
        let preprocessedText = preprocessInput(text)
        
        switch provider {
        case .openai:
            return try await translateWithOpenAI(preprocessedText, mode: mode, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage, userPerception: userPerception, userInstruction: userInstruction)
        case .gemini:
            return try await translateWithGemini(preprocessedText, mode: mode, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage, userPerception: userPerception, userInstruction: userInstruction)
        case .zhipu:
            return try await translateWithZhipu(preprocessedText, mode: mode, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage, userPerception: userPerception, userInstruction: userInstruction)
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
    
    private func parseTranslationResult(from jsonString: String, mode: PromptMode) throws -> String {
        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "TranslationError", code: 3, 
                         userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON"])
        }
        
        guard let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "TranslationError", code: 3, 
                         userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
        }
        
        // Try mode-specific key first, then fallback
        let primaryKey: String
        switch mode {
        case .defaultTranslation:
            primaryKey = "translation_result"
        case .temporaryCustom, .userPreset:
            primaryKey = "result"
        }
        let fallbackKey = primaryKey == "translation_result" ? "result" : "translation_result"
        
        // Try primary key (handle both String and nested Object)
        if let result = jsonObj[primaryKey] {
            if let stringResult = result as? String, !stringResult.isEmpty {
                return stringResult
            } else if let dictResult = result as? [String: Any] {
                // Handle nested object (e.g., {title: "...", author: "..."})
                return formatNestedResult(dictResult)
            }
        }
        
        // Try fallback key
        if let result = jsonObj[fallbackKey] {
            if let stringResult = result as? String, !stringResult.isEmpty {
                return stringResult
            } else if let dictResult = result as? [String: Any] {
                return formatNestedResult(dictResult)
            }
        }
        
        // Last resort: try "answer" key
        if let result = jsonObj["answer"] as? String, !result.isEmpty {
            return result
        }
        
        throw NSError(domain: "TranslationError", code: 3, 
                     userInfo: [NSLocalizedDescriptionKey: "No valid result key found in JSON response"])
    }
    
    // Format nested JSON object into readable string
    private func formatNestedResult(_ dict: [String: Any]) -> String {
        let priorityKeys = ["author", "title", "name", "answer"]
        
        // Get priority key-value pairs
        let priorityLines = priorityKeys.compactMap { key -> String? in
            guard let value = dict[key] else { return nil }
            return "\(key): \(value)"
        }
        
        // Get remaining key-value pairs
        let remainingLines = dict.keys
            .filter { !priorityKeys.contains($0) }
            .sorted()
            .compactMap { key in "\(key): \(dict[key]!)" }
        
        let allLines = priorityLines + remainingLines
        return allLines.isEmpty ? String(describing: dict) : allLines.joined(separator: "\n")
    }
    
    // MARK: - Prompt Generation Helper
    
    /// Generate system and user prompts based on mode (共享方法，消除重复)
    private func generatePrompts(
        for mode: PromptMode,
        text: String,
        sourceLanguage: String,
        targetLanguage: String,
        userPerception: String?,
        userInstruction: String?
    ) -> (system: String, user: String) {
        let systemPrompt: String
        if mode == .temporaryCustom {
            systemPrompt = PromptCoordinator.shared.generateCustomPrompt(
                inputContext: userPerception,
                outputRequirement: userInstruction
            )
        } else {
            systemPrompt = PromptCoordinator.shared.generateSystemPrompt(for: mode, withLearnedRules: true)
        }
        
        let userPrompt = PromptCoordinator.shared.generateUserPrompt(
            text: text,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
        
        return (systemPrompt, userPrompt)
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
    
    private func translateWithOpenAI(_ text: String, mode: PromptMode, sourceLanguage: String, targetLanguage: String, userPerception: String?, userInstruction: String?) async throws -> String {
        guard let apiKey = UserDefaults.standard.string(forKey: "openai_api_key"), !apiKey.isEmpty else {
            return "Please set your OpenAI API Key in Settings."
        }
        
        let prompts = generatePrompts(
            for: mode,
            text: text,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            userPerception: userPerception,
            userInstruction: userInstruction
        )
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "temperature": getTemperature(for: text),
            "messages": [
                ["role": "system", "content": prompts.system],
                ["role": "user", "content": prompts.user]
            ],
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
            return try parseTranslationResult(from: cleanJSON, mode: mode)
        }
        
        return "Failed to parse translation."
    }
    
    
    private func translateWithGemini(_ text: String, mode: PromptMode, sourceLanguage: String, targetLanguage: String, userPerception: String?, userInstruction: String?) async throws -> String {
        return try await executeWithRetry {
            guard let apiKey = UserDefaults.standard.string(forKey: "gemini_api_key"), !apiKey.isEmpty else {
                return "Please set your Gemini API Key in Settings."
            }
            
            let prompts = generatePrompts(
                for: mode,
                text: text,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                userPerception: userPerception,
                userInstruction: userInstruction
            )
            
            // Use proper system_instruction field (Gemini best practice)
            let body: [String: Any] = [
                "system_instruction": [
                    "parts": [["text": prompts.system]]
                ],
                "contents": [
                    [
                        "parts": [
                            ["text": prompts.user]
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
            
            guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)") else {
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
                
                // DEBUG: Print raw response
                print("DEBUG Gemini Response:")
                print(cleanJSON)
                
                return try self.parseTranslationResult(from: cleanJSON, mode: mode)
            }
            
            return "Failed to parse translation."
        }
    }
    
    
    private func translateWithZhipu(_ text: String, mode: PromptMode, sourceLanguage: String, targetLanguage: String, userPerception: String?, userInstruction: String?) async throws -> String {
        return try await executeWithRetry {
            guard let apiKey = UserDefaults.standard.string(forKey: "zhipu_api_key"), !apiKey.isEmpty else {
                return "Please set your Zhipu API Key in Settings."
            }
            
            let prompts = generatePrompts(
                for: mode,
                text: text,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                userPerception: userPerception,
                userInstruction: userInstruction
            )
            
            let body: [String: Any] = [
                "model": "glm-4.5-air",
                "messages": [
                    ["role": "system", "content": prompts.system],
                    ["role": "user", "content": prompts.user]
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
