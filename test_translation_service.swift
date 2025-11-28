import Foundation

// --- Paste TranslationService Logic Here (Simplified for testing) ---

class TranslationServiceTest {
    
    // MARK: - Smart Pre-processing
    
    func preprocessInput(_ text: String) -> String {
        // Heuristic: If short lines + frequent newlines -> Preserve newlines (Poetry/Code)
        // Heuristic: If long sentences broken by newlines mid-sentence -> Merge lines (PDF Copy)
        
        let lines = text.components(separatedBy: .newlines)
        if lines.isEmpty { return text }
        
        // Heuristic: Check if lines should be merged based on punctuation and next line capitalization
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
    
    func containsMarkdown(_ text: String) -> Bool {
        let markdownMarkers = ["`", "**", "#", "[", "]"]
        for marker in markdownMarkers {
            if text.contains(marker) {
                return true
            }
        }
        return false
    }
}

// --- Test Logic ---

func testTranslationService() {
    let service = TranslationServiceTest()
    
    print("Testing Smart Pre-processing...")
    
    // Case 1: Poetry (Short lines, keep newlines)
    let poetry = "The woods are lovely, dark and deep,\nBut I have promises to keep,\nAnd miles to go before I sleep."
    let processedPoetry = service.preprocessInput(poetry)
    if processedPoetry == poetry {
        print("✅ Poetry preserved.")
    } else {
        print("❌ Poetry modified: \(processedPoetry)")
    }
    
    // Case 2: PDF Copy (Long lines broken mid-sentence)
    let pdfText = "This is a long sentence that has been broken\nby a newline character in the middle of the\nsentence. It should be merged."
    let processedPDF = service.preprocessInput(pdfText)
    if processedPDF.contains("broken by a newline") && !processedPDF.contains("broken\nby") {
        print("✅ PDF text merged.")
    } else {
        print("❌ PDF text not merged correctly: \(processedPDF)")
    }
    
    print("\nTesting Markdown Detection...")
    
    // Case 3: Markdown
    let markdown = "This is **bold** text."
    if service.containsMarkdown(markdown) {
        print("✅ Markdown detected.")
    } else {
        print("❌ Markdown not detected.")
    }
    
    // Case 4: Plain Text
    let plain = "This is plain text."
    if !service.containsMarkdown(plain) {
        print("✅ Plain text identified.")
    } else {
        print("❌ Plain text flagged as markdown.")
    }
}

testTranslationService()
