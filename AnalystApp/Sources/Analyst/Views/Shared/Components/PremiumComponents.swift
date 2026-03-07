import SwiftUI

// MARK: - Pressable Button Style

/// A button style that provides press-scale feedback with haptic
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    var haptic: HapticManager.ImpactStyle = .light
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(AnimationProvider.Spring.snappy.animation, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.shared.impact(haptic)
                }
            }
    }
}

// MARK: - Scale Button Style

/// Simpler scale-only button style
struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Bouncy Button Style

/// A more playful bouncy button style
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

// MARK: - View Extensions for Button Styles

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
    static var pressableLight: PressableButtonStyle { PressableButtonStyle(haptic: .light) }
    static var pressableMedium: PressableButtonStyle { PressableButtonStyle(haptic: .medium) }
    static var pressableHeavy: PressableButtonStyle { PressableButtonStyle(haptic: .heavy) }
    static func pressable(scale: CGFloat, haptic: HapticManager.ImpactStyle = .light) -> PressableButtonStyle {
        PressableButtonStyle(scale: scale, haptic: haptic)
    }
}

extension ButtonStyle where Self == ScaleButtonStyle {
    static var scale: ScaleButtonStyle { ScaleButtonStyle() }
    static func scale(amount: CGFloat) -> ScaleButtonStyle { ScaleButtonStyle(scale: amount) }
}

extension ButtonStyle where Self == BouncyButtonStyle {
    static var bouncy: BouncyButtonStyle { BouncyButtonStyle() }
}

// MARK: - Premium Card Style

/// A modifier that applies premium card styling with depth
struct PremiumCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 14
    var glowColor: Color? = nil
    var glowOpacity: Double = 0.3
    
    func body(content: Content) -> some View {
        content
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .overlay(alignment: .bottom) {
                if let glowColor = glowColor {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(glowColor.opacity(glowOpacity))
                        .frame(height: 1)
                        .blur(radius: 4)
                        .padding(.horizontal, 8)
                }
            }
    }
}

extension View {
    /// Applies premium card styling with optional bottom glow
    func premiumCard(cornerRadius: CGFloat = 14, glowColor: Color? = nil) -> some View {
        modifier(PremiumCardModifier(cornerRadius: cornerRadius, glowColor: glowColor))
    }
}

// MARK: - Animated Entry Modifier

/// Modifier that animates the view when it appears
struct AnimatedEntryModifier: ViewModifier {
    var delay: Double = 0
    var startY: CGFloat = 12
    var duration: Double = 0.4
    
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : startY)
            .onAppear {
                withAnimation(.spring(response: duration, dampingFraction: 0.8).delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

extension View {
    /// Animates the view when it appears with a fade and slide up
    func animatedEntry(delay: Double = 0, startY: CGFloat = 12) -> some View {
        modifier(AnimatedEntryModifier(delay: delay, startY: startY))
    }
}

// MARK: - Staggered Animation Modifier

/// Modifier for staggered list animations
struct StaggeredEntryModifier: ViewModifier {
    let index: Int
    let totalCount: Int
    let baseDelay: Double
    
    @State private var hasAppeared = false
    
    private var delay: Double {
        baseDelay + Double(index) * 0.05
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 16)
            .scaleEffect(hasAppeared ? 1 : 0.95)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75).delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

extension View {
    /// Applies staggered entry animation based on index
    func staggeredEntry(index: Int, totalCount: Int, baseDelay: Double = 0.1) -> some View {
        modifier(StaggeredEntryModifier(index: index, totalCount: totalCount, baseDelay: baseDelay))
    }
}

// MARK: - Glow Effect Modifier

/// Adds a subtle glow effect around the view
struct GlowEffectModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let isAnimating: Bool
    
    @State private var animateGlow = false
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(isAnimating ? (animateGlow ? 0.4 : 0.2) : 0.3),
                radius: isAnimating ? (animateGlow ? radius * 1.2 : radius * 0.8) : radius
            )
            .onAppear {
                if isAnimating {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        animateGlow = true
                    }
                }
            }
    }
}

extension View {
    /// Adds a glow effect around the view
    func glow(color: Color, radius: CGFloat = 8, animated: Bool = false) -> some View {
        modifier(GlowEffectModifier(color: color, radius: radius, isAnimating: animated))
    }
}

// MARK: - Press Scale Modifier

/// Manual press scale for non-button views
struct PressScaleModifier: ViewModifier {
    @GestureState private var isPressed = false
    let scale: CGFloat
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(AnimationProvider.quick, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        HapticManager.shared.lightImpact()
                    }
                    .onEnded { _ in
                        action()
                    }
            )
    }
}

extension View {
    /// Adds press-scale gesture to any view
    func pressScale(scale: CGFloat = 0.96, action: @escaping () -> Void) -> some View {
        modifier(PressScaleModifier(scale: scale, action: action))
    }
}

// MARK: - Gradient Icon Background

/// A gradient background for icons
struct GradientIconBackground: View {
    let color: Color
    let size: CGFloat
    let cornerRadius: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.2), color.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(color.opacity(0.3), lineWidth: 0.5)
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Premium Button

/// A premium styled button with gradient and glow
struct PremiumButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(title: String, icon: String? = nil, color: Color = .potomacYellow, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(.rajdhaniBold(15))
                    .tracking(1)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: color.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                    HapticManager.shared.lightImpact()
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Pill Button

/// A pill-shaped button for quick actions
struct PillButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var isGlowing = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Glow background
                    if isPressed || isGlowing {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(color.opacity(0.3))
                            .frame(width: 52, height: 52)
                            .blur(radius: 8)
                            .transition(.opacity)
                    }
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.18), color.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(color.opacity(0.25), lineWidth: 1)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                .scaleEffect(isPressed ? 0.92 : 1.0)
                
                Text(label)
                    .font(.quicksandSemiBold(11))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(AnimationProvider.quick) {
                        isPressed = true
                    }
                    HapticManager.shared.lightImpact()
                }
                .onEnded { _ in
                    withAnimation(AnimationProvider.quick) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Animated Dots Typing Indicator

/// A more organic typing indicator
struct OrganicTypingIndicator: View {
    @State private var animationPhase = 0.0
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.potomacYellow)
                    .frame(width: 6, height: 6)
                    .offset(y: sin(animationPhase + Double(index) * 0.8) * 4)
                    .opacity(0.6 + sin(animationPhase + Double(index) * 0.8) * 0.3)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: false)) {
                animationPhase = .pi
            }
        }
    }
}

// MARK: - Animated Counter

/// An animated number counter
struct AnimatedCounter: View {
    let value: Int
    let font: Font
    let color: Color
    
    @State private var displayValue: Int = 0
    
    var body: some View {
        Text("\(displayValue)")
            .font(font)
            .foregroundColor(color)
            .contentTransition(.numericText())
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    displayValue = newValue
                }
            }
            .onAppear {
                displayValue = value
            }
    }
}

// MARK: - Floating Action Button

/// A floating action button with glow
struct FloatingActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(color.opacity(isHovering ? 0.4 : 0.25))
                    .frame(width: 64, height: 64)
                    .blur(radius: 12)
                
                // Button background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: color.opacity(0.4), radius: 8, y: 4)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.black)
            }
            .scaleEffect(isPressed ? 0.9 : isHovering ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(AnimationProvider.quick) { isPressed = true }
                    HapticManager.shared.lightImpact()
                }
                .onEnded { _ in
                    withAnimation(AnimationProvider.bouncy) { isPressed = false }
                }
        )
        .onHover { hovering in
            withAnimation(AnimationProvider.quick) { isHovering = hovering }
        }
    }
}

// MARK: - Previews

#Preview("Premium Components") {
    ZStack {
        Color(hex: "0D0D0D").ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 24) {
                // Premium Button
                PremiumButton(title: "GET STARTED", icon: "arrow.right", color: .potomacYellow) {
                    print("Tapped")
                }
                .padding(.horizontal, 20)
                
                // Pill Buttons
                HStack(spacing: 12) {
                    PillButton(icon: "plus.message.fill", label: "New Chat", color: .potomacYellow) {}
                    PillButton(icon: "chevron.left.forwardslash.chevron.right", label: "Generate", color: .potomacTurquoise) {}
                    PillButton(icon: "arrow.up.doc.fill", label: "Upload", color: Color(hex: "A78BFA")) {}
                }
                .padding(.horizontal, 20)
                
                // Card with glow
                VStack(spacing: 12) {
                    Text("Premium Card")
                        .font(.rajdhaniBold(18))
                        .foregroundColor(.white)
                    Text("With bottom glow effect")
                        .font(.quicksandRegular(13))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .premiumCard(glowColor: .potomacYellow)
                .padding(.horizontal, 20)
                
                // Typing indicator
                VStack(spacing: 12) {
                    Text("Typing Indicator")
                        .font(.quicksandSemiBold(12))
                        .foregroundColor(.white.opacity(0.4))
                    OrganicTypingIndicator()
                }
                
                // Floating Action Button
                FloatingActionButton(icon: "plus", color: .potomacYellow) {}
                    .padding(.top, 20)
            }
            .padding(.top, 40)
        }
    }
    .preferredColorScheme(.dark)
}