import Foundation

// MARK: - Stream Event Types (Vercel AI SDK Data Stream Protocol)

enum StreamEvent: Sendable {
    case textDelta(String)
    case data(String)          // raw JSON payload as String (avoids non-Sendable [Any])
    case toolCallStart(ToolCallStartData)
    case toolCallDelta(ToolCallDeltaData)
    case toolCallComplete(ToolCallCompleteData)
    case toolResult(ToolResultData)
    case sourceCitation(SourceData)
    case reasoningStep(String)
    case finished(FinishData)
    case error(String)
}

// MARK: - Event Data Structures

struct ToolCallStartData: Codable, Sendable {
    let toolCallId: String
    let toolName: String
    
    enum CodingKeys: String, CodingKey {
        case toolCallId = "toolCallId"
        case toolName
    }
}

struct ToolCallDeltaData: Codable, Sendable {
    let toolCallId: String
    let argsTextDelta: String
    
    enum CodingKeys: String, CodingKey {
        case toolCallId = "toolCallId"
        case argsTextDelta
    }
}

struct ToolCallCompleteData: Codable, Sendable {
    let toolCallId: String
    let toolName: String
    // args omitted — only toolName is needed for UI display

    enum CodingKeys: String, CodingKey {
        case toolCallId
        case toolName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        toolCallId = try c.decode(String.self, forKey: .toolCallId)
        toolName   = try c.decode(String.self, forKey: .toolName)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(toolCallId, forKey: .toolCallId)
        try c.encode(toolName,   forKey: .toolName)
    }
}

struct ToolResultData: Codable, Sendable {
    let toolCallId: String
    let result: String
    
    enum CodingKeys: String, CodingKey {
        case toolCallId = "toolCallId"
        case result
    }
}

struct SourceData: Codable, Sendable, Identifiable {
    var id: String { url ?? title }
    let title: String
    let url: String?
    let snippet: String?
    let type: String?
}

struct FinishData: Codable, Sendable {
    let finishReason: String
    let usage: UsageData?
    let isContinued: Bool?
    
    enum CodingKeys: String, CodingKey {
        case finishReason
        case usage
        case isContinued
    }
}

struct UsageData: Codable, Sendable {
    let promptTokens: Int
    let completionTokens: Int
}

// MARK: - Stream Error

struct StreamError: Error, Sendable {
    let message: String
    let code: String?
}