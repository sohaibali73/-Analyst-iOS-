//
//  ChatViewModelTests.swift
//  AnalystTests
//
//  Phase 8: Unit tests for ChatViewModel
//

import XCTest
@testable import Analyst

final class ChatViewModelTests: XCTestCase {
    
    var sut: ChatViewModel!
    
    override func setUp() {
        super.setUp()
        // Use the default initializer which uses real singletons.
        // Tests below only verify local / synchronous behaviour
        // that does NOT require network calls.
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
    
    // MARK: - Send Message Validation
    
    func testSendMessage_emptyText_doesNothing() async {
        // When — send whitespace-only text
        await sut.sendMessage("   ")
        
        // Then — no messages should be added
        XCTAssertTrue(sut.messages.isEmpty)
    }
    
    func testSendMessage_noConversation_doesNothing() async {
        // Given — no currentConversation is set
        XCTAssertNil(sut.currentConversation)
        
        // When
        await sut.sendMessage("Hello")
        
        // Then — message is not added when there's no conversation
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
    
    func testMessageRole_encoding() throws {
        XCTAssertEqual(MessageRole.user.rawValue, "user")
        XCTAssertEqual(MessageRole.assistant.rawValue, "assistant")
        XCTAssertEqual(MessageRole.system.rawValue, "system")
    }
    
    // MARK: - Conversation Model Tests
    
    func testConversation_displayTitle_emptyTitle() {
        let conversation = Conversation(
            id: "1",
            userId: nil,
            title: "",
            conversationType: nil,
            createdAt: Date()
        )
        XCTAssertEqual(conversation.displayTitle, "New Conversation")
    }
    
    func testConversation_displayTitle_withTitle() {
        let conversation = Conversation(
            id: "1",
            userId: nil,
            title: "My Chat",
            conversationType: nil,
            createdAt: Date()
        )
        XCTAssertEqual(conversation.displayTitle, "My Chat")
    }
    
    // MARK: - ToolCall Model Tests
    
    func testToolCall_displayTitle() {
        let toolCall = ToolCall(
            id: "tc-1",
            name: "stock_analysis",
            arguments: [:],
            result: nil
        )
        XCTAssertEqual(toolCall.displayTitle, "Stock Analysis")
        XCTAssertEqual(toolCall.iconName, "chart.line.uptrend.xyaxis")
    }
    
    func testToolCall_displayTitle_unknown() {
        let toolCall = ToolCall(
            id: "tc-2",
            name: "custom_tool",
            arguments: [:],
            result: nil
        )
        XCTAssertEqual(toolCall.displayTitle, "Custom Tool")
        XCTAssertEqual(toolCall.iconName, "wrench.and.screwdriver")
    }
    
    func testToolCall_numericExtraction() {
        let dict: [String: Any] = ["price": 42.5, "count": 10]
        XCTAssertEqual(ToolCall.num("price", from: dict), 42.5)
        XCTAssertEqual(ToolCall.int("count", from: dict), 10)
        XCTAssertNil(ToolCall.num("missing", from: dict))
    }
}
