import Foundation

// MARK: - SSE Streaming Client

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
    
    func streamMessage(
        conversationId: String?,
        message: String
    ) -> AsyncThrowingStream<StreamEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = baseURL.appendingPathComponent(APIEndpoints.Chat.stream)
                    print("🌐 SSEClient: Connecting to \(url.absoluteString)")
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    // Get token from APIClient as single source of truth
                    if let token = await APIClient.shared.getToken() {
                        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                        print("🔑 SSEClient: Added auth token")
                    } else {
                        print("⚠️ SSEClient: No auth token found")
                    }
                    
                    // Use snake_case for API (conversation_id not conversationId)
                    var body: [String: Any] = ["content": message]
                    if let conversationId = conversationId {
                        body["conversation_id"] = conversationId
                    }
                    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                    
                    print("📤 SSEClient: Request body: \(body)")
                    
                    let (bytes, response) = try await session.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        print("❌ SSEClient: Invalid response type")
                        throw APIError.invalidResponse
                    }
                    
                    print("📡 SSEClient: Response status: \(httpResponse.statusCode)")
                    
                    guard httpResponse.statusCode == 200 else {
                        print("❌ SSEClient: HTTP error \(httpResponse.statusCode)")
                        throw APIError.serverError
                    }
                    
                    var buffer = ""
                    var eventCount = 0
                    
                    // Read byte by byte and parse lines
                    for try await byte in bytes {
                        guard let character = String(bytes: [byte], encoding: .utf8) else { continue }
                        buffer += character
                        
                        // Check for complete lines (Vercel AI SDK format: each line is {type_code}:{JSON}\n)
                        while let newlineIndex = buffer.range(of: "\n")?.lowerBound {
                            let line = String(buffer[..<newlineIndex])
                            buffer = String(buffer[buffer.index(after: newlineIndex)...])
                            
                            if let event = parseStreamLine(line) {
                                eventCount += 1
                                print("📨 SSEClient: Event #\(eventCount): \(type(of: event))")
                                continuation.yield(event)
                                
                                if case .finished = event {
                                    print("✅ SSEClient: Stream finished after \(eventCount) events")
                                    continuation.finish()
                                    return
                                }
                            }
                        }
                    }
                    
                    print("📡 SSEClient: Stream ended naturally after \(eventCount) events")
                    continuation.finish()
                } catch {
                    print("❌ SSEClient: Stream error: \(error)")
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
            // No colon - might be malformed, skip
            print("⚠️ SSEClient: Malformed line (no colon): \(trimmed.prefix(50))")
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
            // Text delta - the JSON is the actual text string
            if let text = try? decoder.decode(String.self, from: jsonData) {
                return .textDelta(text)
            }
            // Fallback: try raw JSON string
            return .textDelta(jsonPart)
            
        case "2":
            // Data – pass the raw JSON string (Sendable-safe)
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
            print("⚠️ SSEClient: Failed to decode toolCallStart from: \(jsonPart)")
            
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
            print("⚠️ SSEClient: Failed to decode toolCallComplete from: \(jsonPart.prefix(100))")
            
        case "a":
            // Tool result
            if let toolResult = try? decoder.decode(ToolResultData.self, from: jsonData) {
                return .toolResult(toolResult)
            }
            print("⚠️ SSEClient: Failed to decode toolResult from: \(jsonPart.prefix(100))")
            
        case "d":
            // Finish message
            if let finish = try? decoder.decode(FinishData.self, from: jsonData) {
                return .finished(finish)
            }
            // Fallback with default values
            return .finished(FinishData(finishReason: "stop", usage: nil, isContinued: false))
            
        case "e":
            // Finish step - can be ignored or treated as finish
            return nil
            
        case "f":
            // Start step - can be ignored
            return nil
            
        default:
            print("⚠️ SSEClient: Unknown type code '\(typeCode)': \(jsonPart.prefix(50))")
            break
        }
        
        return nil
    }
}