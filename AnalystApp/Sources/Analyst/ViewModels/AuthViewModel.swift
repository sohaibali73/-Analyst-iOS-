import Foundation
import Observation
import LocalAuthentication

// MARK: - Auth View Model

/// Manages user authentication state, biometric auth, and profile operations.
///
/// ## Error Handling
/// - Uses `AuthError` for all user-facing error types.
/// - `userFacingError` provides a computed string for UI display.
/// - `clearError()` resets error state after dismissal.
///
/// ## Security
/// - Tokens are stored/cleared via `KeychainManager`.
/// - Biometric auth validates the existing token, not stored credentials.
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

    /// User-friendly error message for UI display.
    var userFacingError: String? {
        error?.errorDescription
    }

    /// Clears the current error state.
    func clearError() {
        error = nil
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

    // MARK: - Authentication Methods

    /// Checks if an existing token is valid and loads the user profile.
    @MainActor
    func checkAuth() async {
        isLoading = true
        error = nil

        do {
            guard keychain.contains(.accessToken) else {
                isLoading = false
                return
            }

            let user = try await apiClient.getCurrentUser()
            self.user = user
        } catch {
            // Token is invalid, clear it
            keychain.delete(.accessToken)
            keychain.delete(.refreshToken)
            debugLog("Token validation failed: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Authenticates a user with email and password.
    ///
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's password.
    /// - Throws: `AuthError` on validation or API failure.
    @MainActor
    func login(email: String, password: String) async throws {
        isLoading = true
        error = nil

        defer {
            isLoading = false
        }

        // Validate input
        guard !email.isEmpty else {
            throw AuthError.emptyEmail
        }
        guard !password.isEmpty else {
            throw AuthError.emptyPassword
        }
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        do {
            _ = try await apiClient.login(email: email, password: password)

            let user = try await apiClient.getCurrentUser()
            self.user = user

            // Store email for biometric auth
            if isBiometricAvailable {
                try? keychain.set(email, forKey: .savedEmail)
            }

            hapticManager.success()
        } catch let error as APIError {
            throw AuthError.apiError(error.errorDescription ?? "Login failed")
        } catch {
            throw AuthError.apiError(error.localizedDescription)
        }
    }

    /// Registers a new user account.
    ///
    /// - Throws: `AuthError` on validation or API failure.
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

    /// Authenticates using Face ID / Touch ID.
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

    /// Logs out the current user.
    @MainActor
    func logout() async {
        isLoading = true

        do {
            try await apiClient.logout()
        } catch {
            // Ignore logout errors — we'll clear local state anyway
            debugLog("Logout API error (ignored): \(error.localizedDescription)")
        }

        keychain.delete(.accessToken)
        keychain.delete(.refreshToken)
        user = nil
        isLoading = false

        hapticManager.mediumImpact()
    }

    // MARK: - Profile & Settings Methods

    /// Updates the user's profile name and nickname.
    @MainActor
    func updateProfile(name: String?, nickname: String?) async throws {
        do {
            let updatedUser = try await apiClient.updateUserProfile(
                name: name,
                nickname: nickname,
                claudeAPIKey: nil,
                tavilyAPIKey: nil
            )
            self.user = updatedUser
            hapticManager.success()
        } catch let error as APIError {
            throw AuthError.apiError(error.errorDescription ?? "Profile update failed")
        }
    }

    /// Updates the user's external API keys.
    @MainActor
    func updateAPIKeys(claudeKey: String?, tavilyKey: String?) async throws {
        do {
            let updatedUser = try await apiClient.updateUserProfile(
                name: nil,
                nickname: nil,
                claudeAPIKey: claudeKey,
                tavilyAPIKey: tavilyKey
            )
            self.user = updatedUser
            hapticManager.success()
        } catch let error as APIError {
            throw AuthError.apiError(error.errorDescription ?? "API key update failed")
        }
    }

    /// Changes the user's password.
    @MainActor
    func changePassword(current: String, new: String) async throws {
        guard !current.isEmpty else {
            throw AuthError.emptyPassword
        }
        guard new.count >= 8 else {
            throw AuthError.weakPassword
        }

        do {
            try await apiClient.changePassword(current: current, new: new)
            hapticManager.success()
        } catch let error as APIError {
            throw AuthError.apiError(error.errorDescription ?? "Password change failed")
        }
    }

    // MARK: - Private Helpers

    private func checkBiometricAvailability() async {
        let context = LAContext()
        var error: NSError?
        isBiometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Validates email format using a regular expression.
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    /// Logs messages only in DEBUG builds.
    private func debugLog(_ message: String) {
        #if DEBUG
        print("🔐 AuthVM: \(message)")
        #endif
    }
}

// MARK: - Auth Error

/// Authentication-specific error types with user-friendly descriptions.
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
