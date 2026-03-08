//
//  AuthViewModelTests.swift
//  AnalystTests
//
//  Comprehensive unit tests for AuthViewModel, User model, and error types.
//

import XCTest
@testable import Analyst

final class AuthViewModelTests: XCTestCase {

    var sut: AuthViewModel!

    override func setUp() {
        super.setUp()
        sut = AuthViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_isLoading() {
        // AuthViewModel starts with isLoading = true (checkAuth runs in Task)
        XCTAssertNil(sut.user)
        XCTAssertTrue(sut.isLoading)
    }

    func testInitialState_noError() {
        XCTAssertNil(sut.error)
        XCTAssertNil(sut.userFacingError)
    }

    // MARK: - Logout Tests

    func testLogout_clearsUser() async {
        sut.user = makeTestUser()

        await sut.logout()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.user)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Error Handling Tests

    func testClearError_resetsState() {
        sut.error = .emptyEmail
        XCTAssertNotNil(sut.userFacingError)

        sut.clearError()

        XCTAssertNil(sut.error)
        XCTAssertNil(sut.userFacingError)
    }

    func testUserFacingError_reflectsError() {
        sut.error = .invalidEmail
        XCTAssertEqual(sut.userFacingError, "Please enter a valid email address.")
    }

    // MARK: - User Model Tests: Initials

    func testUserInitials_fromTwoWordName() {
        let user = makeTestUser(name: "John Doe")
        XCTAssertEqual(user.initials, "JD")
    }

    func testUserInitials_fromSingleName() {
        let user = makeTestUser(name: "Alice")
        XCTAssertEqual(user.initials, "AL")
    }

    func testUserInitials_fromEmail() {
        let user = makeTestUser(name: nil, email: "testuser@test.com")
        XCTAssertEqual(user.initials, "TE")
    }

    func testUserInitials_fromNickname() {
        let user = makeTestUser(name: "John Doe", nickname: "JD")
        // nickname takes priority for displayName, initials = "JD"
        XCTAssertEqual(user.initials, "JD")
    }

    // MARK: - User Model Tests: Display Name

    func testDisplayName_usesNickname() {
        let user = makeTestUser(name: "John Doe", nickname: "Johnny")
        XCTAssertEqual(user.displayName, "Johnny")
    }

    func testDisplayName_usesName() {
        let user = makeTestUser(name: "John Doe", nickname: nil)
        XCTAssertEqual(user.displayName, "John Doe")
    }

    func testDisplayName_fallsBackToEmail() {
        let user = makeTestUser(name: nil, nickname: nil, email: "hello@test.com")
        XCTAssertEqual(user.displayName, "hello")
    }

    // MARK: - User Model Tests: API Key Security

    func testHasClaudeApiKey_true() {
        let user = makeTestUser(claudeApiKey: "sk-ant-1234567890")
        XCTAssertTrue(user.hasClaudeApiKey)
    }

    func testHasClaudeApiKey_false_nil() {
        let user = makeTestUser(claudeApiKey: nil)
        XCTAssertFalse(user.hasClaudeApiKey)
    }

    func testHasClaudeApiKey_false_empty() {
        let user = makeTestUser(claudeApiKey: "")
        XCTAssertFalse(user.hasClaudeApiKey)
    }

    func testMaskedClaudeApiKey_longKey() {
        let user = makeTestUser(claudeApiKey: "sk-ant-api03-abcdefghijklmnop")
        let masked = user.maskedClaudeApiKey
        XCTAssertNotNil(masked)
        // Should show first 4 and last 4 chars
        XCTAssertTrue(masked!.hasPrefix("sk-a"))
        XCTAssertTrue(masked!.hasSuffix("mnop"))
        XCTAssertTrue(masked!.contains("••••"))
        // Should NOT contain the full key
        XCTAssertFalse(masked!.contains("abcdefghijklmnop"))
    }

    func testMaskedClaudeApiKey_shortKey() {
        let user = makeTestUser(claudeApiKey: "short")
        let masked = user.maskedClaudeApiKey
        XCTAssertNotNil(masked)
        // Short keys should be fully masked
        XCTAssertEqual(masked, "••••••••")
    }

    func testMaskedClaudeApiKey_nil() {
        let user = makeTestUser(claudeApiKey: nil)
        XCTAssertNil(user.maskedClaudeApiKey)
    }

    func testHasTavilyApiKey() {
        let userWithKey = makeTestUser(tavilyApiKey: "tvly-abc123")
        XCTAssertTrue(userWithKey.hasTavilyApiKey)

        let userWithout = makeTestUser(tavilyApiKey: nil)
        XCTAssertFalse(userWithout.hasTavilyApiKey)
    }

    // MARK: - Auth Error Tests

    func testAuthError_allCases_haveDescriptions() {
        let errors: [AuthError] = [
            .notAuthenticated,
            .emptyEmail,
            .emptyPassword,
            .invalidEmail,
            .weakPassword,
            .passwordMismatch,
            .biometricNotAvailable,
            .biometricFailed,
            .noSavedCredentials,
            .apiError("test"),
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Missing description for \(error)")
            XCTAssertFalse(error.errorDescription!.isEmpty, "Empty description for \(error)")
        }
    }

    func testAuthError_apiError_preservesMessage() {
        let error = AuthError.apiError("Custom server error message")
        XCTAssertEqual(error.errorDescription, "Custom server error message")
    }

    // MARK: - AuthResponse Tests

    func testAuthResponse_isExpired_false() {
        let response = AuthResponse(
            accessToken: "token",
            tokenType: "bearer",
            userId: "user-1",
            email: "test@test.com",
            expiresIn: 3600
        )
        XCTAssertFalse(response.isExpired)
    }

    func testAuthResponse_isExpired_true() {
        let response = AuthResponse(
            accessToken: "token",
            tokenType: "bearer",
            userId: "user-1",
            email: "test@test.com",
            expiresIn: 0 // expires immediately
        )
        // expiresIn = 0 means expiration = now, so it should be expired
        XCTAssertTrue(response.isExpired)
    }

    func testAuthResponse_expirationDate() {
        let response = AuthResponse(
            accessToken: "token",
            tokenType: "bearer",
            userId: "user-1",
            email: "test@test.com",
            expiresIn: 3600
        )
        // Expiration should be ~1 hour from now
        let expected = Date().addingTimeInterval(3600)
        XCTAssertEqual(response.expirationDate.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 2.0)
    }

    // MARK: - APIError Tests

    func testAPIError_allCases_haveDescriptions() {
        let errors: [APIError] = [
            .unauthorized,
            .forbidden,
            .notFound,
            .clientError("test"),
            .validationError("test"),
            .rateLimited,
            .serverError,
            .invalidResponse,
            .networkUnavailable,
            .unknown,
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Missing description for \(error)")
        }
    }

    func testAPIError_isRetryable() {
        XCTAssertTrue(APIError.serverError.isRetryable)
        XCTAssertTrue(APIError.rateLimited.isRetryable)
        XCTAssertFalse(APIError.unauthorized.isRetryable)
        XCTAssertFalse(APIError.forbidden.isRetryable)
        XCTAssertFalse(APIError.notFound.isRetryable)
        XCTAssertFalse(APIError.clientError("test").isRetryable)
        XCTAssertFalse(APIError.invalidResponse.isRetryable)
    }

    func testAPIError_rateLimited_message() {
        XCTAssertEqual(APIError.rateLimited.errorDescription, "Too many requests. Please wait a moment and try again.")
    }

    func testAPIError_validationError_message() {
        let error = APIError.validationError("Email already exists")
        XCTAssertTrue(error.errorDescription!.contains("Email already exists"))
    }

    // MARK: - Keychain Error Tests

    func testKeychainError_descriptions() {
        XCTAssertNotNil(KeychainError.encodingFailed.errorDescription)
        XCTAssertNotNil(KeychainError.saveFailed(0).errorDescription)
        XCTAssertNotNil(KeychainError.notFound.errorDescription)
    }

    // MARK: - PaginationState Tests

    func testPaginationConfiguration_defaults() {
        let config = PaginationConfiguration.default
        XCTAssertEqual(config.pageSize, 20)
        XCTAssertEqual(config.prefetchThreshold, 5)
    }

    // MARK: - CacheTTL Tests

    func testCacheTTL_values() {
        XCTAssertEqual(CacheTTL.short, 60)
        XCTAssertEqual(CacheTTL.medium, 300)
        XCTAssertEqual(CacheTTL.long, 3600)
        XCTAssertEqual(CacheTTL.day, 86400)
        XCTAssertEqual(CacheTTL.week, 604800)
    }

    // MARK: - CacheKey Tests

    func testCacheKey_uniqueKeys() {
        XCTAssertEqual(CacheKey.conversations.key, "conversations_list")
        XCTAssertEqual(CacheKey.documents.key, "documents_list")
        XCTAssertEqual(CacheKey.user.key, "user_profile")
        XCTAssertEqual(CacheKey.conversation(id: "abc").key, "conversation_abc")
        XCTAssertEqual(CacheKey.stock(symbol: "AAPL", type: "ticker").key, "stock_AAPL_ticker")
    }

    // MARK: - Helpers

    private func makeTestUser(
        name: String? = "Test User",
        nickname: String? = nil,
        email: String = "test@test.com",
        claudeApiKey: String? = nil,
        tavilyApiKey: String? = nil
    ) -> User {
        User(
            id: "test-\(UUID().uuidString.prefix(8))",
            email: email,
            name: name,
            nickname: nickname,
            avatarUrl: nil,
            createdAt: nil,
            lastActive: nil,
            claudeApiKey: claudeApiKey,
            tavilyApiKey: tavilyApiKey
        )
    }
}
