import Foundation
import NaturalLanguage

// MARK: - Detection Result

struct LanguageDetectionResult {
    let sourceLanguage: String
    let confidence: Double
    let method: String
}

// MARK: - Script Classification

private enum ScriptCategory {
    case cjk
    case hiragana
    case katakana
    case hangul
    case latin
    case cyrillic
    case arabic
    case thai
    case neutral
}

// MARK: - Language Detection Service

final class LanguageDetectionService {

    static let shared = LanguageDetectionService()

    private static let codeSyntaxChars = CharacterSet(
        charactersIn: "{}()[]<>;:=+-*/%&|!~^,.?@#$\\\"\'"
    )

    private static let minNaturalCharsPerLine = 4
    private static let minorityScriptThreshold = 0.05
    private static let codeLineSymbolRatio = 0.6

    private init() {}

    // MARK: - Public API

    func detect(_ text: String, target: String) -> LanguageDetectionResult {
        let lines = text.components(separatedBy: .newlines)

        var scriptVotes: [ScriptCategory: Int] = [:]

        for line in lines {
            let lineResult = analyzeLine(line)

            guard lineResult.totalNaturalChars >= Self.minNaturalCharsPerLine else {
                continue
            }
            guard !lineResult.isCodeLine else {
                continue
            }

            for (script, count) in lineResult.scriptCounts where count > 0 {
                scriptVotes[script, default: 0] += count
            }
        }

        let totalVotes = scriptVotes.values.reduce(0, +)

        guard totalVotes > 0 else {
            return fallbackResult(target: target)
        }

        let dominantEntry = scriptVotes.max(by: { $0.value < $1.value })!
        let dominantScript = dominantEntry.key
        let dominantRatio = Double(dominantEntry.value) / Double(totalVotes)

        let detectedSource = resolveLanguage(
            dominant: dominantScript,
            votes: scriptVotes,
            totalVotes: totalVotes,
            text: text
        )

        if detectedSource == normalizeLanguageCode(target) {
            return resolveCollision(
                detectedSource: detectedSource,
                target: target,
                votes: scriptVotes,
                totalVotes: totalVotes
            )
        }

        return LanguageDetectionResult(
            sourceLanguage: detectedSource,
            confidence: dominantRatio,
            method: "script_analysis"
        )
    }

    // MARK: - Line Analysis

    private struct LineAnalysis {
        var scriptCounts: [ScriptCategory: Int] = [:]
        var totalNaturalChars: Int = 0
        var totalChars: Int = 0
        var symbolChars: Int = 0
        var isCodeLine: Bool { totalChars > 0 && Double(symbolChars) / Double(totalChars) > LanguageDetectionService.codeLineSymbolRatio }
    }

    private func analyzeLine(_ line: String) -> LineAnalysis {
        var result = LineAnalysis()
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        for char in trimmed {
            result.totalChars += 1

            if char.isWhitespace || char.isNewline {
                continue
            }

            let scalars = char.unicodeScalars
            guard let scalar = scalars.first else { continue }

            if Self.codeSyntaxChars.contains(scalar) || char.isNumber {
                result.symbolChars += 1
                continue
            }

            let script = classifyScalar(scalar)
            if script != .neutral {
                result.scriptCounts[script, default: 0] += 1
                result.totalNaturalChars += 1
            }
        }

        return result
    }

    // MARK: - Unicode Script Classification

    private func classifyScalar(_ scalar: Unicode.Scalar) -> ScriptCategory {
        let v = scalar.value

        // CJK Unified Ideographs
        if (0x4E00...0x9FFF).contains(v) { return .cjk }
        // CJK Extension A
        if (0x3400...0x4DBF).contains(v) { return .cjk }
        // CJK Compatibility Ideographs
        if (0xF900...0xFAFF).contains(v) { return .cjk }
        // CJK Extension B+
        if (0x20000...0x2A6DF).contains(v) { return .cjk }

        // Hiragana
        if (0x3040...0x309F).contains(v) { return .hiragana }

        // Katakana
        if (0x30A0...0x30FF).contains(v) { return .katakana }
        // Katakana Phonetic Extensions
        if (0x31F0...0x31FF).contains(v) { return .katakana }

        // Hangul Syllables
        if (0xAC00...0xD7AF).contains(v) { return .hangul }
        // Hangul Jamo
        if (0x1100...0x11FF).contains(v) { return .hangul }
        // Hangul Compatibility Jamo
        if (0x3130...0x318F).contains(v) { return .hangul }

        // Latin (Basic + Extended)
        if (0x0041...0x007A).contains(v) { return .latin }
        if (0x00C0...0x024F).contains(v) { return .latin }
        // Latin Extended Additional
        if (0x1E00...0x1EFF).contains(v) { return .latin }

        // Cyrillic
        if (0x0400...0x04FF).contains(v) { return .cyrillic }

        // Arabic
        if (0x0600...0x06FF).contains(v) { return .arabic }
        if (0x0750...0x077F).contains(v) { return .arabic }

        // Thai
        if (0x0E00...0x0E7F).contains(v) { return .thai }

        // Vietnamese uses Latin script, handled by Latin range above

        return .neutral
    }

    // MARK: - Language Resolution

    private func resolveLanguage(
        dominant: ScriptCategory,
        votes: [ScriptCategory: Int],
        totalVotes: Int,
        text: String
    ) -> String {
        let hasKana = (votes[.hiragana, default: 0] + votes[.katakana, default: 0]) > 0

        switch dominant {
        case .hiragana, .katakana:
            return "ja"
        case .hangul:
            return "ko"
        case .cjk:
            if hasKana {
                return "ja"
            }
            return disambiguateCJK(text: text)
        case .latin:
            return disambiguateLatin(text: text)
        case .cyrillic:
            return "ru"
        case .arabic:
            return "ar"
        case .thai:
            return "th"
        case .neutral:
            return "en"
        }
    }

    // MARK: - Same-Script Disambiguation

    private func disambiguateCJK(text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.languageConstraints = [
            .simplifiedChinese,
            .traditionalChinese,
            .japanese
        ]
        recognizer.languageHints = [
            .simplifiedChinese: 0.4,
            .traditionalChinese: 0.2,
            .japanese: 0.4
        ]
        recognizer.processString(text)

        switch recognizer.dominantLanguage {
        case .japanese:
            return "ja"
        case .traditionalChinese:
            return "zh-Hant"
        default:
            return "zh-Hans"
        }
    }

    private func disambiguateLatin(text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.languageConstraints = [
            .english, .french, .german, .spanish, .vietnamese
        ]
        recognizer.languageHints = [
            .english: 0.5,
            .french: 0.15,
            .german: 0.1,
            .spanish: 0.1,
            .vietnamese: 0.15
        ]
        recognizer.processString(text)

        switch recognizer.dominantLanguage {
        case .french: return "fr"
        case .german: return "de"
        case .spanish: return "es"
        case .vietnamese: return "vi"
        default: return "en"
        }
    }

    // MARK: - Source-Target Collision Resolution

    private func resolveCollision(
        detectedSource: String,
        target: String,
        votes: [ScriptCategory: Int],
        totalVotes: Int
    ) -> LanguageDetectionResult {
        let minorityEntries = votes
            .filter { mapScriptToLanguage($0.key) != normalizeLanguageCode(target) }
            .sorted { $0.value > $1.value }

        if let topMinority = minorityEntries.first {
            let minorityRatio = Double(topMinority.value) / Double(totalVotes)

            if minorityRatio > Self.minorityScriptThreshold {
                let minorityLang = mapScriptToLanguage(topMinority.key)
                return LanguageDetectionResult(
                    sourceLanguage: minorityLang,
                    confidence: minorityRatio,
                    method: "minority_flip"
                )
            }
        }

        let fallbackLang = fallbackOpposite(target: target)
        return LanguageDetectionResult(
            sourceLanguage: fallbackLang,
            confidence: 0.3,
            method: "collision_fallback"
        )
    }

    // MARK: - Helpers

    private func mapScriptToLanguage(_ script: ScriptCategory) -> String {
        switch script {
        case .cjk: return "zh-Hans"
        case .hiragana, .katakana: return "ja"
        case .hangul: return "ko"
        case .latin: return "en"
        case .cyrillic: return "ru"
        case .arabic: return "ar"
        case .thai: return "th"
        case .neutral: return "en"
        }
    }

    private func fallbackOpposite(target: String) -> String {
        let normalized = normalizeLanguageCode(target)
        switch normalized {
        case "zh-Hans", "zh-Hant": return "en"
        case "en": return "zh-Hans"
        case "ja": return "en"
        case "ko": return "en"
        default: return "en"
        }
    }

    private func fallbackResult(target: String) -> LanguageDetectionResult {
        LanguageDetectionResult(
            sourceLanguage: fallbackOpposite(target: target),
            confidence: 0.1,
            method: "fallback"
        )
    }

    private func normalizeLanguageCode(_ code: String) -> String {
        if code.hasPrefix("zh") {
            return code.contains("Hant") ? "zh-Hant" : "zh-Hans"
        }
        return String(code.prefix(2))
    }
}
