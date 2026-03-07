import SwiftUI

// MARK: - Animation Provider

/// Centralized animation configuration for consistent timing throughout the app
enum AnimationProvider {
    // MARK: - Durations
    
    enum Duration {
        static let instant: Double = 0.1
        static let fast: Double = 0.2
        static let normal: Double = 0.3
        static let slow: Double = 0.4
        static let verySlow: Double = 0.6
    }
    
    // MARK: - Spring Configurations
    
    enum Spring {
        case `default`
        case gentle
        case bouncy
        case snappy
        case smooth
        case stiff
        
        var animation: Animation {
            switch self {
            case .default:
                return .spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0)
            case .gentle:
                return .spring(response: 0.5, dampingFraction: 0.85, blendDuration: 0)
            case .bouncy:
                return .spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)
            case .snappy:
                return .spring(response: 0.25, dampingFraction: 0.8, blendDuration: 0)
            case .smooth:
                return .spring(response: 0.45, dampingFraction: 0.9, blendDuration: 0)
            case .stiff:
                return .spring(response: 0.2, dampingFraction: 0.95, blendDuration: 0)
            }
        }
        
        var parameters: (response: Double, dampingFraction: Double) {
            switch self {
            case .default: return (0.35, 0.75)
            case .gentle: return (0.5, 0.85)
            case .bouncy: return (0.4, 0.6)
            case .snappy: return (0.25, 0.8)
            case .smooth: return (0.45, 0.9)
            case .stiff: return (0.2, 0.95)
            }
        }
    }
    
    // MARK: - Easing Curves
    
    enum Easing {
        case easeIn
        case easeOut
        case easeInOut
        case linear
        
        var animation: Animation {
            return animation(duration: Duration.normal)
        }
        
        func animation(duration: Double) -> Animation {
            switch self {
            case .easeIn:
                return .timingCurve(0.42, 0, 1, 1, duration: duration)
            case .easeOut:
                return .timingCurve(0, 0, 0.58, 1, duration: duration)
            case .easeInOut:
                return .timingCurve(0.42, 0, 0.58, 1, duration: duration)
            case .linear:
                return .linear(duration: duration)
            }
        }
    }
    
    // MARK: - Common Animations
    
    /// Standard spring animation for most UI interactions
    static var standard: Animation {
        Spring.default.animation
    }
    
    /// Quick spring for button presses and micro-interactions
    static var quick: Animation {
        Spring.snappy.animation
    }
    
    /// Smooth spring for transitions and content changes
    static var smooth: Animation {
        Spring.smooth.animation
    }
    
    /// Bouncy spring for playful interactions
    static var bouncy: Animation {
        Spring.bouncy.animation
    }
    
    /// Fade in animation
    static func fadeIn(duration: Double = Duration.normal) -> Animation {
        .easeInOut(duration: duration)
    }
    
    /// Slide in from edge
    static func slideIn(from edge: Edge, duration: Double = Duration.normal) -> Animation {
        .spring(response: duration, dampingFraction: 0.8)
    }
    
    /// Scale animation
    static func scale(duration: Double = Duration.fast) -> Animation {
        .spring(response: duration, dampingFraction: 0.7)
    }
}

// MARK: - View Transitions

/// Custom transitions for consistent UI animations
extension AnyTransition {
    /// Fade in/out transition
    static var fade: AnyTransition {
        .opacity
    }
    
    /// Scale fade transition (good for modals and overlays)
    static var scaleFade: AnyTransition {
        .scale(scale: 0.95).combined(with: .opacity)
    }
    
    /// Slide from bottom with fade
    static var slideUp: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }
    
    /// Slide from top with fade
    static var slideDown: AnyTransition {
        .move(edge: .top).combined(with: .opacity)
    }
    
    /// Slide from leading edge
    static var slideLeading: AnyTransition {
        .move(edge: .leading).combined(with: .opacity)
    }
    
    /// Slide from trailing edge
    static var slideTrailing: AnyTransition {
        .move(edge: .trailing).combined(with: .opacity)
    }
    
    /// Pop in/out with scale and opacity
    static var pop: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 1.05).combined(with: .opacity)
        )
    }
    
    /// Card insertion transition
    static var cardInsert: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        )
    }
    
    /// Expand from center
    static var expand: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.5).combined(with: .opacity),
            removal: .scale(scale: 1.2).combined(with: .opacity)
        )
    }
}

// MARK: - View Modifiers

/// Pressed state modifier for buttons
struct PressableModifier: ViewModifier {
    @State private var isPressed = false
    let scale: CGFloat
    let action: () -> Void
    
    init(scale: CGFloat = 0.96, action: @escaping () -> Void) {
        self.scale = scale
        self.action = action
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(AnimationProvider.quick, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in
                        isPressed = false
                        action()
                    }
            )
    }
}

/// Animated visibility modifier
struct AnimatedVisibilityModifier: ViewModifier {
    let isVisible: Bool
    let transition: AnyTransition
    let animation: Animation
    
    func body(content: Content) -> some View {
        if isVisible {
            content
                .transition(transition)
                .animation(animation, value: isVisible)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply standard spring animation
    func animateStandard() -> some View {
        self.animation(AnimationProvider.standard, value: UUID())
    }
    
    /// Apply pressed state animation
    func pressable(scale: CGFloat = 0.96, action: @escaping () -> Void) -> some View {
        modifier(PressableModifier(scale: scale, action: action))
    }
    
    /// Conditional animated visibility
    func animatedVisibility(
        _ isVisible: Bool,
        transition: AnyTransition = .fade,
        animation: Animation = AnimationProvider.standard
    ) -> some View {
        modifier(AnimatedVisibilityModifier(
            isVisible: isVisible,
            transition: transition,
            animation: animation
        ))
    }
    
    /// Shrink on tap gesture
    func shrinkOnTap(action: @escaping () -> Void) -> some View {
        self.modifier(PressableModifier(scale: 0.96, action: action))
    }
    
    /// Apply conditional animation
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            return transform(self)
        } else {
            return AnyView(self)
        }
    }
}

// MARK: - Animation Completion Modifier

/// Modifier that triggers a callback when an animation completes
struct AnimationCompletionModifier<Value: Equatable>: ViewModifier {
    let value: Value
    let completion: () -> Void
    
    @State private var oldValue: Value
    
    init(value: Value, completion: @escaping () -> Void) {
        self.value = value
        self.completion = completion
        self._oldValue = State(initialValue: value)
    }
    
    func body(content: Content) -> some View {
        content
            .onChange(of: value) { _, newValue in
                oldValue = newValue
                // Delay completion slightly to allow animation to finish
                DispatchQueue.main.asyncAfter(deadline: .now() + AnimationProvider.Duration.normal) {
                    completion()
                }
            }
    }
}

extension View {
    /// Trigger callback when animation on value completes
    func onAnimationComplete<Value: Equatable>(
        of value: Value,
        completion: @escaping () -> Void
    ) -> some View {
        modifier(AnimationCompletionModifier(value: value, completion: completion))
    }
}

// MARK: - Conditional View Extension

extension AnyView {
    /// Conditional view builder helper
    static func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: () -> TrueContent,
        else elseTransform: () -> FalseContent
    ) -> AnyView where TrueContent: View, FalseContent: View {
        if condition {
            return AnyView(ifTransform())
        } else {
            return AnyView(elseTransform())
        }
    }
}