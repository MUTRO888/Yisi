import Foundation
import SQLite3

class LearningManager {
    static let shared = LearningManager()
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    private init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("com.yisi.app", isDirectory: true)
        
        // Create directory if needed
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        dbPath = appDir.appendingPathComponent("learned_rules.db").path
        openDatabase()
        createTableIfNeeded()
    }
    
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Error opening database")
        }
    }
    
    private func createTableIfNeeded() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS learned_rules (
            id TEXT PRIMARY KEY,
            original_text TEXT NOT NULL,
            ai_translation TEXT NOT NULL,
            user_correction TEXT NOT NULL,
            reasoning TEXT NOT NULL,
            rule_pattern TEXT NOT NULL,
            category TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            usage_count INTEGER DEFAULT 0
        );
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error creating table")
            }
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - AI Analysis
    
    func analyzeCorrection(
        originalText: String,
        aiTranslation: String,
        userCorrection: String
    ) async throws -> UserLearnedRule {
        // Use Gemini/Zhipu to analyze the correction
        let provider = getAPIProvider()
        let analysisPrompt = generateAnalysisPrompt(
            originalText: originalText,
            aiTranslation: aiTranslation,
            userCorrection: userCorrection
        )
        
        // Call API
        let analysisJSON = try await callAnalysisAPI(prompt: analysisPrompt, provider: provider)
        
        // Clean and parse response
        let cleanedJSON = extractJSON(from: analysisJSON)
        guard let jsonData = cleanedJSON.data(using: .utf8) else {
            throw NSError(domain: "LearningError", code: 4, 
                         userInfo: [NSLocalizedDescriptionKey: "Invalid JSON encoding", "rawResponse": analysisJSON])
        }
        
        let analysis: RuleAnalysisResponse
        do {
            analysis = try JSONDecoder().decode(RuleAnalysisResponse.self, from: jsonData)
        } catch {
            print("❌ JSON Decoding Error:")
            print("  - Error: \(error)")
            print("  - Raw Response: \(analysisJSON)")
            print("  - Cleaned JSON: \(cleanedJSON)")
            throw NSError(domain: "LearningError", code: 5, 
                         userInfo: [NSLocalizedDescriptionKey: "JSON parsing failed: \(error.localizedDescription)", 
                                   "rawResponse": analysisJSON,
                                   "cleanedJSON": cleanedJSON])
        }
        
        // Create rule
        let categoryRaw = analysis.category
        // Map English category from AI to Chinese rawValue if needed, or use as is if it matches
        var category = RuleCategory(rawValue: categoryRaw)
        
        if category == nil {
            // Try mapping from English keys to Enum
            switch categoryRaw {
            case "attributeToVerb": category = .attributeToVerb
            case "metaphor": category = .metaphor
            case "terminology": category = .terminology
            case "style": category = .style
            default: category = .other
            }
        }
        
        let finalCategory = category ?? .other
        print("DEBUG: Rule Category - AI: \(categoryRaw) -> Final: \(finalCategory.rawValue)")
        
        let rule = UserLearnedRule(
            originalText: originalText,
            aiTranslation: aiTranslation,
            userCorrection: userCorrection,
            reasoning: analysis.reasoning,
            rulePattern: analysis.rulePattern,
            category: finalCategory
        )
        
        // Save to database
        print("DEBUG: Attempting to save rule to DB...")
        try saveRule(rule)
        print("DEBUG: Rule saved successfully! ID: \(rule.id)")
        
        return rule
    }
    
    // Helper to extract JSON from markdown code blocks
    private func extractJSON(from text: String) -> String {
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code block if present
        if jsonString.hasPrefix("```json") {
            jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
            jsonString = jsonString.replacingOccurrences(of: "```", with: "")
        } else if jsonString.hasPrefix("```") {
            jsonString = jsonString.replacingOccurrences(of: "```", with: "")
        }
        
        return jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func generateAnalysisPrompt(originalText: String, aiTranslation: String, userCorrection: String) -> String {
        return """
        You are a translation quality analyzer. Analyze why the user corrected the AI translation.

        Original Text: "\(originalText)"
        AI Translation: "\(aiTranslation)"
        User Correction: "\(userCorrection)"

        Output ONLY valid JSON with these EXACT keys (use camelCase):
        {
          "reasoning": "Brief analysis in 2-3 sentences",
          "rulePattern": "**Bad Case**: ... **Expected Case**: ... **Instruction**: ...",
          "category": "attributeToVerb"
        }
        
        IMPORTANT:
        - Use "rulePattern" NOT "rule_pattern"
        - Category must be one of: attributeToVerb, metaphor, terminology, style, other
        - No markdown code blocks, just pure JSON
        """
    }
    
    private func callAnalysisAPI(prompt: String, provider: APIProvider) async throws -> String {
        // Reuse TranslationService's API calling logic
        guard let apiKey = getAPIKey(for: provider) else {
            throw NSError(domain: "LearningError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing API Key"])
        }
        
        switch provider {
        case .gemini:
            return try await callGeminiAnalysis(prompt: prompt, apiKey: apiKey)
        case .zhipu:
            return try await callZhipuAnalysis(prompt: prompt, apiKey: apiKey)
        default:
            throw NSError(domain: "LearningError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unsupported provider for analysis"])
        }
    }
    
    private func callGeminiAnalysis(prompt: String, apiKey: String) async throws -> String {
        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "response_mime_type": "application/json",
                "temperature": 0.3
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=\(apiKey)") else {
            throw NSError(domain: "LearningError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let firstPart = parts.first,
           let text = firstPart["text"] as? String {
            return text
        }
        
        throw NSError(domain: "LearningError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse analysis"])
    }
    
    private func callZhipuAnalysis(prompt: String, apiKey: String) async throws -> String {
        let body: [String: Any] = [
            "model": "glm-4.5-air",
            "messages": [
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
        request.timeoutInterval = 30
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        
        throw NSError(domain: "LearningError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse analysis"])
    }
    
    // MARK: - Database Operations
    
    func saveRule(_ rule: UserLearnedRule) throws {
        print("DEBUG: saveRule called for rule: \(rule.id)")
        let insertQuery = """
        INSERT OR REPLACE INTO learned_rules 
        (id, original_text, ai_translation, user_correction, reasoning, rule_pattern, category, created_at, usage_count)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (rule.id.uuidString as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (rule.originalText as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (rule.aiTranslation as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (rule.userCorrection as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 5, (rule.reasoning as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, (rule.rulePattern as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 7, (rule.category.rawValue as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(statement, 8, Int64(rule.createdAt.timeIntervalSince1970))
            sqlite3_bind_int(statement, 9, Int32(rule.usageCount))
            
            if sqlite3_step(statement) != SQLITE_DONE {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                print("DEBUG: SQL Step Error: \(errorMsg)")
                sqlite3_finalize(statement)
                throw NSError(domain: "LearningError", code: 7, userInfo: [NSLocalizedDescriptionKey: "Failed to execute insert statement: \(errorMsg)"])
            }
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("DEBUG: SQL Prepare Error: \(errorMsg)")
            throw NSError(domain: "LearningError", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to prepare insert statement: \(errorMsg)"])
        }
        
        print("DEBUG: SQL Insert Successful")
        sqlite3_finalize(statement)
    }
    
    func getAllRules() -> [UserLearnedRule] {
        var rules: [UserLearnedRule] = []
        let query = "SELECT * FROM learned_rules ORDER BY created_at DESC;"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let rule = parseRule(from: statement) {
                    rules.append(rule)
                }
            }
        }
        sqlite3_finalize(statement)
        return rules
    }
    
    func deleteRule(id: UUID) throws {
        let deleteQuery = "DELETE FROM learned_rules WHERE id = ?;"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, id.uuidString, -1, nil)
            if sqlite3_step(statement) != SQLITE_DONE {
                throw NSError(domain: "LearningError", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to delete rule"])
            }
        }
        sqlite3_finalize(statement)
    }
    
    private func parseRule(from statement: OpaquePointer?) -> UserLearnedRule? {
        guard let statement = statement else { return nil }
        
        let idString = String(cString: sqlite3_column_text(statement, 0))
        let originalText = String(cString: sqlite3_column_text(statement, 1))
        let aiTranslation = String(cString: sqlite3_column_text(statement, 2))
        let userCorrection = String(cString: sqlite3_column_text(statement, 3))
        let reasoning = String(cString: sqlite3_column_text(statement, 4))
        let rulePattern = String(cString: sqlite3_column_text(statement, 5))
        let categoryString = String(cString: sqlite3_column_text(statement, 6))
        let timestamp = sqlite3_column_int64(statement, 7)
        let usageCount = sqlite3_column_int(statement, 8)
        
        guard let id = UUID(uuidString: idString),
              let category = RuleCategory(rawValue: categoryString) else {
            return nil
        }
        
        return UserLearnedRule(
            id: id,
            originalText: originalText,
            aiTranslation: aiTranslation,
            userCorrection: userCorrection,
            reasoning: reasoning,
            rulePattern: rulePattern,
            category: category,
            createdAt: Date(timeIntervalSince1970: TimeInterval(timestamp)),
            usageCount: Int(usageCount)
        )
    }
    
    // MARK: - Helper Methods
    
    private func getAPIProvider() -> APIProvider {
        if let providerString = UserDefaults.standard.string(forKey: "api_provider"),
           let provider = APIProvider(rawValue: providerString) {
            return provider
        }
        return .gemini
    }
    
    private func getAPIKey(for provider: APIProvider) -> String? {
        switch provider {
        case .gemini:
            return UserDefaults.standard.string(forKey: "gemini_api_key")
        case .zhipu:
            return UserDefaults.standard.string(forKey: "zhipu_api_key")
        case .openai:
            return UserDefaults.standard.string(forKey: "openai_api_key")
        }
    }
    
    deinit {
        sqlite3_close(db)
    }
}
