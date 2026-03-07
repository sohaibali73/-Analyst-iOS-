import SwiftUI

// MARK: - Toast System

/// Toast notification type
enum ToastType {
    case success
    case error
    case warning
    case info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .potomacYellow
        case .info: return .chartBlue
        }
    }
}

/// Toast notification view
struct ToastItem: Identifiable, Equatable {
    let id = UUID()
    let type: ToastType
    let message: String
    let duration: TimeInterval
    
    init(type: ToastType, message: String, duration: TimeInterval = 3.0) {
        self.type = type
        self.message = message
        self.duration = duration
    }
    
    static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// Toast view component
struct ToastView: View {
    let toast: ToastItem
    @State private var isShowing = false
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(toast.type.color)
            
            Text(toast.message)
                .font(.quicksandRegular(14))
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color(hex: "1a1a2e"))
                .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
        )
        .overlay(
            Capsule()
                .stroke(toast.type.color.opacity(0.3), lineWidth: 1)
        )
        .offset(y: isShowing ? 0 : 100)
        .opacity(isShowing ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isShowing = true
            }
        }
    }
}

/// Toast manager for displaying notifications
@Observable
final class ToastManager {
    static let shared = ToastManager()
    
    var currentToast: ToastItem?
    private var dismissTask: Task<Void, Never>?
    
    private init() {}
    
    func show(_ type: ToastType, message: String, duration: TimeInterval = 3.0) {
        // Cancel previous dismiss task
        dismissTask?.cancel()
        
        // Show new toast
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentToast = ToastItem(type: type, message: message, duration: duration)
        }
        
        // Auto-dismiss
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                currentToast = nil
            }
        }
    }
    
    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            currentToast = nil
        }
    }
    
    // Convenience methods
    func success(_ message: String) { show(.success, message: message) }
    func error(_ message: String) { show(.error, message: message) }
    func warning(_ message: String) { show(.warning, message: message) }
    func info(_ message: String) { show(.info, message: message) }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @State private var toastManager = ToastManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let toast = toastManager.currentToast {
                    ToastView(toast: toast)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1000)
                }
            }
    }
}

extension View {
    func toast() -> some View {
        modifier(ToastModifier())
    }
}

// MARK: - Retryable Error View

/// Error view with retry capability
struct RetryableErrorView: View {
    let title: String
    let message: String
    let error: Error?
    let retryAction: () async -> Void
    
    @State private var isRetrying = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.chartRed.opacity(0.12))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 28))
                    .foregroundColor(.chartRed)
            }
            
            // Title
            Text(title)
                .font(.rajdhaniBold(20))
                .foregroundColor(.white)
                .tracking(1)
            
            // Message
            Text(message)
                .font(.quicksandRegular(14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
            
            // Error details (collapsible)
            if let error = error {
                DisclosureGroup {
                    Text(error.localizedDescription)
                        .font(.firaCode(11))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(8)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Error Details")
                            .font(.quicksandSemiBold(12))
                    }
                    .foregroundColor(.white.opacity(0.4))
                }
                .accentColor(.white.opacity(0.4))
            }
            
            // Retry button
            Button {
                HapticManager.shared.mediumImpact()
                isRetrying = true
                Task {
                    await retryAction()
                    await MainActor.run { isRetrying = false }
                }
            } label: {
                HStack(spacing: 8) {
                    if isRetrying {
                        ProgressView()
                            .tint(.black)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15))
                    }
                    Text(isRetrying ? "RETRYING..." : "TRY AGAIN")
                        .font(.rajdhaniBold(15))
                        .tracking(1)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.potomacYellow)
                .cornerRadius(12)
            }
            .disabled(isRetrying)
        }
        .padding(32)
        .background(Color.white.opacity(0.04))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Offline Banner

/// Banner shown when device is offline
struct OfflineBanner: View {
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var showBanner = false
    
    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 10) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.chartOrange)
                
                Text("You're offline. Some features may be unavailable.")
                    .font(.quicksandSemiBold(13))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(networkMonitor.connectionType.rawValue)
                    .font(.quicksandSemiBold(11))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.chartOrange.opacity(0.15))
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Empty State View

/// Reusable empty state component
struct EmptyStateView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        iconColor: Color = .potomacYellow,
        title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(iconColor.opacity(0.7))
            }
            
            // Text
            VStack(spacing: 8) {
                Text(title)
                    .font(.rajdhaniBold(20))
                    .foregroundColor(.white)
                    .tracking(1)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.quicksandRegular(14))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
            
            // Action button
            if let actionTitle = actionTitle, let action = action {
                Button {
                    HapticManager.shared.lightImpact()
                    action()
                } label: {
                    Text(actionTitle)
                        .font(.quicksandSemiBold(14))
                        .foregroundColor(.potomacYellow)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.potomacYellow.opacity(0.1))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(40)
    }
}

// MARK: - Loading State View

/// Loading state with animated indicator
struct LoadingStateView: View {
    let message: String?
    @State private var rotation: Double = 0
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Animated loader
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.potomacYellow, lineWidth: 3)
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(rotation))
            }
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
            
            if let message = message {
                Text(message)
                    .font(.quicksandRegular(13))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }
}

#Preview("Feedback Views") {
    ZStack {
        Color(hex: "0D0D0D").ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 32) {
                // Retryable error
                RetryableErrorView(
                    title: "Connection Failed",
                    message: "Unable to reach the server. Please check your connection and try again.",
                    error: URLError(.notConnectedToInternet)
                ) {
                    // Retry action
                }
                
                // Empty state
                EmptyStateView(
                    icon: "bubble.left.and.bubble.right",
                    iconColor: .potomacYellow,
                    title: "No Conversations",
                    subtitle: "Start your first conversation with Yang to begin",
                    actionTitle: "New Chat"
                ) {
                    print("New chat tapped")
                }
                
                // Loading state
                LoadingStateView(message: "Loading conversations...")
            }
            .padding(20)
        }
    }
    .preferredColorScheme(.dark)
}