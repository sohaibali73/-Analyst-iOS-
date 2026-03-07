//
//  AuthViewModelTests.swift
//  AnalystTests
//
//  Phase 8: Unit tests for AuthViewModel
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
        // isAuthenticated = user != nil && !isLoading → false when loading
        XCTAssertNil(sut.user)
        XCTAssertTrue(sut.isLoading)
    }
    
    // MARK: - Logout Tests
    
    func testLogout_clearsUser() async {
        // Given — set a user to simulate authenticated state
        sut.user = User(
            id: "test",
            email: "test@test.com",
            name: "Test User",
            nickname: nil,
            avatarUrl: nil,
            createdAt: nil,
            lastActive: nil,
            claudeApiKey: nil,
            tavilyApiKey: nil
        )
        
        // When
        await sut.logout()
        
        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.user)
    }
    
    // MARK: - User Initials Tests
    
    func testUserInitials_fromName() {
        let user = User(
            id: "1",
            email: "test@test.com",
            name: "John Doe",
            nickname: nil,
            avatarUrl: nil,
            createdAt: nil,
            lastActive: nil,
            claudeApiKey: nil,
            tavilyApiKey: nil
        )
        XCTAssertEqual(user.initials, "JD")
    }
    
    func testUserInitials_fromEmail() {
        let user = User(
            id: "1",
            email: "testuser@test.com",
            name: nil,
            nickname: nil,
            avatarUrl: nil,
            createdAt: nil,
            lastActive: nil,
            claudeApiKey: nil,
            tavilyApiKey: nil
        )
        // displayName = email prefix "testuser", initials = "TE" (first 2 chars uppercased)
        XCTAssertEqual(user.initials, "TE")
    }
    
    // MARK: - Display Name Tests
    
    func testDisplayName_usesName() {
        let user = User(
            id: "1",
            email: "test@test.com",
            name: "John Doe",
            nickname: nil,
            avatarUrl: nil,
            createdAt: nil,
            lastActive: nil,
            claudeApiKey: nil,
            tavilyApiKey: nil
        )
        XCTAssertEqual(user.displayName, "John Doe")
    }
    
    func testDisplayName_usesNickname() {
        let user = User(
            id: "1",
            email: "test@test.com",
            name: "John Doe",
            nickname: "Johnny",
            avatarUrl: nil,
            createdAt: nil,
            lastActive: nil,
            claudeApiKey: nil,
            tavilyApiKey: nil
        )
        XCTAssertEqual(user.displayName, "Johnny")
    }
    
    func testDisplayName_fallsBackToEmail() {
        let user = User(
            id: "1",
            email: "hello@test.com",
            name: nil,
            nickname: nil,
            avatarUrl: nil,
            createdAt: nil,
            lastActive: nil,
            claudeApiKey: nil,
            tavilyApiKey: nil
        )
        XCTAssertEqual(user.displayName, "hello")
    }
    
    // MARK: - Auth Error Tests
    
    func testAuthError_descriptions() {
        XCTAssertNotNil(AuthError.emptyEmail.errorDescription)
        XCTAssertNotNil(AuthError.emptyPassword.errorDescription)
        XCTAssertNotNil(AuthError.invalidEmail.errorDescription)
        XCTAssertNotNil(AuthError.weakPassword.errorDescription)
        XCTAssertNotNil(AuthError.passwordMismatch.errorDescription)
        XCTAssertNotNil(AuthError.biometricNotAvailable.errorDescription)
        XCTAssertNotNil(AuthError.apiError("test").errorDescription)
    }
    
    // MARK: - AuthResponse Tests
    
    func testAuthResponse_isExpired() {
        let response = AuthResponse(
            accessToken: "token",
            tokenType: "bearer",
            userId: "user-1",
            email: "test@test.com",
            expiresIn: 3600
        )
        XCTAssertFalse(response.isExpired)
    }
}
