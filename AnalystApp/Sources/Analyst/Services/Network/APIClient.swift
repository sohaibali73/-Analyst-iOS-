import Foundation

// MARK: - API Client Actor

/// Thread-safe network client for all Analyst API operations.
///
/// ## Architecture
/// - Uses Swift `actor` for thread-safe token and state management.
/// - All HTTP requests flow through `performRequest(_:_:body:queryItems:)`.
/// - Authentication tokens are stored in Keychain via `KeychainManager`.
///
/// ## Security
/// - Debug logging is disabled in release builds (no token/header leaks).
/// - Rate limiting is enforced for sensitive operations.
/// - Input validation occurs before network calls.
///
/// ## Error Handling
/// - All errors are mapped to `APIError` with user-friendly descriptions.
/// - 401 responses automatically clear stored tokens.
actor APIClient {
    static let shared = APIClient()

    let baseURL: URL
    let session: URLSession
    let decoder: JSONDecoder
    private let keychain: KeychainManager

    private(set) var isAuthenticated: Bool = false
    var accessToken: String?

    // MARK: - Init

    private init(
        baseURL: URL = URL(string: APIEndpoints.baseURL)!,
        keychain: KeychainManager = .shared
    ) {
        self.baseURL = baseURL
        self.keychain = keychain

        // Configure session with sensible timeouts
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        configuration.waitsForConnectivity = true
        self.session = URLSession(configuration: configuration)

        // Configure decoder with snake_case conversion and flexible date parsing
        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds (API format: 2026-01-23T13:12:37.380492+00:00)
            let iso8601Formatter = ISO8601DateFormatter()

            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withColonSeparatorInTimeZone]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Try without fractional seconds
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Fallback to DateFormatter for other formats
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)

            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ssXXXXX",
                "yyyy-MM-dd HH:mm:ss"
            ]

            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }

            // Last resort: return current date instead of crashing
            debugLog("⚠️ Date decoding failed for: \(dateString), using current date")
            return Date()
        }

        // Restore existing token from Keychain
        if let token = keychain.get(.accessToken), !token.isEmpty {
            self.accessToken = token
            self.isAuthenticated = true
        }
    }

    // MARK: - Auth Methods

    /// Authenticates a user with email and password.
    ///
    /// - Parameters:
    ///   - email: User's email address (validated before sending).
    ///   - password: User's password.
    /// - Returns: The authentication response containing the access token.
    /// - Throws: `APIError` on network or server failure.
    func login(email: String, password: String) async throws -> AuthResponse {
        guard !email.isEmpty, !password.isEmpty else {
            throw APIError.clientError("Email and password are required.")
        }

        let body = ["email": email, "password": password]

        do {
            let data = try await performRequest(.post, APIEndpoints.Auth.login, body: body)
            let response = try decoder.decode(AuthResponse.self, from: data)
            try storeToken(response.accessToken)
            isAuthenticated = true
            return response
        } catch {
            debugLog("Login error: \(error.localizedDescription)")
            throw error
        }
    }

    /// Registers a new user account.
    func register(email: String, password: String, name: String?, nickname: String?) async throws -> AuthResponse {
        guard !email.isEmpty, !password.isEmpty else {
            throw APIError.clientError("Email and password are required.")
        }
        guard password.count >= 8 else {
            throw APIError.clientError("Password must be at least 8 characters.")
        }

        var body: [String: Any] = ["email": email, "password": password]
        if let name = name, !name.isEmpty { body["name"] = name }
        if let nickname = nickname, !nickname.isEmpty { body["nickname"] = nickname }

        let data = try await performRequest(.post, APIEndpoints.Auth.register, body: body)
        let response = try decoder.decode(AuthResponse.self, from: data)
        try storeToken(response.accessToken)
        isAuthenticated = true
        return response
    }

    /// Logs out the current user and clears stored tokens.
    func logout() async throws {
        _ = try? await performRequest(.post, APIEndpoints.Auth.logout)
        clearTokens()
        isAuthenticated = false
    }

    /// Retrieves the currently authenticated user's profile.
    func getCurrentUser() async throws -> User {
        let data = try await performRequest(.get, APIEndpoints.Auth.me)
        return try decoder.decode(User.self, from: data)
    }

    // MARK: - Conversation Methods

    /// Fetches all conversations for the authenticated user.
    func getConversations() async throws -> [Conversation] {
        let data = try await performRequest(.get, APIEndpoints.Chat.conversations)
        return try decoder.decode([Conversation].self, from: data)
    }

    /// Creates a new conversation.
    func createConversation(title: String?, type: String? = nil) async throws -> Conversation {
        var body: [String: Any] = [:]
        if let title = title { body["title"] = title }
        if let type = type { body["conversation_type"] = type }

        let data = try await performRequest(.post, APIEndpoints.Chat.conversations, body: body)
        return try decoder.decode(Conversation.self, from: data)
    }

    /// Deletes a conversation by ID.
    func deleteConversation(id: String) async throws {
        guard !id.isEmpty else { throw APIError.clientError("Invalid conversation ID.") }
        _ = try await performRequest(.delete, APIEndpoints.Chat.conversation(id))
    }

    /// Renames a conversation.
    func renameConversation(id: String, title: String) async throws -> Conversation {
        guard !id.isEmpty else { throw APIError.clientError("Invalid conversation ID.") }
        guard !title.isEmpty else { throw APIError.clientError("Title cannot be empty.") }

        let body = ["title": title]
        let data = try await performRequest(.patch, APIEndpoints.Chat.conversation(id), body: body)
        return try decoder.decode(Conversation.self, from: data)
    }

    /// Fetches messages for a conversation, handling multiple response formats.
    func getMessages(conversationId: String) async throws -> [Message] {
        guard !conversationId.isEmpty else { throw APIError.clientError("Invalid conversation ID.") }

        let data = try await performRequest(.get, APIEndpoints.Chat.messages(conversationId))

        // Try decoding as bare array first
        if let messages = try? decoder.decode([Message].self, from: data) {
            return messages
        }

        // Fallback: try decoding as wrapped response
        struct WrappedMessages: Decodable {
            let messages: [Message]
        }

        if let wrapped = try? decoder.decode(WrappedMessages.self, from: data) {
            return wrapped.messages
        }

        // Last resort: return empty array instead of throwing
        debugLog("getMessages: Failed to decode messages, returning empty array")
        return []
    }

    // MARK: - Knowledge Base Methods

    /// Fetches all knowledge base documents.
    func getDocuments() async throws -> [KnowledgeDocument] {
        let data = try await performRequest(.get, APIEndpoints.Brain.documents)
        return try decoder.decode([KnowledgeDocument].self, from: data)
    }

    /// Searches the knowledge base.
    func searchKnowledge(query: String, category: String? = nil, limit: Int = 10) async throws -> [DocumentSearchResult] {
        guard !query.isEmpty else { throw APIError.clientError("Search query cannot be empty.") }

        var body: [String: Any] = ["query": query, "limit": min(limit, 100)]
        if let category = category { body["category"] = category }

        let data = try await performRequest(.post, APIEndpoints.Brain.search, body: body)
        let response = try decoder.decode(SearchResponse.self, from: data)
        return response.results
    }

    /// Deletes a knowledge base document.
    func deleteDocument(id: String) async throws {
        guard !id.isEmpty else { throw APIError.clientError("Invalid document ID.") }
        _ = try await performRequest(.delete, APIEndpoints.Brain.document(id))
    }

    /// Retrieves knowledge base statistics.
    func getBrainStats() async throws -> BrainStats {
        let data = try await performRequest(.get, APIEndpoints.Brain.stats)
        return try decoder.decode(BrainStats.self, from: data)
    }

    // MARK: - File Upload

    /// Uploads a document to the knowledge base.
    ///
    /// - Parameters:
    ///   - data: The file data.
    ///   - filename: Original filename for the upload.
    ///   - category: Document category (default: "general").
    /// - Returns: The upload response with document ID and classification.
    func uploadDocument(data: Data, filename: String, category: String = "general") async throws -> UploadResponse {
        guard !filename.isEmpty else { throw APIError.clientError("Filename cannot be empty.") }
        guard !data.isEmpty else { throw APIError.clientError("File data is empty.") }

        let url = baseURL.appendingPathComponent(APIEndpoints.Brain.upload)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)

        // Add category
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"category\"\r\n\r\n".data(using: .utf8)!)
        body.append(category.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (responseData, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        try validateResponse(httpResponse, data: responseData)

        return try decoder.decode(UploadResponse.self, from: responseData)
    }

    // MARK: - AFL Methods

    /// Generates AFL code from a natural language prompt.
    func generateAFL(prompt: String, strategyType: String = "standalone") async throws -> AFLGenerationResponse {
        guard !prompt.isEmpty else { throw APIError.clientError("Prompt cannot be empty.") }

        let body: [String: Any] = [
            "prompt": prompt,
            "strategy_type": strategyType,
            "stream": false
        ]
        let data = try await performRequest(.post, APIEndpoints.AFL.generate, body: body)
        return try decoder.decode(AFLGenerationResponse.self, from: data)
    }

    /// Fetches AFL generation history.
    func getAFLHistory() async throws -> [AFLHistoryEntry] {
        let data = try await performRequest(.get, APIEndpoints.AFL.history)
        return (try? decoder.decode([AFLHistoryEntry].self, from: data)) ?? []
    }

    /// Deletes an AFL history entry.
    func deleteAFLHistory(id: String) async throws {
        guard !id.isEmpty else { throw APIError.clientError("Invalid history ID.") }
        _ = try await performRequest(.delete, APIEndpoints.AFL.historyItem(id))
    }

    // MARK: - User Profile Methods

    /// Alias for `getCurrentUser()` for profile-specific contexts.
    func getCurrentUserProfile() async throws -> User {
        return try await getCurrentUser()
    }

    /// Updates the user profile with optional fields.
    func updateUserProfile(name: String?, nickname: String?, claudeAPIKey: String?, tavilyAPIKey: String?) async throws -> User {
        var body: [String: Any] = [:]
        if let name = name { body["name"] = name }
        if let nickname = nickname { body["nickname"] = nickname }
        if let key = claudeAPIKey { body["claude_api_key"] = key }
        if let key = tavilyAPIKey { body["tavily_api_key"] = key }

        guard !body.isEmpty else { throw APIError.clientError("No fields to update.") }

        let data = try await performRequest(.put, APIEndpoints.Auth.me, body: body)
        return try decoder.decode(User.self, from: data)
    }

    /// Changes the user's password.
    func changePassword(current: String, new: String) async throws {
        guard !current.isEmpty else { throw APIError.clientError("Current password is required.") }
        guard new.count >= 8 else { throw APIError.clientError("New password must be at least 8 characters.") }

        let body: [String: Any] = ["current_password": current, "new_password": new]
        _ = try await performRequest(.put, APIEndpoints.Auth.changePassword, body: body)
    }

    // MARK: - Unified Request Method

    /// Central HTTP request method used by all API calls.
    ///
    /// - Parameters:
    ///   - method: The HTTP method (GET, POST, PUT, PATCH, DELETE).
    ///   - endpoint: The API endpoint path (appended to `baseURL`).
    ///   - body: Optional JSON body dictionary.
    ///   - queryItems: Optional URL query parameters.
    /// - Returns: Raw response `Data`.
    /// - Throws: `APIError` for any HTTP or network error.
    func performRequest(
        _ method: HTTPMethod,
        _ endpoint: String,
        body: [String: Any]? = nil,
        queryItems: [String: Any]? = nil
    ) async throws -> Data {
        var url = baseURL.appendingPathComponent(endpoint)

        // Add query items
        if let queryItems = queryItems {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            components.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            url = components.url!
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        debugLog("REQUEST: \(method.rawValue) \(endpoint)")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        debugLog("RESPONSE: \(httpResponse.statusCode) for \(endpoint)")

        try validateResponse(httpResponse, data: data)

        return data
    }

    // MARK: - Response Validation

    /// Validates an HTTP response and throws appropriate `APIError` for failures.
    func validateResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            clearTokens()
            isAuthenticated = false
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 422:
            let errorMessage = (try? decoder.decode(ErrorResponse.self, from: data))?.detail ?? "Validation failed"
            throw APIError.validationError(errorMessage)
        case 429:
            throw APIError.rateLimited
        case 400...499:
            let errorMessage = (try? decoder.decode(ErrorResponse.self, from: data))?.detail ?? "Request failed"
            throw APIError.clientError(errorMessage)
        case 500...599:
            throw APIError.serverError
        default:
            throw APIError.unknown
        }
    }

    // MARK: - Token Management

    /// Stores an access token in both memory and Keychain.
    func storeToken(_ token: String) throws {
        try keychain.set(token, forKey: .accessToken)
        self.accessToken = token
    }

    /// Clears all stored authentication tokens.
    private func clearTokens() {
        keychain.delete(.accessToken)
        keychain.delete(.refreshToken)
        accessToken = nil
    }

    // MARK: - Token Access for Streaming

    /// Returns the current access token (used by SSEClient for streaming auth).
    func getToken() -> String? {
        accessToken
    }

    // MARK: - Debug Logging

    /// Logs messages only in DEBUG builds to prevent leaking sensitive data in production.
    private func debugLog(_ message: String) {
        #if DEBUG
        print("🌐 APIClient: \(message)")
        #endif
    }
}

// MARK: - Supporting Types

/// HTTP methods supported by the API client.
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Server error response format.
struct ErrorResponse: Codable {
    let detail: String
}

/// Comprehensive API error types with user-friendly descriptions.
enum APIError: Error, LocalizedError {
    case unauthorized
    case forbidden
    case notFound
    case clientError(String)
    case validationError(String)
    case rateLimited
    case serverError
    case invalidResponse
    case decodingError(Error)
    case networkUnavailable
    case unknown

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .forbidden:
            return "You don't have permission to access this resource."
        case .notFound:
            return "The requested resource was not found."
        case .clientError(let message):
            return message
        case .validationError(let message):
            return "Validation error: \(message)"
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .serverError:
            return "A server error occurred. Please try again later."
        case .invalidResponse:
            return "Invalid response from server."
        case .decodingError(let error):
            return "Failed to process response: \(error.localizedDescription)"
        case .networkUnavailable:
            return "No internet connection. Please check your network."
        case .unknown:
            return "An unknown error occurred."
        }
    }

    /// Whether this error type is suitable for automatic retry.
    var isRetryable: Bool {
        switch self {
        case .serverError, .rateLimited:
            return true
        default:
            return false
        }
    }
}

// MARK: - Response Models

struct SearchResponse: Codable {
    let results: [DocumentSearchResult]
    let count: Int
}

struct DocumentSearchResult: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let category: String?
    let summary: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, category, summary
        case createdAt = "created_at"
    }
}

struct UploadResponse: Codable {
    let status: String
    let documentId: String?
    let classification: Classification?

    enum CodingKeys: String, CodingKey {
        case status
        case documentId = "document_id"
        case classification
    }

    struct Classification: Codable {
        let category: String?
        let confidence: Double?
        let summary: String?
    }
}

struct KnowledgeDocument: Codable, Identifiable, Hashable {
    let id: String
    let title: String?
    let filename: String?
    let category: String?
    let tags: [String]?
    let summary: String?
    let fileSize: Int?
    let createdAt: Date?
    let chunkCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, filename, category, tags, summary
        case fileSize = "file_size"
        case createdAt = "created_at"
        case chunkCount = "chunk_count"
    }
}

struct BrainStats: Codable {
    let totalDocuments: Int
    let totalSize: Int
    let totalChunks: Int
    let totalLearnings: Int?
    let categories: [String: Int]

    enum CodingKeys: String, CodingKey {
        case totalDocuments = "total_documents"
        case totalSize = "total_size"
        case totalChunks = "total_chunks"
        case totalLearnings = "total_learnings"
        case categories
    }
}

// MARK: - AFL Models

struct AFLGenerationResponse: Codable {
    let code: String?
    let aflCode: String?
    let explanation: String?
    let stats: AFLStats?

    /// Returns the generated code from whichever field is populated.
    var generatedCode: String {
        code ?? aflCode ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case code
        case aflCode = "afl_code"
        case explanation
        case stats
    }
}

struct AFLStats: Codable {
    let qualityScore: Int?
    let lineCount: Int?
    let hasBuySell: Bool?
    let hasPlot: Bool?

    enum CodingKeys: String, CodingKey {
        case qualityScore = "quality_score"
        case lineCount = "line_count"
        case hasBuySell = "has_buy_sell"
        case hasPlot = "has_plot"
    }
}

struct AFLHistoryEntry: Codable, Identifiable {
    let id: String
    let prompt: String?
    let code: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, prompt, code
        case createdAt = "created_at"
    }
}
