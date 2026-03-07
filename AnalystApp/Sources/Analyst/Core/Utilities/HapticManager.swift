import Foundation

#if canImport(UIKit)
import UIKit
#endif

class HapticManager {
    static let shared = HapticManager()

    /// Check if haptics are enabled via UserDefaults
    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "notifyHaptic") as? Bool ?? true
    }

    #if canImport(UIKit)
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    #endif

    private init() {}
    
    // MARK: - Prepare
    
    func prepare() {
        #if canImport(UIKit)
        impactGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
        #endif
    }
    
    // MARK: - Impact
    
    func impact(_ style: ImpactStyle) {
        guard isEnabled else { return }
        #if canImport(UIKit)
        let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case .light: uiStyle = .light
        case .medium: uiStyle = .medium
        case .heavy: uiStyle = .heavy
        case .soft: uiStyle = .soft
        case .rigid: uiStyle = .rigid
        }
        
        let generator = UIImpactFeedbackGenerator(style: uiStyle)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    func lightImpact() {
        impact(.light)
    }
    
    func mediumImpact() {
        impact(.medium)
    }
    
    func heavyImpact() {
        impact(.heavy)
    }
    
    // MARK: - Notification
    
    func notification(_ type: NotificationType) {
        guard isEnabled else { return }
        #if canImport(UIKit)
        let uiType: UINotificationFeedbackGenerator.FeedbackType
        switch type {
        case .success: uiType = .success
        case .warning: uiType = .warning
        case .error: uiType = .error
        }
        
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(uiType)
        #endif
    }
    
    func success() {
        notification(.success)
    }
    
    func warning() {
        notification(.warning)
    }
    
    func error() {
        notification(.error)
    }
    
    // MARK: - Selection
    
    func selection() {
        guard isEnabled else { return }
        #if canImport(UIKit)
        selectionGenerator.selectionChanged()
        #endif
    }
    
    // MARK: - Cross-Platform Types
    
    enum ImpactStyle {
        case light
        case medium
        case heavy
        case soft
        case rigid
    }
    
    enum NotificationType {
        case success
        case warning
        case error
    }
}