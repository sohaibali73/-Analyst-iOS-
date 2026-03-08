import SwiftUI

@main
struct AnalystApp: App {
    @State var authViewModel = AuthViewModel()
    @State var tabViewModel = TabViewModel()
    @AppStorage("appTheme") private var appTheme: AppTheme = .dark

    var body: some Scene {
        WindowGroup {
            #if os(watchOS)
            WatchMainView()
                .environment(authViewModel)
                .tint(Color.potomacYellow)
            #else
            RootView()
                .environment(authViewModel)
                .environment(tabViewModel)
                .tint(Color.potomacYellow)
                .preferredColorScheme(appTheme.colorScheme)
            #endif
        }
    }
}

// MARK: - Root View (iOS, macOS, visionOS)

#if !os(watchOS)
struct RootView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var networkMonitor = NetworkMonitor.shared

    #if os(iOS) || os(visionOS)
    @ObservedObject private var biometricAuth = BiometricAuthManager.shared
    #endif

    /// Scene phase for detecting background/foreground transitions
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Offline banner at top
                OfflineBanner()
                    .animation(AnimationProvider.smooth, value: networkMonitor.isConnected)

                // Main content
                Group {
                    if auth.isLoading {
                        SplashView()
                    } else if auth.isAuthenticated {
                        MainTabView()
                    } else {
                        NavigationStack {
                            LoginView()
                        }
                    }
                }
            }
            #if os(iOS) || os(visionOS)
            .trackActivity() // Track user activity for auto-lock
            .overlay {
                // App Lock overlay (shown when locked)
                if auth.isAuthenticated && biometricAuth.isEnabled && !biometricAuth.isUnlocked {
                    AppLockView()
                        .transition(.opacity)
                        .zIndex(1000) // Ensure it's on top
                }
            }
            #endif
        }
        .animation(.easeInOut(duration: 0.4), value: auth.isAuthenticated)
        .animation(.easeInOut(duration: 0.4), value: auth.isLoading)
        #if os(iOS) || os(visionOS)
        .animation(.easeInOut(duration: 0.3), value: biometricAuth.isUnlocked)
        .onChange(of: auth.isAuthenticated) { _, newValue in
            print("🔐 isAuthenticated changed to: \(newValue)")
            if newValue {
                biometricAuth.unlockWithoutAuth()
            } else {
                biometricAuth.lock()
            }
        }
        #endif
        .onChange(of: auth.user) { _, newValue in
            print("🔐 user changed to: \(newValue?.email ?? "nil")")
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
        }
        .toast()
    }

    /// Handle app background/foreground transitions for auto-lock
    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        switch newPhase {
        case .background, .inactive:
            // App going to background
            #if os(iOS) || os(visionOS)
            AutoLockManager.shared.recordActivity()
            #endif

        case .active:
            #if os(iOS) || os(visionOS)
            // App coming to foreground - check if we should lock
            if auth.isAuthenticated && biometricAuth.isEnabled {
                AutoLockManager.shared.forceCheck()
                if AutoLockManager.shared.duration.seconds == 0 {
                    biometricAuth.lock()
                }
            }
            #endif

        @unknown default:
            break
        }
    }
}
#endif

// MARK: - Splash View

struct SplashView: View {
    @State private var shimmerOffset: CGFloat = -60
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.85
    @State private var glowRadius: CGFloat = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Background glow
            RadialGradient(
                colors: [Color.potomacYellow.opacity(0.10), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 200
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                ZStack {
                    // Glow halo
                    Circle()
                        .fill(Color.potomacYellow.opacity(0.12))
                        .frame(width: 140, height: 140)
                        .blur(radius: glowRadius)

                    Image("potomac-icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: Color.potomacYellow.opacity(0.35), radius: 24)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                Spacer().frame(height: 32)

                // Brand text
                VStack(spacing: 6) {
                    Text("ANALYST")
                        .font(.custom("Rajdhani-Bold", size: 32))
                        .foregroundColor(.white)
                        .tracking(8)

                    Text("BY POTOMAC")
                        .font(.custom("Quicksand-SemiBold", size: 11))
                        .foregroundColor(Color.potomacYellow)
                        .tracking(6)
                }
                .opacity(logoOpacity)

                Spacer()

                // Loading bar
                VStack(spacing: 16) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 120, height: 3)

                        Capsule()
                            .fill(Color.potomacYellow)
                            .frame(width: 50, height: 3)
                            .offset(x: shimmerOffset)
                    }
                    .clipped()

                    Text("VERSION 1.0")
                        .font(.custom("Quicksand-Regular", size: 9))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(3)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                logoOpacity = 1
                logoScale = 1
                glowRadius = 40
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                shimmerOffset = 70
            }
        }
    }
}
