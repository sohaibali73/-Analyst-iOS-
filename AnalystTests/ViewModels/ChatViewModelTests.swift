//
//  ChatViewModelTests.swift
//  AnalystTests
//
//  Comprehensive unit tests for ChatViewModel.
//

import XCTest
@testable import Analyst

final class ChatViewModelTests: XCTestCase {

    var sut: ChatViewModel!

    override func setUp() {
        super.setUp()
        sut = ChatViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertTrue(sut.messages.isEmpty)
        XCTAssertFalse(sut.isStreaming)
        XCTAssertTrue(sut.streamingText.isEmpty)
        XCTAssertNil(sut.currentConversation)
        XCTAssertNil(sut.error)
        XCTAssertNil(sut.userFacingError)
        XCTAssertFalse(sut.isLoadingHistory)
        XCTAssertFalse(sut.isLoadingConversations)
        XCTAssertTrue(sut.conversations.isEmpty)
    }

    // MARK: - Stop Streaming Tests

    func testStopStreaming_cancelsAndResets() {
        // Given
        sut.isStreaming = true
        sut.streamingText = "partial content"

        // When
        sut.stopStreaming()

        // Then
        XCTAssertFalse(sut.isStreaming)
        XCTAssertTrue(sut.streamingText.isEmpty)
    }

    func testStopStreaming_finalizesStreamingMessage() {
        // Given — simulate a streaming assistant message
        let conv = Conversation(
            id: "conv-1", userId: nil, title: "Test",
            conversationType: nil, createdAt: Date()
        )
        sut.messages = [
            Message(id: "msg-1", conversationId: "conv-1", role: .assistant,
                    content: "Partial...", isStreaming: true)
        ]
        sut.isStreaming = true

        // When
        sut.stopStreaming()

        // Then — the message should no longer be streaming
        XCTAssertFalse(sut.messages[0].isStreaming)
        XCTAssertFalse(sut.isStreaming)
    }

    // MARK: - Error Handling Tests

    func testUserFacingError_withAPIError() {
        // Given
        sut.error = APIError.unauthorized

        // Then
        XCTAssertNotNil(sut.userFacingError)
        XCTAssertEqual(sut.userFacingError, "Your session has expired. Please log in again.")
    }

    func testUserFacingError_withStreamError() {
        // Given
        sut.error = StreamError(message: "Connection lost", code: nil)

        // Then
        XCTAssertEqual(sut.userFacingError, "Connection lost")
    }

    func testUserFacingError_withNilError() {
        // Given
        sut.error = nil

        // Then
        XCTAssertNil(sut.userFacingError)
    }

    func testClearError_resetsErrorState() {
        // Given
        sut.error = APIError.serverError

        // When
        sut.clearError()

        // Then
        XCTAssertNil(sut.error)
        XCTAssertNil(sut.userFacingError)
    }

    // MARK: - Send Message Validation

    func testSendMessage_emptyText_doesNothing() async {
        await sut.sendMessage("   ")
        XCTAssertTrue(sut.messages.isEmpty)
    }

    func testSendMessage_noConversation_setsError() async {
        XCTAssertNil(sut.currentConversation)

        await sut.sendMessage("Hello")

        // Should set error instead of silently failing
        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.messages.isEmpty)
    }

    // MARK: - Message Model Tests

    func testMessageInit_defaultValues() {
        let message = Message(
            conversationId: "conv-1",
            role: .user,
            content: "Hello"
        )

        XCTAssertEqual(message.conversationId, "conv-1")
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "Hello")
        XCTAssertFalse(message.isStreaming)
        XCTAssertNil(message.toolCalls)
        XCTAssertNil(message.metadata)
    }

    func testMessageInit_withStreaming() {
        let message = Message(
            conversationId: "conv-1",
            role: .assistant,
            content: "Streaming...",
            isStreaming: true
        )

        XCTAssertTrue(message.isStreaming)
        XCTAssertEqual(message.role, .assistant)
    }

    func testMessageRole_encoding() throws {
        XCTAssertEqual(MessageRole.user.rawValue, "user")
        XCTAssertEqual(MessageRole.assistant.rawValue, "assistant")
        XCTAssertEqual(MessageRole.system.rawValue, "system")
    }

    // MARK: - Conversation Model Tests

    func testConversation_displayTitle_emptyTitle() {
        let conversation = Conversation(
            id: "1", userId: nil, title: "",
            conversationType: nil, createdAt: Date()
        )
        XCTAssertEqual(conversation.displayTitle, "New Conversation")
    }

    func testConversation_displayTitle_withTitle() {
        let conversation = Conversation(
            id: "1", userId: nil, title: "My Chat",
            conversationType: nil, createdAt: Date()
        )
        XCTAssertEqual(conversation.displayTitle, "My Chat")
    }

    func testConversation_formattedDate_today() {
        let conversation = Conversation(
            id: "1", userId: nil, title: "Test",
            conversationType: nil, createdAt: Date()
        )
        // Today's conversation should show time format (not "Yesterday" or date)
        let formatted = conversation.formattedDate
        XCTAssertFalse(formatted.isEmpty)
        XCTAssertNotEqual(formatted, "Yesterday")
    }

    func testConversation_formattedDate_yesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let conversation = Conversation(
            id: "1", userId: nil, title: "Test",
            conversationType: nil, createdAt: yesterday
        )
        XCTAssertEqual(conversation.formattedDate, "Yesterday")
    }

    // MARK: - ToolCall Model Tests

    func testToolCall_displayTitle() {
        let toolCall = ToolCall(id: "tc-1", name: "stock_analysis", arguments: [:], result: nil)
        XCTAssertEqual(toolCall.displayTitle, "Stock Analysis")
        XCTAssertEqual(toolCall.iconName, "chart.line.uptrend.xyaxis")
    }

    func testToolCall_displayTitle_unknown() {
        let toolCall = ToolCall(id: "tc-2", name: "custom_tool", arguments: [:], result: nil)
        XCTAssertEqual(toolCall.displayTitle, "Custom Tool")
        XCTAssertEqual(toolCall.iconName, "wrench.and.screwdriver")
    }

    func testToolCall_displayTitle_allKnownTools() {
        let tools: [(String, String)] = [
            ("stock_analysis", "Stock Analysis"),
            ("get_stock_data", "Stock Analysis"),
            ("generate_afl_code", "AFL Strategy Generated"),
            ("web_search", "Web Search"),
            ("search_knowledge_base", "Knowledge Base Search"),
            ("technical_analysis", "Technical Analysis"),
            ("create_chart", "Chart Created"),
        ]

        for (name, expected) in tools {
            let tc = ToolCall(id: "tc", name: name, arguments: [:], result: nil)
            XCTAssertEqual(tc.displayTitle, expected, "Failed for tool: \(name)")
        }
    }

    func testToolCall_numericExtraction() {
        let dict: [String: Any] = ["price": 42.5, "count": 10]
        XCTAssertEqual(ToolCall.num("price", from: dict), 42.5)
        XCTAssertEqual(ToolCall.int("count", from: dict), 10)
        XCTAssertNil(ToolCall.num("missing", from: dict))
        XCTAssertNil(ToolCall.int("missing", from: dict))
    }

    func testToolCall_numericExtraction_crossTypes() {
        let dict: [String: Any] = ["intVal": 42, "doubleVal": 3.14]
        // int should be extractable as Double
        XCTAssertEqual(ToolCall.num("intVal", from: dict), 42.0)
        // double should be extractable as Int (truncated)
        XCTAssertEqual(ToolCall.int("doubleVal", from: dict), 3)
    }

    func testToolCall_resultDict() {
        let tc = ToolCall(
            id: "tc", name: "test",
            arguments: [:],
            result: AnyCodable(["key": "value"])
        )
        XCTAssertEqual(tc.resultDict["key"] as? String, "value")
    }

    func testToolCall_resultDict_nilResult() {
        let tc = ToolCall(id: "tc", name: "test", arguments: [:], result: nil)
        XCTAssertTrue(tc.resultDict.isEmpty)
    }

    // MARK: - AnyCodable Tests

    func testAnyCodable_stringValue() {
        let codable = AnyCodable("hello")
        XCTAssertEqual(codable.value as? String, "hello")
    }

    func testAnyCodable_intValue() {
        let codable = AnyCodable(42)
        XCTAssertEqual(codable.value as? Int, 42)
    }

    func testAnyCodable_hashable() {
        let a = AnyCodable("test")
        let b = AnyCodable("test")
        XCTAssertEqual(a, b)
    }

    func testAnyCodable_hashable_different() {
        let a = AnyCodable("hello")
        let b = AnyCodable("world")
        XCTAssertNotEqual(a, b)
    }

    // MARK: - StreamEvent Model Tests

    func testStreamError_properties() {
        let err = StreamError(message: "Network timeout", code: "TIMEOUT")
        XCTAssertEqual(err.message, "Network timeout")
        XCTAssertEqual(err.code, "TIMEOUT")
    }

    func testFinishData_properties() {
        let finish = FinishData(finishReason: "stop", usage: nil, isContinued: false)
        XCTAssertEqual(finish.finishReason, "stop")
        XCTAssertNil(finish.usage)
        XCTAssertEqual(finish.isContinued, false)
    }

    func testUsageData_properties() {
        let usage = UsageData(promptTokens: 100, completionTokens: 50)
        XCTAssertEqual(usage.promptTokens, 100)
        XCTAssertEqual(usage.completionTokens, 50)
    }
}
