import Foundation
import AppKit

// MARK: - 统一的请求配置要素
struct AIRequestConfig {
    let apiKey: String
    let model: String
    let temperature: Double
    let maxTokens: Int
    let enableDeepThinking: Bool // 关键开关
}

// MARK: - 统一的消息结构 (兼容文本和多模态)
enum AIMessageRole: String {
    case system
    case user
    case assistant
}

struct AIMessageContent {
    let text: String
    let image: Data? // 可选的图片数据
    
    init(text: String, image: Data? = nil) {
        self.text = text
        self.image = image
    }
}

struct AIMessage {
    let role: AIMessageRole
    let content: AIMessageContent
    
    init(role: AIMessageRole, content: AIMessageContent) {
        self.role = role
        self.content = content
    }
    
    init(role: AIMessageRole, text: String, image: Data? = nil) {
        self.role = role
        self.content = AIMessageContent(text: text, image: image)
    }
}

// MARK: - 统一接口协议
protocol AIProvider {
    var provider: APIProvider { get }
    
    /// 发送请求并返回流式/非流式结果 (目前统一返回完整 String)
    func send(messages: [AIMessage], config: AIRequestConfig) async throws -> String
}

// MARK: - 辅助扩展：判断是否为推理模型 (逻辑复用)
extension AIProvider {
    func isReasoningModel(_ model: String) -> Bool {
        let lower = model.lowercased()
        if lower.contains("o1") || lower.contains("o3") { return true }
        if lower.contains("thinking") { return true }
        if lower.contains("gemini-2.5") { return true }
        if lower.contains("glm-4.5") { return true } // GLM-4.5 视为推理/混合模型
        return false
    }
}
