import Foundation
import SwiftUI

/// Manages automatic app locking after inactivity
@MainActor
class AutoLockManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AutoLockManager()
    
    // MARK: - Properties
    
    /// Auto-lock duration options
    enum AutoLockDuration: String, CaseIterable, Identifiable {
        case immediately = "immediately"
        case oneMinute = "1 minute"
        case fiveMinutes = "5 minutes"
        case fifteenMinutes = "15 minutes"
        case thirtyMinutes = "30 minutes"
        case oneHour = "1 hour"
        case never = "never"
        
        var id: String { rawValue }
        
        var displayText: String { rawValue }
        
        var seconds: TimeInterval? {
            switch self {
            case .immediately: return 0
            case .oneMinute: return 60
            case .fiveMinutes: return 300
            case .fifteenMinutes: return 900
            case .thirtyMinutes: return 1800
            case .oneHour: return 3600
            case .never: return nil
            }
        }
    }
    
    /// Selected auto-lock duration
    @Published var duration: AutoLockDuration = .fiveMinutes {
        didSet {
            UserDefaults.standard.set(duration.rawValue, forKey: "autoLockDuration")
        }
    }
    
    /// Last activity timestamp
    private var lastActivity: Date = Date()
    
    /// Timer for checking lock status
    private var timer: Timer?
    
    /// Whether auto-lock is currently active (biometrics enabled + duration set)
    var isActive: Bool {
        BiometricAuthManager.shared.isEnabled && duration.seconds != nil
    }
    
    // MARK: - Init
    
    private init() {
        // Load saved duration
        if let savedValue = UserDefaults.standard.string(forKey: "autoLockDuration"),
           let savedDuration = AutoLockDuration(rawValue: savedValue) {
            duration = savedDuration
        }
        startMonitoring()
    }
    
    // MARK: - Monitoring
    
    /// Start monitoring for inactivity
    func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkLockStatus()
            }
        }
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    /// Stop monitoring
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Record user activity (call on touches, scrolls, etc.)
    func recordActivity() {
        lastActivity = Date()
    }
    
    /// Check if we should lock the app
    private func checkLockStatus() {
        let bioAuth = BiometricAuthManager.shared
        
        // Skip if biometrics disabled or duration is never
        guard bioAuth.isEnabled, let lockSeconds = duration.seconds else { return }
        
        // Skip if already locked
        guard bioAuth.isUnlocked else { return }
        
        let elapsed = Date().timeIntervalSince(lastActivity)
        
        if elapsed >= lockSeconds {
            bioAuth.lock()
        }
    }
    
    /// Force immediate lock check
    func forceCheck() {
        checkLockStatus()
    }
}

// MARK: - View Modifier for Activity Tracking

struct ActivityTrackingModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear { AutoLockManager.shared.recordActivity() }
            .onTapGesture { AutoLockManager.shared.recordActivity() }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in AutoLockManager.shared.recordActivity() }
            )
    }
}

extension View {
    /// Track user activity for auto-lock
    func trackActivity() -> some View {
        modifier(ActivityTrackingModifier())
    }
}