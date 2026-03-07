import Foundation

// MARK: - API Client Actor

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
        
        // Configure session
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        configuration.waitsForConnectivity = true
        self.session = URLSession(configuration: configuration)
        
        // Configure decoder
        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 with various options
            let iso8601Formatter = ISO8601DateFormatter()
            
            // Try with fractional seconds and colon in timezone (API format: 2026-01-23T13:12:37.380492+00:00)
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
            
            // Last resort: return current date instead of failing
            print("⚠️ Date decoding failed for: \(dateString), using current date")
            return Date()
        }
        
        // Check for existing token
        if let token = keychain.get(.accessToken), !token.isEmpty {
            self.accessToken = token
            self.isAuthenticated = true
        }
    }
    
    // MARK: - Auth Methods
    
    func login(email: String, password: String) async throws -> AuthResponse {
        print("🌐 APIClient.login called for: \(email)")
        let body = ["email": email, "password": password]
        
        do {
            let data = try await request(.post, APIEndpoints.Auth.login, body: body)
            print("🌐 APIClient.login received data: \(data.count) bytes")
            
            let response = try decoder.decode(AuthResponse.self, from: data)
            print("🌐 APIClient.login decoded response, token: \(response.accessToken.prefix(20))...")
            
            try storeToken(response.accessToken)
            isAuthenticated = true
            print("🌐 APIClient.login token stored, isAuthenticated: \(self.isAuthenticated)")
            
            return response
        } catch {
            print("🌐 APIClient.login error: \(error)")
            throw error
        }
    }
    
    func register(email: String, password: String, name: String?, nickname: String?) async throws -> AuthResponse {
        var body: [String: Any] = ["email": email, "password": password]
        if let name = name { body["name"] = name }
        if let nickname = nickname { body["nickname"] = nickname }
        
        let data = try await request(.post, APIEndpoints.Auth.register, body: body)
        
        let response = try decoder.decode(AuthResponse.self, from: data)
        try storeToken(response.accessToken)
        isAuthenticated = true
        
        return response
    }
    
    func logout() async throws {
        _ = try? await request(.post, APIEndpoints.Auth.logout)
        clearTokens()
        isAuthenticated = false
    }
    
    func getCurrentUser() async throws -> User {
        let data = try await request(.get, APIEndpoints.Auth.me)
        return try decoder.decode(User.self, from: data)
    }
    
    // MARK: - Conversation Methods
    
    func getConversations() async throws -> [Conversation] {
        let data = try await request(.get, APIEndpoints.Chat.conversations)
        return try decoder.decode([Conversation].self, from: data)
    }
    
    func createConversation(title: String?, type: String? = nil) async throws -> Conversation {
        var body: [String: Any] = [:]
        if let title = title { body["title"] = title }
        if let type = type { body["conversation_type"] = type }
        
        let data = try await request(.post, APIEndpoints.Chat.conversations, body: body)
        return try decoder.decode(Conversation.self, from: data)
    }
    
    func deleteConversation(id: String) async throws {
        _ = try await request(.delete, APIEndpoints.Chat.conversation(id))
    }
    
    func renameConversation(id: String, title: String) async throws -> Conversation {
        let body = ["title": title]
        let data = try await request(.patch, APIEndpoints.Chat.conversation(id), body: body)
        return try decoder.decode(Conversation.self, from: data)
    }
    
    func getMessages(conversationId: String) async throws -> [Message] {
        let data = try await request(.get, APIEndpoints.Chat.messages(conversationId))
        
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
        print("⚠️ getMessages: Failed to decode messages, returning empty array")
        return []
    }
    
    // MARK: - Knowledge Base Methods
    
    func getDocuments() async throws -> [KnowledgeDocument] {
        let data = try await request(.get, APIEndpoints.Brain.documents)
        return try decoder.decode([KnowledgeDocument].self, from: data)
    }
    
    func searchKnowledge(query: String, category: String? = nil, limit: Int = 10) async throws -> [DocumentSearchResult] {
        var body: [String: Any] = ["query": query, "limit": limit]
        if let category = category { body["category"] = category }
        
        let data = try await request(.post, APIEndpoints.Brain.search, body: body)
        let response = try decoder.decode(SearchResponse.self, from: data)
        return response.results
    }
    
    func deleteDocument(id: String) async throws {
        _ = try await request(.delete, APIEndpoints.Brain.document(id))
    }
    
    func getBrainStats() async throws -> BrainStats {
        let data = try await request(.get, APIEndpoints.Brain.stats)
        return try decoder.decode(BrainStats.self, from: data)
    }
    
    // MARK: - File Upload
    
    func uploadDocument(data: Data, filename: String, category: String = "general") async throws -> UploadResponse {
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
    
    func generateAFL(prompt: String, strategyType: String = "standalone") async throws -> AFLGenerationResponse {
        let body: [String: Any] = [
            "prompt": prompt,
            "strategy_type": strategyType,
            "stream": false
        ]
        let data = try await request(.post, APIEndpoints.AFL.generate, body: body)
        return try decoder.decode(AFLGenerationResponse.self, from: data)
    }
    
    func getAFLHistory() async throws -> [AFLHistoryEntry] {
        let data = try await request(.get, APIEndpoints.AFL.history)
        return (try? decoder.decode([AFLHistoryEntry].self, from: data)) ?? []
    }
    
    func deleteAFLHistory(id: String) async throws {
        _ = try await request(.delete, APIEndpoints.AFL.historyItem(id))
    }
    
    func getCurrentUserProfile() async throws -> User {
        return try await getCurrentUser()
    }
    
    func updateUserProfile(name: String?, nickname: String?, claudeAPIKey: String?, tavilyAPIKey: String?) async throws -> User {
        var body: [String: Any] = [:]
        if let name = name { body["name"] = name }
        if let nickname = nickname { body["nickname"] = nickname }
        if let key = claudeAPIKey { body["claude_api_key"] = key }
        if let key = tavilyAPIKey { body["tavily_api_key"] = key }
        let data = try await request(.put, APIEndpoints.Auth.me, body: body)
        return try decoder.decode(User.self, from: data)
    }
    
    func changePassword(current: String, new: String) async throws {
        let body: [String: Any] = ["current_password": current, "new_password": new]
        _ = try await request(.put, APIEndpoints.Auth.changePassword, body: body)
    }
    
    // MARK: - Generic Request Method
    
    private func request(
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
        
        print("🌐 REQUEST: \(method.rawValue) \(url.absoluteString)")
        if let body = body {
            print("🌐 BODY: \(body)")
        }
        if let httpBody = request.httpBody {
            print("🌐 HTTP BODY RAW: \(String(data: httpBody, encoding: .utf8) ?? "nil")")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("🌐 RESPONSE STATUS: \(httpResponse.statusCode)")
        print("🌐 RESPONSE HEADERS: \(httpResponse.allHeaderFields)")
        print("🌐 RESPONSE DATA: \(String(data: data, encoding: .utf8) ?? "nil")")
        
        try validateResponse(httpResponse, data: data)
        
        return data
    }
    
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
    
    func storeToken(_ token: String) throws {
        try keychain.set(token, forKey: .accessToken)
        self.accessToken = token
    }
    
    private func clearTokens() {
        keychain.delete(.accessToken)
        keychain.delete(.refreshToken)
        accessToken = nil
    }
    
    // MARK: - Get Token for Streaming
    
    func getToken() -> String? {
        accessToken
    }
}

// MARK: - Supporting Types

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct ErrorResponse: Codable {
    let detail: String
}

enum APIError: Error, LocalizedError {
    case unauthorized
    case forbidden
    case notFound
    case clientError(String)
    case serverError
    case invalidResponse
    case decodingError(Error)
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
        case .serverError:
            return "A server error occurred. Please try again later."
        case .invalidResponse:
            return "Invalid response from server."
        case .decodingError(let error):
            return "Failed to process response: \(error.localizedDescription)"
        case .unknown:
            return "An unknown error occurred."
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
