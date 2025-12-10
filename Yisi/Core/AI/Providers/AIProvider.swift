import Foundation
import AppKit

// MARK: - 统一的请求配置要素

struct AIRequestConfig {
    let apiKey: String
    let model: String
    let temperature: Double
    let maxTokens: Int
    let enableNativeReasoning: Bool // API 层面是否开启原生推理能力
}

// MARK: - 统一的消息结构 (兼容文本和多模态)

enum AIMessageRole: String {
    case system
    case user
    case assistant
}

struct AIMessageContent {
    let text: String
    let image: Data?
    
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

// MARK: - 推理能力协议（可扩展）

/// 推理能力配置协议
/// 每个 Provider 实现自己的推理模型判断和参数配置逻辑
protocol ReasoningCapability {
    /// 判断模型是否为推理模型
    /// - Parameter model: 模型 ID
    /// - Returns: 是否具备原生推理能力
    func isReasoningModel(_ model: String) -> Bool
    
    /// 配置推理参数到请求 body
    /// - Parameters:
    ///   - body: 请求 body（inout 修改）
    ///   - model: 模型 ID
    ///   - enabled: 是否启用推理模式
    func configureReasoning(body: inout [String: Any], model: String, enabled: Bool)
}

// MARK: - 统一接口协议

protocol AIProvider: ReasoningCapability {
    var provider: APIProvider { get }
    
    /// 发送请求并返回结果
    func send(messages: [AIMessage], config: AIRequestConfig) async throws -> String
}

// MARK: - 默认实现（无推理能力）

extension ReasoningCapability {
    /// 默认实现：非推理模型
    func isReasoningModel(_ model: String) -> Bool {
        return false
    }
    
    /// 默认实现：无需配置推理参数
    func configureReasoning(body: inout [String: Any], model: String, enabled: Bool) {
        // 默认不做任何操作
    }
}
