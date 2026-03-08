import Foundation

// MARK: - SSE Streaming Client

/// Server-Sent Events client for real-time message streaming.
///
/// ## Protocol
/// Implements the Vercel AI SDK Data Stream Protocol where each line
/// is formatted as `{type_code}:{JSON}\n`.
///
/// ## Thread Safety
/// Uses Swift `actor` for safe concurrent access to shared state.
///
/// ## Memory Management
/// The returned `AsyncThrowingStream` uses a detached `Task` that
/// respects cancellation, ensuring no resource leaks when callers cancel.
actor SSEClient {
    static let shared = SSEClient()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    private init(
        baseURL: URL = URL(string: APIEndpoints.baseURL)!
    ) {
        self.baseURL = baseURL

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 300 // 5 minutes for streaming
        configuration.timeoutIntervalForResource = 600
        self.session = URLSession(configuration: configuration)

        self.decoder = JSONDecoder()
    }

    // MARK: - Stream Message

    /// Streams an assistant response for the given conversation and user message.
    ///
    /// - Parameters:
    ///   - conversationId: The conversation to send the message in.
    ///   - message: The user's message text.
    /// - Returns: An `AsyncThrowingStream` of `StreamEvent` values.
    func streamMessage(
        conversationId: String?,
        message: String
    ) -> AsyncThrowingStream<StreamEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = baseURL.appendingPathComponent(APIEndpoints.Chat.stream)
                    debugLog("Connecting to stream endpoint")

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    // Get token from APIClient as single source of truth
                    if let token = await APIClient.shared.getToken() {
                        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    } else {
                        debugLog("Warning: No auth token found for streaming")
                    }

                    // Build request body (snake_case for API)
                    var body: [String: Any] = ["content": message]
                    if let conversationId = conversationId {
                        body["conversation_id"] = conversationId
                    }
                    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await session.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw APIError.invalidResponse
                    }

                    guard httpResponse.statusCode == 200 else {
                        debugLog("HTTP error: \(httpResponse.statusCode)")
                        switch httpResponse.statusCode {
                        case 401:
                            throw APIError.unauthorized
                        case 429:
                            throw APIError.rateLimited
                        case 500...599:
                            throw APIError.serverError
                        default:
                            throw APIError.clientError("Stream request failed with status \(httpResponse.statusCode)")
                        }
                    }

                    var buffer = ""
                    var eventCount = 0

                    // Read byte by byte and parse lines
                    for try await byte in bytes {
                        // Check for cancellation to prevent resource leaks
                        guard !Task.isCancelled else {
                            debugLog("Stream cancelled by caller")
                            continuation.finish()
                            return
                        }

                        guard let character = String(bytes: [byte], encoding: .utf8) else { continue }
                        buffer += character

                        // Parse complete lines (Vercel AI SDK format: {type_code}:{JSON}\n)
                        while let newlineIndex = buffer.range(of: "\n")?.lowerBound {
                            let line = String(buffer[..<newlineIndex])
                            buffer = String(buffer[buffer.index(after: newlineIndex)...])

                            if let event = parseStreamLine(line) {
                                eventCount += 1
                                continuation.yield(event)

                                if case .finished = event {
                                    debugLog("Stream finished after \(eventCount) events")
                                    continuation.finish()
                                    return
                                }
                            }
                        }
                    }

                    debugLog("Stream ended naturally after \(eventCount) events")
                    continuation.finish()
                } catch {
                    debugLog("Stream error: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Parse Stream Line (Vercel AI SDK format: {type_code}:{JSON})

    private func parseStreamLine(_ line: String) -> StreamEvent? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Format: {type_code}:{JSON}
        guard let colonIndex = trimmed.firstIndex(of: ":") else {
            debugLog("Malformed line (no colon): \(trimmed.prefix(50))")
            return nil
        }

        let typeCode = String(trimmed[..<colonIndex])
        let jsonPart = String(trimmed[trimmed.index(after: colonIndex)...])

        return parseTypeCode(typeCode, jsonPart: jsonPart)
    }

    // MARK: - Parse Type Code (Vercel AI SDK Data Stream Protocol)

    private func parseTypeCode(_ typeCode: String, jsonPart: String) -> StreamEvent? {
        guard let jsonData = jsonPart.data(using: .utf8) else { return nil }

        switch typeCode {
        case "0":
            // Text delta — the JSON is the actual text string
            if let text = try? decoder.decode(String.self, from: jsonData) {
                return .textDelta(text)
            }
            return .textDelta(jsonPart)

        case "2":
            // Data — pass the raw JSON string (Sendable-safe)
            return .data(jsonPart)

        case "3":
            // Error
            if let errorMessage = try? decoder.decode(String.self, from: jsonData) {
                return .error(errorMessage)
            }
            return .error(jsonPart)

        case "7":
            // Tool call start
            if let toolStart = try? decoder.decode(ToolCallStartData.self, from: jsonData) {
                return .toolCallStart(toolStart)
            }
            debugLog("Failed to decode toolCallStart")

        case "8":
            // Tool call delta
            if let toolDelta = try? decoder.decode(ToolCallDeltaData.self, from: jsonData) {
                return .toolCallDelta(toolDelta)
            }

        case "9":
            // Tool call complete
            if let toolComplete = try? decoder.decode(ToolCallCompleteData.self, from: jsonData) {
                return .toolCallComplete(toolComplete)
            }
            debugLog("Failed to decode toolCallComplete")

        case "a":
            // Tool result
            if let toolResult = try? decoder.decode(ToolResultData.self, from: jsonData) {
                return .toolResult(toolResult)
            }
            debugLog("Failed to decode toolResult")

        case "d":
            // Finish message
            if let finish = try? decoder.decode(FinishData.self, from: jsonData) {
                return .finished(finish)
            }
            return .finished(FinishData(finishReason: "stop", usage: nil, isContinued: false))

        case "e":
            // Finish step — can be ignored
            return nil

        case "f":
            // Start step — can be ignored
            return nil

        default:
            debugLog("Unknown type code '\(typeCode)'")
            break
        }

        return nil
    }

    // MARK: - Debug Logging

    /// Logs messages only in DEBUG builds.
    private func debugLog(_ message: String) {
        #if DEBUG
        print("📡 SSEClient: \(message)")
        #endif
    }
}
