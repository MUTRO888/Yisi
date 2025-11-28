import Foundation

struct TranslationResponse: Codable {
    let detected_type: String
    let thinking_process: String
    let translation_result: String
}
