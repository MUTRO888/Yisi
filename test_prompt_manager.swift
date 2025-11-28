import Foundation

func testPromptManagerFile() {
    let filePath = "/Users/mutro/Desktop/开发/Yisi/Yisi/Core/Translation/PromptManager.swift"
    guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
        print("❌ Could not read PromptManager.swift")
        return
    }
    
    print("Testing System Prompt Generation (File Content)...")
    
    if content.contains("Golden Few-Shot Samples") && content.contains("Output Schema") {
        print("✅ System Prompt contains required sections.")
    } else {
        print("❌ System Prompt missing sections.")
    }
    
    if content.contains("Force Majeure") && content.contains("myocardial infarction") {
        print("✅ System Prompt contains few-shot examples.")
    } else {
        print("❌ System Prompt missing few-shot examples.")
    }
    
    if content.contains("CRITICAL RULE: Never flatten or translate the URL part of a Markdown link") {
        print("✅ System Prompt contains Markdown link preservation rule.")
    } else {
        print("❌ System Prompt missing Markdown link preservation rule.")
    }
}

testPromptManagerFile()
