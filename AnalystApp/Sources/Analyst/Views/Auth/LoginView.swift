import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case email, password }

    // Feature cards matching the website
    private let features: [(icon: String, title: String, subtitle: String)] = [
        ("bolt.fill",          "AI-Powered Code Generation",    "Generate AFL strategies with natural language"),
        ("chart.line.uptrend.xyaxis", "Advanced Backtest Analysis",      "Visualise and refine your strategy performance"),
        ("lock.shield.fill",   "Enterprise-Grade Security",     "Your data protected with military-grade encryption")
    ]

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────
            Color(red: 0.04, green: 0.04, blue: 0.04)
                .ignoresSafeArea()

            // Warm amber radial glow at top-centre
            RadialGradient(
                colors: [
                    Color.potomacYellow.opacity(0.18),
                    Color.potomacYellow.opacity(0.07),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.0),
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()

            // ── Content ─────────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Hero / Logo ──────────────────────────────
                    heroSection
                        .padding(.top, 64)
                        .padding(.bottom, 36)

                    // ── Feature cards ────────────────────────────
                    featureCardsSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)

                    // ── Divider ──────────────────────────────────
                    Rectangle()
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 1)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 36)

                    // ── Sign-in form ─────────────────────────────
                    formSection
                        .padding(.horizontal, 28)
                        .padding(.bottom, 60)
                }
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .onTapGesture { focusedField = nil }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 14) {
            // Hexagonal-ish logo glow
            ZStack {
                // Outer ambient glow
                Circle()
                    .fill(Color.potomacYellow.opacity(0.10))
                    .frame(width: 140, height: 140)
                    .blur(radius: 28)

                // Inner ring
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                Color.potomacYellow.opacity(0.6),
                                Color.potomacYellow.opacity(0.15),
                                Color.potomacYellow.opacity(0.6)
                            ],
                            center: .center
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 96, height: 96)

                Image("potomac-icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color.potomacYellow.opacity(0.4), radius: 14)
            }

            VStack(spacing: 5) {
                Text("ANALYST")
                    .font(.custom("Rajdhani-Bold", size: 30))
                    .foregroundColor(.white)
                    .tracking(8)

                Text("BY POTOMAC")
                    .font(.custom("Quicksand-SemiBold", size: 10))
                    .foregroundColor(Color.potomacYellow)
                    .tracking(6)
            }

            Text("AI-Powered Trading Intelligence")
                .font(.custom("Quicksand-Regular", size: 13))
                .foregroundColor(.white.opacity(0.45))
                .tracking(0.5)
                .padding(.top, 4)
        }
    }

    // MARK: - Feature Cards Section

    private var featureCardsSection: some View {
        VStack(spacing: 10) {
            ForEach(features, id: \.title) { feature in
                FeatureHighlightCard(
                    icon: feature.icon,
                    title: feature.title,
                    subtitle: feature.subtitle
                )
            }
        }
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: 20) {

            // Heading
            VStack(spacing: 4) {
                Text("WELCOME BACK")
                    .font(.custom("Rajdhani-Bold", size: 24))
                    .foregroundColor(.white)
                    .tracking(3)

                Text("Sign in to continue")
                    .font(.custom("Quicksand-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.bottom, 4)

            // Email
            VStack(alignment: .leading, spacing: 6) {
                Text("EMAIL ADDRESS")
                    .font(.custom("Quicksand-SemiBold", size: 9))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)

                TextField("you@example.com", text: $email)
                    #if os(iOS)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    #endif
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .foregroundColor(.white)
                    .font(.custom("Quicksand-Regular", size: 15))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(11)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(
                                focusedField == .email
                                    ? Color.potomacYellow.opacity(0.8)
                                    : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            }

            // Password
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("PASSWORD")
                        .font(.custom("Quicksand-SemiBold", size: 9))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1.5)
                    Spacer()
                    Button("Forgot password?") {}
                        .font(.custom("Quicksand-SemiBold", size: 11))
                        .foregroundColor(Color.potomacYellow.opacity(0.8))
                }

                HStack {
                    Group {
                        if showPassword {
                            TextField("••••••••", text: $password)
                        } else {
                            SecureField("••••••••", text: $password)
                        }
                    }
                    .focused($focusedField, equals: .password)
                    .foregroundColor(.white)
                    .font(.custom("Quicksand-Regular", size: 15))

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.white.opacity(0.35))
                            .font(.system(size: 15))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.05))
                .cornerRadius(11)
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(
                            focusedField == .password
                                ? Color.potomacYellow.opacity(0.8)
                                : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
            }

            // Error message
            if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                    Text(error)
                        .font(.custom("Quicksand-Medium", size: 12))
                }
                .foregroundColor(Color.error)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
            }

            // Sign In button
            Button {
                Task { await handleLogin() }
            } label: {
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView().tint(.black).scaleEffect(0.85)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Text("SIGN IN")
                        .font(.custom("Rajdhani-Bold", size: 17))
                        .tracking(2)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(
                    isLoading || email.isEmpty || password.isEmpty
                        ? Color.potomacYellow.opacity(0.5)
                        : Color.potomacYellow
                )
                .cornerRadius(12)
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            .padding(.top, 6)

            // Face ID
            if auth.canUseBiometrics {
                Button {
                    Task { await handleBiometric() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "faceid")
                            .font(.system(size: 16))
                        Text("Sign in with Face ID")
                            .font(.custom("Quicksand-Medium", size: 13))
                    }
                    .foregroundColor(.white.opacity(0.45))
                }
                .padding(.top, 4)
            }

            // Register
            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .font(.custom("Quicksand-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.35))
                NavigationLink("Create one") { RegisterView() }
                    .font(.custom("Quicksand-SemiBold", size: 12))
                    .foregroundColor(Color.potomacYellow)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Actions

    private func handleLogin() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await auth.login(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleBiometric() async {
        do {
            try await auth.authenticateWithBiometrics()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Feature Highlight Card

private struct FeatureHighlightCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            // Amber icon circle
            ZStack {
                Circle()
                    .fill(Color.potomacYellow.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.potomacYellow)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.custom("Rajdhani-SemiBold", size: 15))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.custom("Quicksand-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.45))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LoginView()
            .environment(AuthViewModel())
    }
    .preferredColorScheme(.dark)
}
