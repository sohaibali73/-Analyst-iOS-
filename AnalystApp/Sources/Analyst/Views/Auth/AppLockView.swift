import SwiftUI

/// View shown when the app is locked and requires biometric authentication
struct AppLockView: View {
    @ObservedObject private var biometricAuth = BiometricAuthManager.shared
    @State private var isAuthenticating = false
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "0D0D0D").ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo and lock icon
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(Color.potomacYellow.opacity(0.08))
                        .frame(width: 160, height: 160)
                        .blur(radius: 40)
                    
                    VStack(spacing: 16) {
                        // App icon
                        Image("potomac-icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        
                        // Lock icon
                        ZStack {
                            Circle()
                                .fill(Color.potomacYellow.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "lock.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.potomacYellow)
                        }
                    }
                }
                .offset(y: animationOffset)
                
                Spacer().frame(height: 32)
                
                // Title
                Text("ANALYST")
                    .font(.custom("Rajdhani-Bold", size: 28))
                    .foregroundColor(.white)
                    .tracking(6)
                
                Text("by Potomac")
                    .font(.custom("Quicksand-SemiBold", size: 11))
                    .foregroundColor(.potomacYellow.opacity(0.6))
                    .tracking(3)
                
                Spacer().frame(height: 48)
                
                // Unlock button
                Button {
                    Task { await authenticate() }
                } label: {
                    HStack(spacing: 12) {
                        if isAuthenticating {
                            ProgressView()
                                .tint(.black)
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: biometricAuth.biometricType.iconName)
                                .font(.system(size: 20))
                            
                            Text("Unlock with \(biometricAuth.biometricType.name)")
                                .font(.custom("Rajdhani-Bold", size: 16))
                                .tracking(1)
                        }
                    }
                    .foregroundColor(.black)
                    .frame(width: 260, height: 54)
                    .background(Color.potomacYellow)
                    .cornerRadius(14)
                }
                .disabled(isAuthenticating)
                .buttonStyle(.plain)
                
                // Error message
                if let error = biometricAuth.lastError {
                    Text(error)
                        .font(.custom("Quicksand-Regular", size: 12))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animationOffset = -5
            }
            // Auto-trigger authentication on appear
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await authenticate()
            }
        }
    }
    
    private func authenticate() async {
        isAuthenticating = true
        await biometricAuth.authenticate(reason: "Unlock Analyst")
        isAuthenticating = false
    }
}

// MARK: - Preview

#Preview {
    AppLockView()
}