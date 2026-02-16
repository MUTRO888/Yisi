import Foundation
import SwiftUI
import Translation

// MARK: - Error Types

enum SystemTranslationError: LocalizedError {
    case unsupportedSystem
    case serviceUnavailable
    case translationFailed(String)
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .unsupportedSystem:
            return "System translation requires macOS 15.0 or later"
        case .serviceUnavailable:
            return "Translation service is currently unavailable"
        case .translationFailed(let reason):
            return "Translation failed: \(reason)"
        case .timeout:
            return "Translation request timed out"
        }
    }
}

// MARK: - System Translation Manager

@available(macOS 15.0, *)
@MainActor
public final class SystemTranslationManager: ObservableObject {
    
    public static let shared = SystemTranslationManager()
    
    @Published var configuration: TranslationSession.Configuration?
    @Published private(set) var isTranslating = false
    
    private var textToTranslate: String = ""
    private var translationResult: String?
    private var translationError: Error?
    
    private init() {}
    
    // MARK: - Public API
    
    /// Translate text using macOS system translation
    public func translate(
        _ text: String,
        to targetLanguage: String,
        from sourceLanguage: String? = nil
    ) async throws -> String {
        let resolvedSource: String
        if let explicit = sourceLanguage {
            resolvedSource = explicit
        } else {
            let detection = LanguageDetectionService.shared.detect(text, target: targetLanguage)
            resolvedSource = detection.sourceLanguage
            print("[SystemTranslation] Detected source: \(resolvedSource) (confidence: \(String(format: "%.2f", detection.confidence)), method: \(detection.method))")
        }
        
        do {
            let raw = try await executeTranslation(text, to: targetLanguage, from: resolvedSource)
            return normalizeNewlines(original: text, translated: raw)
        } catch {
            // Fallback: if user-selected source was wrong, retry with algorithm detection
            if sourceLanguage != nil {
                let detection = LanguageDetectionService.shared.detect(text, target: targetLanguage)
                let fallback = detection.sourceLanguage
                if fallback != resolvedSource {
                    print("[SystemTranslation] Explicit source '\(resolvedSource)' failed, retrying with detected: \(fallback) (\(detection.method))")
                    let raw = try await executeTranslation(text, to: targetLanguage, from: fallback)
                    return normalizeNewlines(original: text, translated: raw)
                }
            }
            throw error
        }
    }
    
    // MARK: - Post-Processing
    
    /// Preserve the original text's newline pattern in the translated output.
    /// Apple's Translation API sometimes inserts extra blank lines that
    /// were not present in the source text.
    private func normalizeNewlines(original: String, translated: String) -> String {
        let hasConsecutiveNewlines = original.contains("\n\n")
        if hasConsecutiveNewlines {
            return translated
        }
        
        var result = translated
        while result.contains("\n\n") {
            result = result.replacingOccurrences(of: "\n\n", with: "\n")
        }
        return result
    }
    
    /// Internal execution method
    private func executeTranslation(
        _ text: String,
        to targetLanguage: String,
        from sourceLanguage: String
    ) async throws -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return text
        }
        
        // Wait for any previous translation to complete
        while isTranslating {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
        
        textToTranslate = text
        translationResult = nil
        translationError = nil
        isTranslating = true
        
        let targetLocale = Locale.Language(identifier: targetLanguage)
        let sourceLocale = Locale.Language(identifier: sourceLanguage)
        
        print("[SystemTranslation] Starting translation request (source: \(sourceLanguage), target: \(targetLanguage))")
        
        // Trigger configuration change to start translationTask
        // We set to nil first to ensure a change is detected if the locales are the same as before
        configuration = nil
        try? await Task.sleep(nanoseconds: 10_000_000) // Small delay to let nil propagate
        
        configuration = TranslationSession.Configuration(
            source: sourceLocale,
            target: targetLocale
        )
        print("[SystemTranslation] Configuration set (source: \(sourceLanguage), target: \(targetLanguage))")
        
        // Wait for result with timeout
        let timeoutSeconds = 30
        var waited = 0
        // Important: check isTranslating still true, because handleSession might have set it false
        while translationResult == nil && translationError == nil && isTranslating && waited < timeoutSeconds * 10 {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            waited += 1
        }
        
        // Final cleanup
        let result = translationResult
        let error = translationError
        
        isTranslating = false
        configuration = nil
        
        if let error = error {
            throw error
        }
        
        if let result = result {
            return result
        }
        
        // If we timed out or the task was cancelled
        throw SystemTranslationError.timeout
    }
    
    /// Called when TranslationSession is ready via .translationTask modifier
    public func handleSession(_ session: TranslationSession) async {
        guard isTranslating && !textToTranslate.isEmpty else {
            return
        }
        
        print("[SystemTranslation] Session active, translating...")
        
        do {
            let response = try await session.translate(textToTranslate)
            translationResult = response.targetText
            print("[SystemTranslation] Success")
        } catch {
            print("[SystemTranslation] Failed: \(error.localizedDescription)")
            translationError = SystemTranslationError.translationFailed(error.localizedDescription)
        }
        
        // Always mark as finished to unlock the waiter
        isTranslating = false
    }
}

// MARK: - System Translation Host View

@available(macOS 15.0, *)
public struct SystemTranslationHost: View {
    @ObservedObject private var manager = SystemTranslationManager.shared
    
    public init() {}
    
    public var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .translationTask(manager.configuration) { session in
                await manager.handleSession(session)
            }
    }
}

// MARK: - Compatibility Wrapper

public struct SystemTranslation {
    
    public static var isSupported: Bool {
        if #available(macOS 15.0, *) {
            return true
        }
        return false
    }
    
    @MainActor
    public static func translate(
        _ text: String,
        to targetLanguage: String,
        from sourceLanguage: String? = nil
    ) async throws -> String {
        guard #available(macOS 15.0, *) else {
            throw SystemTranslationError.unsupportedSystem
        }
        
        return try await SystemTranslationManager.shared.translate(
            text,
            to: targetLanguage,
            from: sourceLanguage
        )
    }
}
