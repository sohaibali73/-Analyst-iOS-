import Foundation
import SwiftUI

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

struct Message: Identifiable, Codable, Hashable {
    let id: String
    let conversationId: String
    let role: MessageRole
    var content: String
    let createdAt: Date
    var metadata: MessageMetadata?
    /// Not persisted — only used during streaming
    var isStreaming: Bool = false
    /// Live tool calls populated during streaming or extracted from metadata
    var toolCalls: [ToolCall]?

    // Only encode/decode API fields — exclude isStreaming & toolCalls
    enum CodingKeys: String, CodingKey {
        case id, conversationId, role, content, createdAt, metadata
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        conversationId = try c.decode(String.self, forKey: .conversationId)
        role = try c.decode(MessageRole.self, forKey: .role)
        content = try c.decodeIfPresent(String.self, forKey: .content) ?? ""
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        metadata = try c.decodeIfPresent(MessageMetadata.self, forKey: .metadata)
        isStreaming = false
        toolCalls = nil
    }

    init(
        id: String = UUID().uuidString,
        conversationId: String,
        role: MessageRole,
        content: String,
        createdAt: Date = Date(),
        metadata: MessageMetadata? = nil,
        isStreaming: Bool = false,
        toolCalls: [ToolCall]? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.metadata = metadata
        self.isStreaming = isStreaming
        self.toolCalls = toolCalls
    }
}

// MARK: - Message Metadata

struct MessageMetadata: Codable, Hashable {
    let parts: [MessagePart]?
    let artifacts: [Artifact]?
    let hasArtifacts: Bool?
    let toolsUsed: [ToolUsage]?
}

// MARK: - Message Part

struct MessagePart: Codable, Hashable {
    let type: String
    let text: String?
    let state: String?
    let input: [String: AnyCodable]?
    let output: AnyCodable?
    let errorText: String?
    let toolName: String?
}

// MARK: - Artifact

struct Artifact: Codable, Hashable, Identifiable {
    let id: String
    let type: String // "code", "react", "mermaid"
    let language: String?
    let code: String
    let start: Int?
    let end: Int?
}

// MARK: - Tool Usage

struct ToolUsage: Codable, Hashable {
    let tool: String
    let input: [String: AnyCodable]?
    let result: [String: AnyCodable]?
}

// MARK: - Tool Call

struct ToolCall: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let arguments: [String: AnyCodable]
    let result: AnyCodable?
    
    /// Unwrapped arguments as plain [String: Any] for easy access in generative UI views
    var argumentsDict: [String: Any] {
        arguments.mapValues { $0.value }
    }
    
    /// Unwrapped result as plain [String: Any] dictionary (returns empty dict if not a dictionary)
    var resultDict: [String: Any] {
        result?.value as? [String: Any] ?? [:]
    }

    /// Safe numeric extraction from a dict value that may be Int or Double
    static func num(_ key: String, from dict: [String: Any]) -> Double? {
        if let d = dict[key] as? Double { return d }
        if let i = dict[key] as? Int { return Double(i) }
        return nil
    }

    /// Safe integer extraction from a dict value
    static func int(_ key: String, from dict: [String: Any]) -> Int? {
        if let i = dict[key] as? Int { return i }
        if let d = dict[key] as? Double { return Int(d) }
        return nil
    }
    
    var displayTitle: String {
        switch name {
        case "stock_analysis", "get_stock_data":
            return "Stock Analysis"
        case "generate_afl_code":
            return "AFL Strategy Generated"
        case "web_search":
            return "Web Search"
        case "search_knowledge_base":
            return "Knowledge Base Search"
        case "technical_analysis":
            return "Technical Analysis"
        case "create_chart":
            return "Chart Created"
        default:
            return name.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    var iconName: String {
        switch name {
        case "stock_analysis", "get_stock_data": return "chart.line.uptrend.xyaxis"
        case "generate_afl_code": return "chevron.left.forwardslash.chevron.right"
        case "web_search": return "globe"
        case "search_knowledge_base": return "doc.text.magnifyingglass"
        case "technical_analysis": return "waveform"
        case "create_chart": return "chart.bar.fill"
        default: return "wrench.and.screwdriver"
        }
    }
    
    var iconColor: Color {
        switch name {
        case "stock_analysis", "get_stock_data": return .chartGreen
        case "generate_afl_code": return .chartBlue
        case "web_search": return .chartPurple
        case "search_knowledge_base": return .chartOrange
        case "technical_analysis": return .potomacTurquoise
        default: return .gray
        }
    }
}

// MARK: - Source

struct Source: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let url: String?
    let snippet: String?
    let type: SourceType
    
    enum SourceType: String, Codable {
        case document
        case web
        case code
    }
}

// MARK: - AnyCodable Helper

struct AnyCodable: Codable {
    let value: Any
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dict = value as? [String: Any] {
            try container.encode(dict.mapValues { AnyCodable($0) })
        }
    }
    
    init(_ value: Any) {
        self.value = value
    }
}

// MARK: - AnyCodable Hashable Conformance

extension AnyCodable: Hashable {
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // Compare based on string representation
        return String(describing: lhs.value) == String(describing: rhs.value)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(String(describing: value))
    }
}