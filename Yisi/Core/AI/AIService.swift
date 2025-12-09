import Foundation
import AppKit

enum APIProvider: String {
    case openai = "OpenAI"
    case gemini = "Gemini"
    case zhipu = "Zhipu AI"
}

class AIService: ObservableObject {
    static let shared = AIService()
    
    private init() {}
    
    func processText(_ text: String, mode: PromptMode = .defaultTranslation, sourceLanguage: String = "Auto Detect", targetLanguage: String = "简体中文", userPerception: String? = nil, userInstruction: String? = nil) async throws -> String {
        let provider = getAPIProvider()
        let preprocessedText = preprocessInput(text)
        
        let result: String
        switch provider {
        case .openai:
            result = try await translateWithOpenAI(preprocessedText, mode: mode, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage, userPerception: userPerception, userInstruction: userInstruction)
        case .gemini:
            result = try await translateWithGemini(preprocessedText, mode: mode, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage, userPerception: userPerception, userInstruction: userInstruction)
        case .zhipu:
            result = try await translateWithZhipu(preprocessedText, mode: mode, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage, userPerception: userPerception, userInstruction: userInstruction)
        }
        
        // Save to History
        HistoryManager.shared.addHistory(
            sourceText: text, // Save original text, not preprocessed
            targetText: result,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            mode: mode,
            customPerception: userPerception,
            customInstruction: userInstruction
        )
        
        return result
    }
    
    // MARK: - Image Recognition
    
    /// 处理图片识别（支持多 API 提供商）
    /// - Parameters:
    ///   - image: 要识别的图片
    ///   - instruction: 给 AI 的指令（由调用方根据模式决定）
    /// - Returns: AI 的响应文本
    func processImage(_ image: NSImage, instruction: String) async throws -> String {
        let provider = getProvider(for: .image)
        
        guard let apiKey = getAPIKey(for: provider, usage: .image), !apiKey.isEmpty else {
            throw NSError(domain: "AIError", code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "Please set your \(provider.rawValue) API Key in Settings for image recognition."])
        }
        
        // 将 NSImage 转换为 Base64
        guard let imageData = imageToBase64(image) else {
            throw NSError(domain: "AIError", code: 2, 
                         userInfo: [NSLocalizedDescriptionKey: "Failed to encode image."])
        }
        
        let model = getModel(for: provider, usage: .image)
        
        let parsedResult: String
        
        switch provider {
        case .gemini:
            parsedResult = try await processImageWithGemini(imageData: imageData, instruction: instruction, apiKey: apiKey, model: model)
        case .openai:
            parsedResult = try await processImageWithOpenAI(imageData: imageData, instruction: instruction, apiKey: apiKey, model: model)
        case .zhipu:
            parsedResult = try await processImageWithZhipu(imageData: imageData, instruction: instruction, apiKey: apiKey, model: model)
        }
        
        // 保存到历史记录（在主线程执行 UI 更新）
        let capturedImage = image
        DispatchQueue.main.async {
            HistoryManager.shared.addHistory(
                sourceText: "", // Empty source text for image recognition
                targetText: parsedResult,
                sourceLanguage: "Auto",
                targetLanguage: "Auto",
                mode: .defaultTranslation,
                image: capturedImage
            )
        }
        
        return parsedResult
    }
    
    // MARK: - Provider-Specific Image Processing
    
    private func processImageWithGemini(imageData: String, instruction: String, apiKey: String, model: String) async throws -> String {
        let apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": instruction],
                        [
                            "inline_data": [
                                "mime_type": "image/png",
                                "data": imageData
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 4096
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        guard let url = URL(string: apiUrl) else {
            throw NSError(domain: "AIError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 60
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "AIError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Gemini API Error: \(errorText)"])
        }
        
        // 解析响应
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let firstPart = parts.first,
           let rawText = firstPart["text"] as? String {
            return parseImageResult(rawText)
        }
        
        throw NSError(domain: "AIError", code: 5, 
                     userInfo: [NSLocalizedDescriptionKey: "Failed to parse Gemini image recognition response"])
    }
    
    private func processImageWithOpenAI(imageData: String, instruction: String, apiKey: String, model: String) async throws -> String {
        let body: [String: Any] = [
            "model": model,
            "temperature": 0.1,
            "max_tokens": 4096,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": instruction
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/png;base64,\(imageData)"
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 60
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "AIError", code: 4, userInfo: [NSLocalizedDescriptionKey: "OpenAI API Error: \(errorText)"])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return parseImageResult(content)
        }
        
        throw NSError(domain: "AIError", code: 5, 
                     userInfo: [NSLocalizedDescriptionKey: "Failed to parse OpenAI image recognition response"])
    }
    
    private func processImageWithZhipu(imageData: String, instruction: String, apiKey: String, model: String) async throws -> String {
        let body: [String: Any] = [
            "model": model,
            "temperature": 0.1,
            "max_tokens": 4096,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": instruction
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/png;base64,\(imageData)"
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: URL(string: "https://open.bigmodel.cn/api/paas/v4/chat/completions")!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 60
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "AIError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Zhipu API Error: \(errorText)"])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return parseImageResult(content)
        }
        
        throw NSError(domain: "AIError", code: 5, 
                     userInfo: [NSLocalizedDescriptionKey: "Failed to parse Zhipu image recognition response"])
    }
    
    /// Parse image recognition result from AI response
    private func parseImageResult(_ rawText: String) -> String {
        let cleanJSON = extractJSON(from: rawText)
        
        if let jsonData = cleanJSON.data(using: .utf8),
           let jsonObj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            // 尝试从 JSON 中提取翻译结果
            if let translationResult = jsonObj["translation_result"] as? String {
                return translationResult
            } else if let result = jsonObj["result"] as? String {
                return result
            } else if let answer = jsonObj["answer"] as? String {
                return answer
            }
        }
        
        // 如果不是有效的 JSON，直接使用原始文本
        return rawText
    }
    
    /// 将 NSImage 转换为 Base64 字符串
    private func imageToBase64(_ image: NSImage) -> String? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return nil
        }
        return pngData.base64EncodedString()
    }
    
    // MARK: - API Usage Context
    
    enum APIUsage {
        case text
        case image
    }
    
    /// Get the API provider for the specified usage context
    private func getProvider(for usage: APIUsage) -> APIProvider {
        switch usage {
        case .text:
            return getAPIProvider()
        case .image:
            // If apply_api_to_image_mode is true (or key doesn't exist, defaulting to true), use text provider
            if shouldUseTextSettingsForImage() {
                return getAPIProvider()
            }
            // Use image-specific provider
            if let providerString = UserDefaults.standard.string(forKey: "image_api_provider"),
               let provider = APIProvider(rawValue: providerString) {
                return provider
            }
            return .gemini
        }
    }
    
    /// Get the API key for the specified provider and usage context
    private func getAPIKey(for provider: APIProvider, usage: APIUsage) -> String? {
        let prefix = (usage == .image && !shouldUseTextSettingsForImage()) ? "image_" : ""
        
        switch provider {
        case .gemini:
            return UserDefaults.standard.string(forKey: "\(prefix)gemini_api_key")
        case .openai:
            return UserDefaults.standard.string(forKey: "\(prefix)openai_api_key")
        case .zhipu:
            return UserDefaults.standard.string(forKey: "\(prefix)zhipu_api_key")
        }
    }
    
    /// Get the model for the specified provider and usage context
    private func getModel(for provider: APIProvider, usage: APIUsage) -> String {
        let prefix = (usage == .image && !shouldUseTextSettingsForImage()) ? "image_" : ""
        
        switch provider {
        case .gemini:
            return UserDefaults.standard.string(forKey: "\(prefix)gemini_model") ?? "gemini-2.5-flash"
        case .openai:
            return UserDefaults.standard.string(forKey: "\(prefix)openai_model") ?? "gpt-4o-mini"
        case .zhipu:
            return UserDefaults.standard.string(forKey: "\(prefix)zhipu_model") ?? "glm-4.5-air"
        }
    }
    
    /// Check if image mode should use text settings (apply_api_to_image_mode toggle)
    private func shouldUseTextSettingsForImage() -> Bool {
        // Default to true if key doesn't exist
        if UserDefaults.standard.object(forKey: "apply_api_to_image_mode") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "apply_api_to_image_mode")
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
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common AI preambles
        let preambles = [
            "Here is the translation:",
            "Translation:",
            "Result:",
            "Here is the result:",
            "Output:",
            "Response:"
        ]
        for preamble in preambles {
            if jsonString.hasPrefix(preamble) {
                jsonString = String(jsonString.dropFirst(preamble.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Remove markdown code blocks if present (Zhipu AI wraps JSON in ```json ... ```)
        if jsonString.contains("```json") {
            jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
        }
        if jsonString.contains("```") {
            jsonString = jsonString.replacingOccurrences(of: "```", with: "")
        }
        
        // Trim again after removing code fences
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Only extract JSON object if it's wrapped in extra text
        // Check if the entire string is already a valid JSON object
        if jsonString.hasPrefix("{") && jsonString.hasSuffix("}") {
            // Already looks like clean JSON, return as-is
            return jsonString
        }
        
        // If we have curly braces but they're not at the start/end, extract the JSON object
        if let startIndex = jsonString.firstIndex(of: "{"),
           let endIndex = jsonString.lastIndex(of: "}") {
            jsonString = String(jsonString[startIndex...endIndex])
        }
        
        return jsonString
    }
    
    private func parseTranslationResult(from jsonString: String, mode: PromptMode) throws -> String {
        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "TranslationError", code: 3, 
                         userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON"])
        }
        
        guard let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // If JSON parsing fails, but the string looks like plain text, return it
            let trimmed = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.hasPrefix("{") && !trimmed.hasSuffix("}") {
                return trimmed
            }
            throw NSError(domain: "TranslationError", code: 3, 
                         userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format: \(jsonString.prefix(100))"])
        }
        
        // Try all possible keys that different AI providers might use
        let possibleKeys = [
            "translation_result",  // TranslationBuilder
            "result",              // CustomBuilder, PresetBuilder
            "answer",              // Fallback
            "content",             // Some AI variants
            "output",              // Alternative
            "text"                 // Plain response
        ]
        
        // Try each key
        for key in possibleKeys {
            if let result = jsonObj[key] {
                if let stringResult = result as? String, !stringResult.isEmpty {
                    return stringResult
                } else if let dictResult = result as? [String: Any] {
                    // Handle nested object (e.g., {title: "...", author: "..."})
                    return formatNestedResult(dictResult)
                }
            }
        }
        
        // If all keys failed, provide detailed error
        let availableKeys = jsonObj.keys.joined(separator: ", ")
        print("DEBUG: Available JSON keys: \(availableKeys)")
        print("DEBUG: Full JSON content: \(jsonString)")
        
        throw NSError(domain: "TranslationError", code: 3, 
                     userInfo: [NSLocalizedDescriptionKey: "No valid result key found. Available keys: \(availableKeys)"])
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
        // AI 自动检测语言，无需预先检测
        let systemPrompt: String
        if mode == .temporaryCustom {
            systemPrompt = PromptCoordinator.shared.generateCustomPrompt(
                inputContext: userPerception,
                outputRequirement: userInstruction
            )
        } else {
            systemPrompt = PromptCoordinator.shared.generateSystemPrompt(
                for: mode,
                withLearnedRules: true
            )
        }
        
        let userPrompt = PromptCoordinator.shared.generateUserPrompt(
            text: text,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            mode: mode
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
        
        let model = UserDefaults.standard.string(forKey: "openai_model") ?? "gpt-4o-mini"
        
        let body: [String: Any] = [
            "model": model,
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
            
            // DEBUG: Print raw response
            print("DEBUG OpenAI Response:")
            print(cleanJSON)
            
            return try parseTranslationResult(from: cleanJSON, mode: mode)
        }
        
        // DEBUG: Print full error response
        if let errorStr = String(data: data, encoding: .utf8) {
            print("DEBUG OpenAI Full Response Error:")
            print(errorStr)
        }
        
        throw NSError(domain: "TranslationError", code: 3, 
                     userInfo: [NSLocalizedDescriptionKey: "Failed to parse translation response structure"])
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
            
            let model = UserDefaults.standard.string(forKey: "gemini_model") ?? "gemini-2.0-flash-exp"
            let apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
            
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
                    "maxOutputTokens": max(2048, self.getMaxTokens(for: text))  // 增加最小值到 2048
                ]
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            
            guard let url = URL(string: apiUrl) else {
                throw NSError(domain: "TranslationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            request.timeoutInterval = 90  // 90 second timeout for long texts
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("❌ Gemini API Error (HTTP Status: \((response as? HTTPURLResponse)?.statusCode ?? 0))")
                if let errorText = String(data: data, encoding: .utf8) {
                    print("API Error Response:")
                    print(errorText)
                    throw NSError(domain: "GeminiAPIError", code: 1, userInfo: [NSLocalizedDescriptionKey: errorText])
                }
                throw NSError(domain: "GeminiAPIError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown API Error"])
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
             
            // Return raw API response as error
            let rawResponse = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "GeminiAPIError", code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: rawResponse])
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
            
            let model = UserDefaults.standard.string(forKey: "zhipu_model") ?? "glm-4-flash"
            
            let body: [String: Any] = [
                "model": model,
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
                
                // DEBUG: Print input and raw response
                print("DEBUG Zhipu Input Text: \(text.prefix(100))...")
                print("DEBUG Zhipu Raw Content: \(content)")
                
                 // Parse JSON response
                let cleanJSON = self.extractJSON(from: content)
                
                // DEBUG: Print raw response
                print("DEBUG Zhipu Response:")
                print(cleanJSON)
                
                return try self.parseTranslationResult(from: cleanJSON, mode: mode)
            }
            
            // DEBUG: Print full error response
            if let errorStr = String(data: data, encoding: .utf8) {
                print("DEBUG Zhipu Full Response Error:")
                print(errorStr)
            }
            
            throw NSError(domain: "TranslationError", code: 3, 
                         userInfo: [NSLocalizedDescriptionKey: "Failed to parse translation response structure"])
        }
    }
}
