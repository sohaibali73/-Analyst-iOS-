import Foundation

// MARK: - AFL Extended Models

struct AFLExplainResponse: Codable {
    let explanation: String?
}

struct AFLValidationResponse: Codable {
    let isValid: Bool?
    let errors: [String]?
    let warnings: [String]?

    enum CodingKeys: String, CodingKey {
        case isValid = "is_valid"
        case errors, warnings
    }
}

struct AFLPreset: Codable, Identifiable {
    let id: String
    let name: String?
    let strategyType: String?
    let backtestSettings: [String: AnyCodable]?
    let isDefault: Bool?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name
        case strategyType = "strategy_type"
        case backtestSettings = "backtest_settings"
        case isDefault = "is_default"
        case createdAt = "created_at"
    }
}

// MARK: - Reverse Engineering Models

struct ReverseEngineerResponse: Codable, Identifiable {
    let id: String?
    let strategyId: String?
    let conversationId: String?
    let phase: String?
    let response: String?

    enum CodingKeys: String, CodingKey {
        case id
        case strategyId = "strategy_id"
        case conversationId = "conversation_id"
        case phase, response
    }
}

struct ReverseEngineerSchematicResponse: Codable {
    let strategyId: String?
    let phase: String?
    let schematic: StrategySchematic?
    let mermaidDiagram: String?

    enum CodingKeys: String, CodingKey {
        case strategyId = "strategy_id"
        case phase, schematic
        case mermaidDiagram = "mermaid_diagram"
    }
}

struct StrategySchematic: Codable {
    let strategyName: String?
    let strategyType: String?
    let timeframe: String?
    let indicators: [String]?
    let entryLogic: String?
    let exitLogic: String?

    enum CodingKeys: String, CodingKey {
        case strategyName = "strategy_name"
        case strategyType = "strategy_type"
        case timeframe, indicators
        case entryLogic = "entry_logic"
        case exitLogic = "exit_logic"
    }
}

struct ReverseEngineerCodeResponse: Codable {
    let strategyId: String?
    let phase: String?
    let code: String?
    let response: String?

    enum CodingKeys: String, CodingKey {
        case strategyId = "strategy_id"
        case phase, code, response
    }
}

// MARK: - Skills Models

struct Skill: Codable, Identifiable {
    let skillId: String?
    let name: String?
    let slug: String?
    let description: String?
    let category: String?
    let maxTokens: Int?
    let tags: [String]?
    let enabled: Bool?
    let supportsStreaming: Bool?

    var id: String { skillId ?? slug ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case skillId = "skill_id"
        case name, slug, description, category
        case maxTokens = "max_tokens"
        case tags, enabled
        case supportsStreaming = "supports_streaming"
    }
}

struct SkillsListResponse: Codable {
    let skills: [Skill]
    let total: Int?
    let categoryFilter: String?

    enum CodingKeys: String, CodingKey {
        case skills, total
        case categoryFilter = "category_filter"
    }
}

struct SkillCategory: Codable {
    let category: String
    let label: String
    let count: Int
}

struct SkillCategoriesResponse: Codable {
    let categories: [SkillCategory]
}

struct SkillDownloadableFile: Codable {
    let fileId: String?
    let filename: String?
    let fileType: String?
    let sizeKb: Double?
    let downloadUrl: String?

    enum CodingKeys: String, CodingKey {
        case fileId = "file_id"
        case filename
        case fileType = "file_type"
        case sizeKb = "size_kb"
        case downloadUrl = "download_url"
    }
}

struct SkillUsage: Codable {
    let inputTokens: Int?
    let outputTokens: Int?

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

struct SkillExecutionResponse: Codable {
    let text: String?
    let skill: String?
    let skillName: String?
    let usage: SkillUsage?
    let model: String?
    let executionTime: Double?
    let stopReason: String?
    let downloadableFiles: [SkillDownloadableFile]?
    let downloadUrl: String?
    let filename: String?

    enum CodingKeys: String, CodingKey {
        case text, skill, model, filename, usage
        case skillName = "skill_name"
        case executionTime = "execution_time"
        case stopReason = "stop_reason"
        case downloadableFiles = "downloadable_files"
        case downloadUrl = "download_url"
    }
}

struct SkillJobResponse: Codable {
    let jobId: String?
    let status: String?
    let skill: String?
    let skillName: String?

    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case status, skill
        case skillName = "skill_name"
    }
}

struct SkillJobStatusResponse: Codable, Identifiable {
    let jobId: String?
    let skillSlug: String?
    let skillName: String?
    let message: String?
    let status: String?
    let progress: Int?
    let statusMessage: String?
    let result: SkillExecutionResponse?
    let error: String?

    var id: String { jobId ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case skillSlug = "skill_slug"
        case skillName = "skill_name"
        case message, status, progress
        case statusMessage = "status_message"
        case result, error
    }
}

// MARK: - File Models

struct FileInfoResponse: Codable {
    let fileId: String?
    let filename: String?
    let fileType: String?
    let sizeKb: Double?
    let exists: Bool?

    enum CodingKeys: String, CodingKey {
        case fileId = "file_id"
        case filename
        case fileType = "file_type"
        case sizeKb = "size_kb"
        case exists
    }
}

struct GeneratedFileItem: Codable, Identifiable {
    let fileId: String?
    let filename: String?
    let fileType: String?
    let sizeKb: Double?
    let toolName: String?
    let downloadUrl: String?

    var id: String { fileId ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case fileId = "file_id"
        case filename
        case fileType = "file_type"
        case sizeKb = "size_kb"
        case toolName = "tool_name"
        case downloadUrl = "download_url"
    }
}

struct GeneratedFilesResponse: Codable {
    let files: [GeneratedFileItem]
}

// MARK: - Chat Extended Models

struct ChatMessageResponse: Codable {
    let conversationId: String?
    let response: String?
    let parts: [MessagePart]?
    let toolsUsed: [ToolUsage]?
    let allArtifacts: [Artifact]?

    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case response, parts
        case toolsUsed = "tools_used"
        case allArtifacts = "all_artifacts"
    }
}

struct ChatUploadResponse: Codable {
    let fileId: String?
    let filename: String?
    let templateId: String?
    let templateLayouts: Int?
    let isTemplate: Bool?

    enum CodingKeys: String, CodingKey {
        case fileId = "file_id"
        case filename
        case templateId = "template_id"
        case templateLayouts = "template_layouts"
        case isTemplate = "is_template"
    }
}

// MARK: - Presentation Models

struct PresentationResponse: Codable {
    let downloadUrl: String?
    let slideCount: Int?
    let plan: [String: AnyCodable]?
    let filename: String?

    enum CodingKeys: String, CodingKey {
        case downloadUrl = "download_url"
        case slideCount = "slide_count"
        case plan, filename
    }
}

// MARK: - Auth Extended Models

struct APIKeyStatusResponse: Codable {
    let hasClaudeKey: Bool?
    let hasTavilyKey: Bool?

    enum CodingKeys: String, CodingKey {
        case hasClaudeKey = "has_claude_key"
        case hasTavilyKey = "has_tavily_key"
    }
}

// MARK: - Health Models

struct HealthResponse: Codable {
    let status: String?
    let routersActive: Int?
    let routersFailed: Int?

    enum CodingKeys: String, CodingKey {
        case status
        case routersActive = "routers_active"
        case routersFailed = "routers_failed"
    }
}
