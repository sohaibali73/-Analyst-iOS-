import Foundation
import Observation

// MARK: - Chat View Model

/// Manages chat conversations, message streaming, and tool call processing.
///
/// ## Memory Management
/// - `streamingTask` is always cancelled before starting a new stream and on `deinit`.
/// - `toolArgBuffers` are cleared after every stream lifecycle (success or failure).
///
/// ## Error Recovery
/// - Network errors are surfaced via `error` and `userFacingError` for UI display.
/// - Conversations auto-refresh in the background after each send.
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

    /// User-friendly error message derived from the current `error`.
    var userFacingError: String? {
        guard let error else { return nil }
        if let apiError = error as? APIError {
            return apiError.errorDescription
        }
        if let streamError = error as? StreamError {
            return streamError.message
        }
        if let authError = error as? AuthError {
            return authError.errorDescription
        }
        return error.localizedDescription
    }

    /// Clears the current error state (call from UI dismiss actions).
    func clearError() {
        error = nil
    }

    // MARK: - Cancellation Support

    private var streamingTask: Task<Void, Never>?

    /// Stops any ongoing streaming operation and cleans up resources.
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
        cleanupStreamingBuffers()
    }

    // MARK: - Dependencies

    private let apiClient: APIClient
    private let sseClient: SSEClient
    private let hapticManager: HapticManager
    private let cacheManager: CacheManager
    private let networkMonitor: NetworkMonitor

    /// Accumulates streamed argument JSON deltas per tool call ID.
    private var toolArgBuffers: [String: String] = [:]

    /// Tracks whether any content was received during the current stream.
    /// Used to decide whether to remove the placeholder assistant message on error.
    private var hasReceivedContent: Bool = false

    /// Rate limiter — prevents sending messages too quickly.
    private var lastMessageSentAt: Date?
    private let minimumMessageInterval: TimeInterval = 1.0

    // MARK: - Init

    init(
        apiClient: APIClient = .shared,
        sseClient: SSEClient = .shared,
        hapticManager: HapticManager = .shared,
        cacheManager: CacheManager = .shared,
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.apiClient = apiClient
        self.sseClient = sseClient
        self.hapticManager = hapticManager
        self.cacheManager = cacheManager
        self.networkMonitor = networkMonitor
    }

    deinit {
        streamingTask?.cancel()
        streamingTask = nil
    }

    // MARK: - Conversations

    /// Loads all conversations from the server, with cache fallback.
    @MainActor
    func loadConversations() async {
        guard !isLoadingConversations else { return }
        isLoadingConversations = true
        defer { isLoadingConversations = false }

        do {
            let loaded = try await apiClient.getConversations()
            conversations = loaded
            // Cache for offline access
            await cacheManager.set(loaded, forKey: CacheKey.conversations.key, ttl: CacheTTL.medium)
        } catch {
            // Attempt cache fallback
            if let cached: [Conversation] = await cacheManager.get(CacheKey.conversations.key) {
                conversations = cached
            }
            self.error = error
            print("❌ Load conversations error: \(error.localizedDescription)")
        }
    }

    /// Loads existing conversations or creates a new one if none exist.
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

    /// Selects a conversation and loads its messages.
    @MainActor
    func selectConversation(_ conversation: Conversation) async {
        // Cancel any ongoing streaming before switching
        stopStreaming()

        currentConversation = conversation
        messages = []
        await loadMessages()
    }

    /// Creates a new empty conversation.
    @MainActor
    func createNewConversation() async {
        // Cancel any ongoing streaming before creating new conversation
        stopStreaming()

        do {
            let conversation = try await apiClient.createConversation(title: nil)
            currentConversation = conversation
            messages = []
            conversations.insert(conversation, at: 0)
        } catch {
            self.error = error
            print("❌ Create conversation error: \(error.localizedDescription)")
        }
    }

    /// Deletes a conversation and selects the next available one.
    @MainActor
    func deleteConversation(_ conversation: Conversation) async {
        do {
            try await apiClient.deleteConversation(id: conversation.id)
            conversations.removeAll { $0.id == conversation.id }

            if currentConversation?.id == conversation.id {
                stopStreaming()
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

    /// Renames a conversation.
    @MainActor
    func renameConversation(_ conversation: Conversation, title: String) async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        do {
            let updated = try await apiClient.renameConversation(id: conversation.id, title: trimmedTitle)
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

    /// Loads messages for the current conversation.
    @MainActor
    func loadMessages() async {
        guard let conversationId = currentConversation?.id else { return }
        guard !isLoadingHistory else { return }

        isLoadingHistory = true
        defer { isLoadingHistory = false }

        do {
            var loaded = try await apiClient.getMessages(conversationId: conversationId)

            // Parse metadata.parts into toolCalls for historical messages
            for i in loaded.indices where loaded[i].role == .assistant {
                loaded[i].toolCalls = extractToolCalls(from: loaded[i])
            }

            messages = loaded
        } catch {
            self.error = error
            print("❌ Load messages error: \(error.localizedDescription)")
        }
    }

    /// Extracts tool calls from message metadata for historical messages.
    private func extractToolCalls(from message: Message) -> [ToolCall]? {
        guard let toolsUsed = message.metadata?.toolsUsed, !toolsUsed.isEmpty else {
            return nil
        }

        var tools: [ToolCall] = []
        for (index, usage) in toolsUsed.enumerated() {
            let toolId = "history-\(message.id)-\(index)"
            let args = usage.input ?? [:]

            var resultValue: AnyCodable?
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

    /// Sends a message and streams the assistant response.
    ///
    /// - Parameter text: The user's message text.
    ///
    /// ## Rate Limiting
    /// Messages cannot be sent faster than once per second to prevent abuse.
    ///
    /// ## Network Check
    /// Returns early with an error if offline.
    @MainActor
    func sendMessage(_ text: String) async {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        guard let conversationId = currentConversation?.id else {
            self.error = StreamError(message: "No active conversation. Please create one first.", code: nil)
            return
        }

        // Rate limiting check
        if let lastSent = lastMessageSentAt,
           Date().timeIntervalSince(lastSent) < minimumMessageInterval {
            return
        }

        // Network connectivity check
        guard networkMonitor.isConnected else {
            self.error = StreamError(message: "No internet connection. Please check your network and try again.", code: nil)
            hapticManager.error()
            return
        }

        // Cancel any previous streaming task to prevent leaks
        streamingTask?.cancel()
        streamingTask = nil

        lastMessageSentAt = Date()

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
        error = nil
        hasReceivedContent = false
        hapticManager.lightImpact()

        let assistantId = UUID().uuidString

        // Wrap in a cancellable Task so stopStreaming() can cancel it.
        // Task {} inherits @MainActor from the enclosing function,
        // so handleStreamEvent runs on MainActor without actor-crossing issues.
        streamingTask = Task {
            do {
                let stream = await sseClient.streamMessage(
                    conversationId: conversationId,
                    message: trimmedText
                )

                for try await event in stream {
                    guard !Task.isCancelled else { break }

                    handleStreamEvent(
                        event,
                        assistantId: assistantId,
                        conversationId: conversationId
                    )
                }

                guard !Task.isCancelled else { return }

                // Finalize message state
                if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[idx].isStreaming = false
                }
                isStreaming = false
                streamingText = ""
                cleanupStreamingBuffers()
                hapticManager.success()

            } catch {
                guard !Task.isCancelled else { return }

                self.error = error

                if !hasReceivedContent {
                    messages.removeAll { $0.id == assistantId }
                }

                isStreaming = false
                streamingText = ""
                cleanupStreamingBuffers()
                hapticManager.error()
            }

            // Refresh sidebar in the background after a short delay
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await loadConversations()
        }
    }

    // MARK: - Stream Event Handler

    /// Processes a single stream event, updating the message list accordingly.
    /// Runs on MainActor (same as the caller) — no `inout` across actor boundaries.
    @MainActor
    private func handleStreamEvent(
        _ event: StreamEvent,
        assistantId: String,
        conversationId: String
    ) {
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
            hasReceivedContent = true
            toolArgBuffers[start.toolCallId] = ""

            ensureAssistantMessage(id: assistantId, conversationId: conversationId)

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
            if let idx = messages.firstIndex(where: { $0.id == assistantId }),
               let tIdx = messages[idx].toolCalls?.firstIndex(where: { $0.id == complete.toolCallId }) {
                var msg = messages[idx]
                let parsedArgs = parseToolArguments(for: complete.toolCallId)
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

        case .finished:
            break // Handled after the loop

        case .error(let errorMessage):
            self.error = StreamError(message: errorMessage, code: nil)

        case .data:
            break // Data events are informational

        default:
            break
        }
    }

    // MARK: - Send Message With Attachments

    /// Sends a message with file attachments. Files are uploaded first, then the message is sent.
    @MainActor
    func sendMessageWithAttachments(_ text: String, attachments: [AttachmentItem]) async {
        guard currentConversation?.id != nil else {
            self.error = StreamError(message: "No active conversation for upload.", code: nil)
            return
        }

        // Upload each attachment to the knowledge base first
        var uploadedNames: [String] = []
        for attachment in attachments {
            do {
                _ = try await apiClient.uploadDocument(
                    data: attachment.data,
                    filename: attachment.name,
                    category: "chat_upload"
                )
                uploadedNames.append(attachment.name)
            } catch {
                print("❌ Upload failed for \(attachment.name): \(error.localizedDescription)")
                // Continue with remaining uploads
            }
        }

        // Build enhanced message mentioning the files
        let fileNames = uploadedNames.joined(separator: ", ")
        let enhancedText: String
        if uploadedNames.isEmpty {
            enhancedText = text
        } else {
            enhancedText = "\(text)\n\n[Attached files: \(fileNames)]"
        }

        await sendMessage(enhancedText)
    }

    // MARK: - Private Helpers

    /// Ensures an assistant placeholder message exists for streaming.
    private func ensureAssistantMessage(id: String, conversationId: String) {
        if messages.firstIndex(where: { $0.id == id }) == nil {
            messages.append(Message(
                id: id,
                conversationId: conversationId,
                role: .assistant,
                content: "",
                isStreaming: true
            ))
        }
    }

    /// Parses accumulated tool argument JSON for a given tool call ID.
    private func parseToolArguments(for toolCallId: String) -> [String: AnyCodable] {
        guard let argsString = toolArgBuffers[toolCallId],
              let argsData = argsString.data(using: .utf8),
              let argsDict = try? JSONSerialization.jsonObject(with: argsData) as? [String: Any] else {
            return [:]
        }
        return argsDict.mapValues { AnyCodable($0) }
    }

    /// Cleans up all streaming-related buffers to prevent memory leaks.
    private func cleanupStreamingBuffers() {
        toolArgBuffers.removeAll()
    }
}
