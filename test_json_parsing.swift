import Foundation

func extractJSON(from text: String) -> String {
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

func testJSONExtraction() {
    print("Testing JSON Extraction...")
    
    // Case 1: Clean JSON
    let clean = "{\"key\": \"value\"}"
    if extractJSON(from: clean) == clean {
        print("✅ Clean JSON preserved.")
    } else {
        print("❌ Clean JSON modified.")
    }
    
    // Case 2: Markdown Wrapped JSON
    let wrapped = "```json\n{\"key\": \"value\"}\n```"
    let extracted = extractJSON(from: wrapped)
    if extracted == "{\"key\": \"value\"}" {
        print("✅ Markdown wrapped JSON extracted.")
    } else {
        print("❌ Failed to extract markdown wrapped JSON: \(extracted)")
    }
    
    // Case 3: Markdown Wrapped JSON (no lang)
    let wrappedNoLang = "```\n{\"key\": \"value\"}\n```"
    let extractedNoLang = extractJSON(from: wrappedNoLang)
    if extractedNoLang == "{\"key\": \"value\"}" {
        print("✅ Markdown wrapped JSON (no lang) extracted.")
    } else {
        print("❌ Failed to extract markdown wrapped JSON (no lang): \(extractedNoLang)")
    }
    
    // Case 4: Plain Text
    let plain = "This is plain text."
    if extractJSON(from: plain) == plain {
        print("✅ Plain text preserved.")
    } else {
        print("❌ Plain text modified.")
    }
}

testJSONExtraction()
