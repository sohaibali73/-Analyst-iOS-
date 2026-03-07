import Foundation
import Observation

@Observable
final class ChatViewModel {
    // MARK: - State
    var messages: [Message] = []
    var conversations: [Conversation] = []
    var currentConversation: Conversation?
    var isStreaming = false
    var isLoadingHistory = false
    var isLoadingConversations = false
    var error: Error?
    var streamingText = ""
    
    // MARK: - Cancellation Support
    private var streamingTask: Task<Void, Never>?
    
    /// Stops any ongoing streaming operation
    func stopStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        
        // Finalize any in-progress streaming message
        if let lastMessage = messages.last, lastMessage.isStreaming {
            if let idx = messages.firstIndex(where: { $0.id == lastMessage.id }) {
                messages[idx].isStreaming = false
            }
        }
        
        isStreaming = false
        streamingText = ""
        toolArgBuffers.removeAll()
    }

    // MARK: - Dependencies
    private let apiClient: APIClient
    private let sseClient: SSEClient
    private let hapticManager: HapticManager

    /// Accumulates streamed argument JSON deltas per tool call ID
    private var toolArgBuffers: [String: String] = [:]

    // MARK: - Init
    init(
        apiClient: APIClient = .shared,
        sseClient: SSEClient = .shared,
        hapticManager: HapticManager = .shared
    ) {
        self.apiClient = apiClient
        self.sseClient = sseClient
        self.hapticManager = hapticManager
    }

    // MARK: - Conversations

    @MainActor
    func loadConversations() async {
        guard !isLoadingConversations else { return }
        isLoadingConversations = true

        do {
            conversations = try await apiClient.getConversations()
        } catch {
            self.error = error
            print("❌ Load conversations error: \(error)")
        }

        isLoadingConversations = false
    }

    @MainActor
    func loadOrCreateConversation() async {
        if conversations.isEmpty {
            await loadConversations()
        }

        if let conversation = conversations.first {
            await selectConversation(conversation)
        } else {
            await createNewConversation()
        }
    }

    @MainActor
    func selectConversation(_ conversation: Conversation) async {
        currentConversation = conversation
        messages = []
        await loadMessages()
    }

    @MainActor
    func createNewConversation() async {
        do {
            let conversation = try await apiClient.createConversation(title: nil)
            currentConversation = conversation
            messages = []
            conversations.insert(conversation, at: 0)
            print("✅ Created new conversation: \(conversation.id)")
        } catch {
            self.error = error
            print("❌ Create conversation error: \(error)")
        }
    }

    @MainActor
    func deleteConversation(_ conversation: Conversation) async {
        do {
            try await apiClient.deleteConversation(id: conversation.id)
            conversations.removeAll { $0.id == conversation.id }

            if currentConversation?.id == conversation.id {
                if let next = conversations.first {
                    await selectConversation(next)
                } else {
                    await createNewConversation()
                }
            }
        } catch {
            self.error = error
        }
    }

    @MainActor
    func renameConversation(_ conversation: Conversation, title: String) async {
        do {
            let updated = try await apiClient.renameConversation(id: conversation.id, title: title)
            if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                conversations[index] = updated
            }
            if currentConversation?.id == conversation.id {
                currentConversation = updated
            }
        } catch {
            self.error = error
        }
    }

    // MARK: - Messages

    @MainActor
    func loadMessages() async {
        guard let conversationId = currentConversation?.id else { return }
        guard !isLoadingHistory else { return }

        isLoadingHistory = true

        do {
            var loaded = try await apiClient.getMessages(conversationId: conversationId)

            // Parse metadata.parts into toolCalls for historical messages
            for i in loaded.indices where loaded[i].role == .assistant {
                loaded[i].toolCalls = extractToolCalls(from: loaded[i])
            }

            messages = loaded
            print("✅ Loaded \(messages.count) messages")
        } catch {
            self.error = error
            print("❌ Load messages error: \(error)")
        }

        isLoadingHistory = false
    }

    /// Extract tool calls from message metadata for historical messages
    private func extractToolCalls(from message: Message) -> [ToolCall]? {
        guard let toolsUsed = message.metadata?.toolsUsed, !toolsUsed.isEmpty else {
            return nil
        }

        var tools: [ToolCall] = []
        for (index, usage) in toolsUsed.enumerated() {
            let toolId = "history-\(message.id)-\(index)"

            // Parse arguments from input
            let args = usage.input ?? [:]

            // Parse result — unwrap the AnyCodable values into a plain dict
            var resultValue: AnyCodable? = nil
            if let resultDict = usage.result {
                let unwrapped = resultDict.mapValues { $0.value }
                resultValue = AnyCodable(unwrapped)
            }

            tools.append(ToolCall(
                id: toolId,
                name: usage.tool,
                arguments: args,
                result: resultValue
            ))
        }

        return tools.isEmpty ? nil : tools
    }

    // MARK: - Send Message

    @MainActor
    func sendMessage(_ text: String) async {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        guard let conversationId = currentConversation?.id else {
            print("❌ No current conversation")
            return
        }

        print("📤 Sending message to conversation: \(conversationId)")

        // Add user message immediately
        let userMessage = Message(
            conversationId: conversationId,
            role: .user,
            content: trimmedText
        )
        messages.append(userMessage)

        // Start streaming
        isStreaming = true
        streamingText = ""
        hapticManager.lightImpact()

        let assistantId = UUID().uuidString
        var hasReceivedContent = false

        do {
            let stream = await sseClient.streamMessage(
                conversationId: conversationId,
                message: trimmedText
            )

            for try await event in stream {
                switch event {
                case .textDelta(let delta):
                    hasReceivedContent = true
                    streamingText += delta

                    if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                        messages[idx].content = streamingText
                    } else {
                        messages.append(Message(
                            id: assistantId,
                            conversationId: conversationId,
                            role: .assistant,
                            content: streamingText,
                            isStreaming: true
                        ))
                    }

                case .toolCallStart(let start):
                    print("🔧 Tool call start: \(start.toolName)")
                    hasReceivedContent = true
                    toolArgBuffers[start.toolCallId] = ""

                    if messages.firstIndex(where: { $0.id == assistantId }) == nil {
                        messages.append(Message(
                            id: assistantId,
                            conversationId: conversationId,
                            role: .assistant,
                            content: "",
                            isStreaming: true
                        ))
                    }

                    if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                        var msg = messages[idx]
                        let toolCall = ToolCall(
                            id: start.toolCallId,
                            name: start.toolName,
                            arguments: [:],
                            result: nil
                        )
                        if msg.toolCalls == nil { msg.toolCalls = [] }
                        msg.toolCalls?.append(toolCall)
                        messages[idx] = msg
                    }

                case .toolCallDelta(let delta):
                    toolArgBuffers[delta.toolCallId, default: ""] += delta.argsTextDelta

                case .toolCallComplete(let complete):
                    print("🔧 Tool call complete: \(complete.toolName)")
                    if let idx = messages.firstIndex(where: { $0.id == assistantId }),
                       let tIdx = messages[idx].toolCalls?.firstIndex(where: { $0.id == complete.toolCallId }) {
                        var msg = messages[idx]
                        var parsedArgs: [String: AnyCodable] = [:]
                        if let argsString = toolArgBuffers[complete.toolCallId],
                           let argsData = argsString.data(using: .utf8),
                           let argsDict = try? JSONSerialization.jsonObject(with: argsData) as? [String: Any] {
                            parsedArgs = argsDict.mapValues { AnyCodable($0) }
                        }
                        msg.toolCalls![tIdx] = ToolCall(
                            id: complete.toolCallId,
                            name: msg.toolCalls![tIdx].name,
                            arguments: parsedArgs,
                            result: msg.toolCalls![tIdx].result
                        )
                        messages[idx] = msg
                    }
                    toolArgBuffers.removeValue(forKey: complete.toolCallId)

                case .toolResult(let result):
                    print("🔧 Tool result received for: \(result.toolCallId)")
                    if let idx = messages.firstIndex(where: { $0.id == assistantId }),
                       let tIdx = messages[idx].toolCalls?.firstIndex(where: { $0.id == result.toolCallId }) {
                        var msg = messages[idx]

                        var parsedResult: Any = result.result
                        if let jsonData = result.result.data(using: .utf8),
                           let jsonObj = try? JSONSerialization.jsonObject(with: jsonData) {
                            parsedResult = jsonObj
                        }

                        msg.toolCalls![tIdx] = ToolCall(
                            id: result.toolCallId,
                            name: msg.toolCalls![tIdx].name,
                            arguments: msg.toolCalls![tIdx].arguments,
                            result: AnyCodable(parsedResult)
                        )
                        messages[idx] = msg
                    }

                case .finished(let finishData):
                    print("🏁 Stream finished: \(finishData.finishReason)")

                case .error(let errorMessage):
                    print("❌ Stream error: \(errorMessage)")
                    self.error = StreamError(message: errorMessage, code: nil)

                case .data(let dataString):
                    print("📊 Data event: \(dataString.prefix(100))")

                default:
                    break
                }
            }

            // Finalize — commit final message state before toggling isStreaming
            if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                messages[idx].isStreaming = false
            }

            isStreaming = false
            streamingText = ""
            toolArgBuffers.removeAll()
            hapticManager.success()
            print("✅ Stream completed")

        } catch {
            print("❌ Stream error: \(error)")
            self.error = error

            if !hasReceivedContent {
                messages.removeAll { $0.id == assistantId }
            }

            isStreaming = false
            streamingText = ""
            toolArgBuffers.removeAll()
            hapticManager.error()
        }

        // Refresh sidebar in the background after a short delay
        Task.detached(priority: .background) { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            await self?.loadConversations()
        }
    }

    // MARK: - Send Message With Attachments

    @MainActor
    func sendMessageWithAttachments(_ text: String, attachments: [AttachmentItem]) async {
        guard (currentConversation?.id) != nil else {
            print("❌ No current conversation for upload")
            return
        }

        // Upload each attachment to the knowledge base first
        for attachment in attachments {
            do {
                let _ = try await apiClient.uploadDocument(
                    data: attachment.data,
                    filename: attachment.name,
                    category: "chat_upload"
                )
                print("✅ Uploaded attachment: \(attachment.name)")
            } catch {
                print("❌ Upload failed for \(attachment.name): \(error)")
            }
        }

        // Build enhanced message mentioning the files
        let fileNames = attachments.map { $0.name }.joined(separator: ", ")
        let enhancedText = "\(text)\n\n[Attached files: \(fileNames)]"

        await sendMessage(enhancedText)
    }
}
