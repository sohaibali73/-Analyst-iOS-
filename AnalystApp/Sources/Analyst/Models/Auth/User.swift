import Foundation

// MARK: - User Model

/// Represents an authenticated user profile.
///
/// ## Security
/// - API keys (`claudeApiKey`, `tavilyApiKey`) are stored as received from the server
///   but should only be displayed in masked form via `maskedClaudeApiKey` / `maskedTavilyApiKey`.
/// - Use `hasClaudeApiKey` / `hasTavilyApiKey` for boolean checks without exposing values.
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

    // MARK: - Display Helpers

    /// Returns the best available display name for the user.
    var displayName: String {
        nickname ?? name ?? email.components(separatedBy: "@").first ?? email
    }

    /// Returns the user's initials (1-2 characters) for avatar display.
    var initials: String {
        let displayName = self.displayName
        let parts = displayName.components(separatedBy: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1)) + String(parts[1].prefix(1))
        }
        return String(displayName.prefix(2)).uppercased()
    }

    // MARK: - API Key Security

    /// Whether the user has a Claude API key configured.
    var hasClaudeApiKey: Bool {
        guard let key = claudeApiKey else { return false }
        return !key.isEmpty
    }

    /// Whether the user has a Tavily API key configured.
    var hasTavilyApiKey: Bool {
        guard let key = tavilyApiKey else { return false }
        return !key.isEmpty
    }

    /// Returns a masked version of the Claude API key for safe display.
    /// Shows first 4 and last 4 characters, e.g., "sk-a...xYz9"
    var maskedClaudeApiKey: String? {
        maskApiKey(claudeApiKey)
    }

    /// Returns a masked version of the Tavily API key for safe display.
    var maskedTavilyApiKey: String? {
        maskApiKey(tavilyApiKey)
    }

    /// Masks an API key for safe display in the UI.
    private func maskApiKey(_ key: String?) -> String? {
        guard let key = key, key.count > 8 else { return key.map { _ in "••••••••" } }
        let prefix = String(key.prefix(4))
        let suffix = String(key.suffix(4))
        return "\(prefix)••••\(suffix)"
    }
}

// MARK: - Auth Response

/// Response returned by login/register endpoints.
/// Note: APIClient uses `.convertFromSnakeCase`, so properties match converted JSON keys.
struct AuthResponse: Codable {
    let accessToken: String    // access_token in JSON
    let tokenType: String      // token_type in JSON
    let userId: String         // user_id in JSON
    let email: String
    let expiresIn: Int         // expires_in in JSON

    /// Computes the token expiration date from `expiresIn`.
    var expirationDate: Date {
        Date().addingTimeInterval(TimeInterval(expiresIn))
    }

    /// Whether the token has expired.
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
