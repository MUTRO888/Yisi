import Foundation

// MARK: - Rule Category

enum RuleCategory: String, Codable {
    case attributeToVerb = "属性定语转动词"
    case metaphor = "隐喻转化"
    case terminology = "专业术语"
    case style = "个人风格偏好"
    case other = "其他"
}

// MARK: - User Learned Rule

struct UserLearnedRule: Codable, Identifiable {
    let id: UUID
    let originalText: String        // 原文
    let aiTranslation: String       // AI 的译文
    let userCorrection: String      // 用户修正后的译文
    let reasoning: String           // AI 分析的改进原因
    let rulePattern: String         // 提炼的规则模式
    let category: RuleCategory      // 规则类别
    let createdAt: Date
    var usageCount: Int             // 被应用次数
    
    init(id: UUID = UUID(),
         originalText: String,
         aiTranslation: String,
         userCorrection: String,
         reasoning: String,
         rulePattern: String,
         category: RuleCategory,
         createdAt: Date = Date(),
         usageCount: Int = 0) {
        self.id = id
        self.originalText = originalText
        self.aiTranslation = aiTranslation
        self.userCorrection = userCorrection
        self.reasoning = reasoning
        self.rulePattern = rulePattern
        self.category = category
        self.createdAt = createdAt
        self.usageCount = usageCount
    }
}

// MARK: - AI Analysis Response

struct RuleAnalysisResponse: Codable {
    let reasoning: String
    let rulePattern: String
    let category: String
}
