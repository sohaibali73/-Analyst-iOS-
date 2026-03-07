import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var isSent = false
    @State private var errorMessage: String?
    @FocusState private var emailFocused: Bool

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────
            Color(hex: "0D0D0D").ignoresSafeArea()

            // Warm amber radial glow at top-centre
            RadialGradient(
                colors: [
                    Color.potomacYellow.opacity(0.12),
                    Color.potomacYellow.opacity(0.04),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.0),
                startRadius: 0,
                endRadius: 350
            )
            .ignoresSafeArea()

            // ── Content ─────────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // ── Logo block ──────────────────────────────
                    logoSection
                        .padding(.top, 60)
                        .padding(.bottom, 40)

                    // ── Divider ──────────────────────────────────
                    Rectangle()
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 1)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 36)

                    // ── Form or success ──────────────────────────
                    if isSent {
                        successSection
                            .padding(.horizontal, 28)
                    } else {
                        formSection
                            .padding(.horizontal, 28)
                    }
                }
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .onTapGesture { emailFocused = false }
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.potomacYellow.opacity(0.10))
                    .frame(width: 120, height: 120)
                    .blur(radius: 24)

                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                Color.potomacYellow.opacity(0.5),
                                Color.potomacYellow.opacity(0.12),
                                Color.potomacYellow.opacity(0.5)
                            ],
                            center: .center
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "lock.rotation")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(Color.potomacYellow)
            }

            VStack(spacing: 5) {
                Text("RESET PASSWORD")
                    .font(.custom("Rajdhani-Bold", size: 26))
                    .foregroundColor(.white)
                    .tracking(5)

                Text("BY POTOMAC ANALYST")
                    .font(.custom("Quicksand-SemiBold", size: 10))
                    .foregroundColor(Color.potomacYellow)
                    .tracking(4)
            }

            Text("We'll send you a link to reset your password")
                .font(.custom("Quicksand-Regular", size: 13))
                .foregroundColor(.white.opacity(0.4))
                .tracking(0.3)
                .padding(.top, 4)
        }
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: 20) {
            // Heading
            VStack(spacing: 4) {
                Text("FORGOT YOUR PASSWORD?")
                    .font(.custom("Rajdhani-Bold", size: 22))
                    .foregroundColor(.white)
                    .tracking(2)

                Text("Enter the email associated with your account")
                    .font(.custom("Quicksand-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.bottom, 4)

            // Email field
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
                    .focused($emailFocused)
                    .foregroundColor(.white)
                    .font(.custom("Quicksand-Regular", size: 15))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(11)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(
                                emailFocused
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
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
            }

            // Send reset link button
            Button {
                Task { await handleSendReset() }
            } label: {
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView().tint(.black).scaleEffect(0.85)
                    } else {
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text("SEND RESET LINK")
                        .font(.custom("Rajdhani-Bold", size: 17))
                        .tracking(2)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(
                    isLoading || email.isEmpty
                        ? Color.potomacYellow.opacity(0.5)
                        : Color.potomacYellow
                )
                .cornerRadius(12)
            }
            .disabled(isLoading || email.isEmpty)
            .padding(.top, 6)

            // Back to login
            HStack(spacing: 4) {
                Text("Remember your password?")
                    .font(.custom("Quicksand-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.35))
                Button("Sign in") { dismiss() }
                    .font(.custom("Quicksand-SemiBold", size: 12))
                    .foregroundColor(Color.potomacYellow)
            }
            .padding(.top, 8)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Success Section

    private var successSection: some View {
        VStack(spacing: 24) {
            // Checkmark
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 42))
                    .foregroundColor(.green)
            }

            VStack(spacing: 8) {
                Text("CHECK YOUR EMAIL")
                    .font(.custom("Rajdhani-Bold", size: 22))
                    .foregroundColor(.white)
                    .tracking(3)

                Text("We sent a password reset link to")
                    .font(.custom("Quicksand-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.45))

                Text(email)
                    .font(.custom("Quicksand-SemiBold", size: 14))
                    .foregroundColor(Color.potomacYellow)
            }

            Text("Didn't receive the email? Check your spam folder\nor make sure the email address is correct.")
                .font(.custom("Quicksand-Regular", size: 12))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 8)

            // Resend button
            Button {
                isSent = false
                errorMessage = nil
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13))
                    Text("Try Again")
                        .font(.custom("Quicksand-SemiBold", size: 13))
                }
                .foregroundColor(Color.potomacYellow)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.potomacYellow.opacity(0.12))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.potomacYellow.opacity(0.25), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Back to login
            Button {
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 13))
                    Text("BACK TO SIGN IN")
                        .font(.custom("Rajdhani-Bold", size: 15))
                        .tracking(2)
                }
                .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, 8)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Actions

    private func handleSendReset() async {
        emailFocused = false
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Validate email
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email address."
            return
        }
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        guard trimmedEmail.range(of: emailRegex, options: .regularExpression) != nil else {
            errorMessage = "Please enter a valid email address."
            return
        }

        do {
            let body: [String: Any] = ["email": trimmedEmail]
            _ = try await APIClient.shared.performRequest(.post, APIEndpoints.Auth.forgotPassword, body: body)
            withAnimation { isSent = true }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
    .preferredColorScheme(.dark)
}
