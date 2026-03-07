import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: String
    let email: String
    let name: String?
    let nickname: String?
    let avatarUrl: String?
    let createdAt: Date?
    let lastActive: Date?
    let claudeApiKey: String?
    let tavilyApiKey: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case nickname
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case lastActive = "last_active"
        case claudeApiKey = "claude_api_key"
        case tavilyApiKey = "tavily_api_key"
    }
    
    var displayName: String {
        nickname ?? name ?? email.components(separatedBy: "@").first ?? email
    }
    
    var initials: String {
        let name = displayName
        let parts = name.components(separatedBy: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1)) + String(parts[1].prefix(1))
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Auth Response
// Note: APIClient uses .convertFromSnakeCase, so properties match converted JSON keys

struct AuthResponse: Codable {
    let accessToken: String    // access_token in JSON
    let tokenType: String      // token_type in JSON
    let userId: String         // user_id in JSON
    let email: String
    let expiresIn: Int         // expires_in in JSON
    
    var expirationDate: Date {
        Date().addingTimeInterval(TimeInterval(expiresIn))
    }
    
    var isExpired: Bool {
        Date() >= expirationDate
    }
}

// MARK: - Login Request

struct LoginRequest: Codable {
    let email: String
    let password: String
}

// MARK: - Register Request

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String?
    let nickname: String?
    let claudeApiKey: String?
    let tavilyApiKey: String?
}

// MARK: - Update User Request

struct UpdateUserRequest: Codable {
    let name: String?
    let nickname: String?
    let claudeApiKey: String?
    let tavilyApiKey: String?
}

// MARK: - Change Password Request

struct ChangePasswordRequest: Codable {
    let currentPassword: String
    let newPassword: String
    
    enum CodingKeys: String, CodingKey {
        case currentPassword = "current_password"
        case newPassword = "new_password"
    }
}