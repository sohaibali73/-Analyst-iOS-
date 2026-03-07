import Foundation
import LocalAuthentication

/// Manages biometric authentication (Face ID / Touch ID)
@MainActor
class BiometricAuthManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = BiometricAuthManager()
    
    // MARK: - Properties
    
    /// Whether biometric authentication is enabled by the user
    @Published var isEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "biometricAuthEnabled")
        }
    }
    
    /// Whether the app is currently unlocked
    @Published var isUnlocked: Bool = false
    
    /// Whether we're currently authenticating
    @Published var isAuthenticating: Bool = false
    
    /// Last authentication error
    @Published var lastError: String?
    
    /// Available biometric type
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }
    
    /// Whether biometrics are available on this device
    var isAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    // MARK: - Types
    
    enum BiometricType {
        case none
        case faceID
        case touchID
        
        var name: String {
            switch self {
            case .none: return "Not Available"
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            }
        }
        
        var iconName: String {
            switch self {
            case .none: return "lock.slash"
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            }
        }
    }
    
    // MARK: - Init
    
    private init() {
        // Load saved preference
        isEnabled = UserDefaults.standard.bool(forKey: "biometricAuthEnabled")
        
        // Start unlocked if biometric auth is disabled
        if !isEnabled {
            isUnlocked = true
        }
    }
    
    // MARK: - Authentication
    
    /// Request biometric authentication
    /// - Parameter reason: The reason to display to the user
    /// - Returns: Whether authentication succeeded
    @discardableResult
    func authenticate(reason: String = "Unlock Analyst") async -> Bool {
        // If disabled or already unlocked, return true
        guard isEnabled else {
            isUnlocked = true
            return true
        }
        
        guard isAvailable else {
            lastError = "Biometric authentication is not available on this device"
            return false
        }
        
        let context = LAContext()
        context.localizedCancelTitle = "Use Passcode"
        context.localizedFallbackTitle = "Use Passcode"
        
        isAuthenticating = true
        lastError = nil
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            
            isUnlocked = success
            isAuthenticating = false
            return success
            
        } catch {
            lastError = error.localizedDescription
            isAuthenticating = false
            return false
        }
    }
    
    /// Lock the app (require biometric auth on next open)
    func lock() {
        guard isEnabled else { return }
        isUnlocked = false
    }
    
    /// Unlock without authentication (for use after password login)
    func unlockWithoutAuth() {
        isUnlocked = true
    }
    
    /// Enable biometric auth and authenticate to confirm
    func enable() async -> Bool {
        guard isAvailable else {
            lastError = "Biometric authentication is not available"
            return false
        }
        
        let success = await authenticate(reason: "Enable biometric authentication")
        if success {
            isEnabled = true
        }
        return success
    }
    
    /// Disable biometric auth
    func disable() {
        isEnabled = false
        isUnlocked = true
    }
}