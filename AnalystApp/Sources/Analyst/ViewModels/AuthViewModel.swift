import Foundation
import Observation
import LocalAuthentication

@Observable
final class AuthViewModel {
    // MARK: - Published State
    
    var user: User?
    var isLoading: Bool = true
    var error: AuthError?
    var isBiometricAvailable: Bool = false
    
    // MARK: - Computed Properties
    
    var isAuthenticated: Bool {
        user != nil && !isLoading
    }
    
    var canUseBiometrics: Bool {
        isBiometricAvailable && user != nil
    }
    
    // MARK: - Dependencies
    
    private let apiClient: APIClient
    private let keychain: KeychainManager
    private let hapticManager: HapticManager
    
    // MARK: - Init
    
    init(
        apiClient: APIClient = .shared,
        keychain: KeychainManager = .shared,
        hapticManager: HapticManager = .shared
    ) {
        self.apiClient = apiClient
        self.keychain = keychain
        self.hapticManager = hapticManager
        
        Task {
            await checkBiometricAvailability()
            await checkAuth()
        }
    }
    
    // MARK: - Public Methods
    
    @MainActor
    func checkAuth() async {
        isLoading = true
        error = nil
        
        do {
            // Check if we have stored credentials
            guard keychain.contains(.accessToken) else {
                isLoading = false
                return
            }
            
            // Validate token with server
            let user = try await apiClient.getCurrentUser()
            self.user = user
        } catch {
            // Token is invalid, clear it
            keychain.delete(.accessToken)
            keychain.delete(.refreshToken)
        }
        
        isLoading = false
    }
    
    @MainActor
    func login(email: String, password: String) async throws {
        print("🔐 Login started for: \(email)")
        isLoading = true
        error = nil
        
        defer { 
            isLoading = false
            print("🔐 Login finished - isLoading: \(isLoading), user: \(self.user?.email ?? "nil")")
        }
        
        // Validate input
        guard !email.isEmpty else {
            print("🔐 Login failed: empty email")
            throw AuthError.emptyEmail
        }
        
        guard !password.isEmpty else {
            print("🔐 Login failed: empty password")
            throw AuthError.emptyPassword
        }
        
        guard isValidEmail(email) else {
            print("🔐 Login failed: invalid email format")
            throw AuthError.invalidEmail
        }
        
        do {
            print("🔐 Calling API login...")
            let response = try await apiClient.login(email: email, password: password)
            print("🔐 API login success, token received: \(response.accessToken.prefix(20))...")
            
            // Get user info
            print("🔐 Fetching user info...")
            let user = try await apiClient.getCurrentUser()
            print("🔐 User fetched: \(user.email)")
            self.user = user
            
            // Store email for biometric auth
            if isBiometricAvailable {
                try? keychain.set(email, forKey: .savedEmail)
            }
            
            hapticManager.success()
            print("🔐 Login complete - isAuthenticated: \(self.isAuthenticated)")
        } catch let error as APIError {
            print("🔐 Login API error: \(error.errorDescription ?? "unknown")")
            throw AuthError.apiError(error.errorDescription ?? "Login failed")
        } catch {
            print("🔐 Login unexpected error: \(error.localizedDescription)")
            throw AuthError.apiError(error.localizedDescription)
        }
    }
    
    @MainActor
    func register(email: String, password: String, confirmPassword: String, name: String?, nickname: String?) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        // Validate input
        guard !email.isEmpty else {
            throw AuthError.emptyEmail
        }
        
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        guard password.count >= 8 else {
            throw AuthError.weakPassword
        }
        
        guard password == confirmPassword else {
            throw AuthError.passwordMismatch
        }
        
        do {
            _ = try await apiClient.register(email: email, password: password, name: name, nickname: nickname)
            
            let user = try await apiClient.getCurrentUser()
            self.user = user
            
            hapticManager.success()
        } catch let error as APIError {
            throw AuthError.apiError(error.errorDescription ?? "Registration failed")
        }
    }
    
    @MainActor
    func authenticateWithBiometrics() async throws {
        guard isBiometricAvailable else {
            throw AuthError.biometricNotAvailable
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let context = LAContext()
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            throw AuthError.biometricNotAvailable
        }
        
        let success = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Sign in to your Analyst account"
            ) { success, error in
                if error != nil {
                    continuation.resume(throwing: AuthError.biometricFailed)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
        
        guard success else {
            throw AuthError.biometricFailed
        }
        
        // Validate existing token
        await checkAuth()
    }
    
    @MainActor
    func logout() async {
        isLoading = true
        
        do {
            try await apiClient.logout()
        } catch {
            // Ignore logout errors - we'll clear local state anyway
        }
        
        keychain.delete(.accessToken)
        keychain.delete(.refreshToken)
        user = nil
        isLoading = false
        
        hapticManager.mediumImpact()
    }
    
    // MARK: - Profile & Settings Methods

    @MainActor
    func updateProfile(name: String?, nickname: String?) async throws {
        let updatedUser = try await apiClient.updateUserProfile(
            name: name,
            nickname: nickname,
            claudeAPIKey: nil,
            tavilyAPIKey: nil
        )
        self.user = updatedUser
        hapticManager.success()
    }

    @MainActor
    func updateAPIKeys(claudeKey: String?, tavilyKey: String?) async throws {
        let updatedUser = try await apiClient.updateUserProfile(
            name: nil,
            nickname: nil,
            claudeAPIKey: claudeKey,
            tavilyAPIKey: tavilyKey
        )
        self.user = updatedUser
        hapticManager.success()
    }

    @MainActor
    func changePassword(current: String, new: String) async throws {
        try await apiClient.changePassword(current: current, new: new)
        hapticManager.success()
    }

    // MARK: - Private Helpers

    private func checkBiometricAvailability() async {
        let context = LAContext()
        var error: NSError?
        isBiometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
}

// MARK: - Auth Error

enum AuthError: Error, LocalizedError {
    case notAuthenticated
    case emptyEmail
    case emptyPassword
    case invalidEmail
    case weakPassword
    case passwordMismatch
    case biometricNotAvailable
    case biometricFailed
    case noSavedCredentials
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You are not signed in."
        case .emptyEmail:
            return "Please enter your email address."
        case .emptyPassword:
            return "Please enter your password."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 8 characters."
        case .passwordMismatch:
            return "Passwords do not match."
        case .biometricNotAvailable:
            return "Face ID / Touch ID is not available on this device."
        case .biometricFailed:
            return "Biometric authentication failed."
        case .noSavedCredentials:
            return "No saved credentials found. Please sign in with your password."
        case .apiError(let message):
            return message
        }
    }
}