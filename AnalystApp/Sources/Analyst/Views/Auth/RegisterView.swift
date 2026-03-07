import SwiftUI

struct RegisterView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case name, email, password, confirm }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Logo block ──────────────────────────────────────────
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.potomacYellow.opacity(0.12))
                                .frame(width: 130, height: 130)
                                .blur(radius: 30)

                            Image("potomac-icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: Color.potomacYellow.opacity(0.3), radius: 16)
                        }

                        VStack(spacing: 4) {
                            Text("ANALYST")
                                .font(.custom("Rajdhani-Bold", size: 26))
                                .foregroundColor(.white)
                                .tracking(6)
                            Text("BY POTOMAC")
                                .font(.custom("Quicksand-SemiBold", size: 10))
                                .foregroundColor(Color.potomacYellow)
                                .tracking(5)
                        }
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 36)

                    // ── Divider ─────────────────────────────────────────────
                    Divider()
                        .background(Color.white.opacity(0.08))
                        .padding(.horizontal, 32)

                    // ── Form ─────────────────────────────────────────────────
                    VStack(spacing: 20) {
                        Text("CREATE ACCOUNT")
                            .font(.custom("Rajdhani-Bold", size: 22))
                            .foregroundColor(.white)
                            .tracking(3)
                            .padding(.top, 32)

                        // Name (optional)
                        inputField(
                            label: "FULL NAME",
                            icon: "person",
                            placeholder: "John Doe  (optional)",
                            text: $name,
                            field: .name,
                            isName: true
                        )

                        // Email (required)
                        inputField(
                            label: "EMAIL ADDRESS",
                            icon: "envelope",
                            placeholder: "you@example.com",
                            text: $email,
                            field: .email,
                            isEmail: true
                        )

                        // Password (required)
                        secureInputField(
                            label: "PASSWORD",
                            icon: "lock",
                            placeholder: "At least 8 characters",
                            text: $password,
                            showText: $showPassword,
                            field: .password,
                            isNewPassword: true
                        )

                        // Confirm password (required)
                        secureInputField(
                            label: "CONFIRM PASSWORD",
                            icon: "lock.rotation",
                            placeholder: "Repeat password",
                            text: $confirmPassword,
                            showText: $showConfirmPassword,
                            field: .confirm,
                            isNewPassword: true
                        )

                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .font(.custom("Quicksand-Medium", size: 12))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 4)
                        }

                        // Password strength hint
                        if !password.isEmpty {
                            passwordStrengthView
                        }

                        // Create Account button
                        Button {
                            Task { await handleRegister() }
                        } label: {
                            HStack(spacing: 10) {
                                if isLoading {
                                    ProgressView().tint(.black)
                                } else {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 17))
                                }
                                Text("CREATE ACCOUNT")
                                    .font(.custom("Rajdhani-Bold", size: 16))
                                    .tracking(2)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(canSubmit ? Color.potomacYellow : Color.potomacYellow.opacity(0.4))
                            .cornerRadius(12)
                        }
                        .disabled(!canSubmit || isLoading)
                        .padding(.top, 8)

                        // Terms note
                        Text("By creating an account you agree to our Terms of Service and Privacy Policy.")
                            .font(.custom("Quicksand-Regular", size: 10))
                            .foregroundColor(.white.opacity(0.3))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)

                        // Back to login
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .font(.custom("Quicksand-Regular", size: 12))
                                .foregroundColor(.white.opacity(0.4))
                            Button("Sign in") { dismiss() }
                                .font(.custom("Quicksand-SemiBold", size: 12))
                                .foregroundColor(Color.potomacYellow)
                        }
                        .padding(.bottom, 48)
                    }
                    .padding(.horizontal, 32)
                }
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .onTapGesture { focusedField = nil }
    }

    // MARK: - Computed Helpers

    private var canSubmit: Bool {
        !email.isEmpty && password.count >= 8 && !confirmPassword.isEmpty
    }

    private var passwordStrengthView: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(strengthColor(for: index))
                    .frame(height: 3)
            }
            Text(strengthLabel)
                .font(.custom("Quicksand-Medium", size: 10))
                .foregroundColor(strengthColor(for: 0))
                .frame(width: 50, alignment: .trailing)
        }
    }

    private var passwordStrength: Int {
        var score = 0
        if password.count >= 8  { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9!@#$%^&*]", options: .regularExpression) != nil { score += 1 }
        return score
    }

    private var strengthLabel: String {
        switch passwordStrength {
        case 1: return "Weak"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Strong"
        default: return ""
        }
    }

    private func strengthColor(for index: Int) -> Color {
        guard index < passwordStrength else { return Color.white.opacity(0.1) }
        switch passwordStrength {
        case 1: return .red
        case 2: return .orange
        case 3: return Color.potomacYellow
        default: return .green
        }
    }

    // MARK: - Actions

    private func handleRegister() async {
        focusedField = nil
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await auth.register(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                confirmPassword: confirmPassword,
                name: name.trimmingCharacters(in: .whitespaces).isEmpty ? nil : name.trimmingCharacters(in: .whitespaces),
                nickname: nil
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Reusable Field Builders

    @ViewBuilder
    private func inputField(
        label: String,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        isEmail: Bool = false,
        isName: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.custom("Quicksand-SemiBold", size: 10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1)

            TextField(placeholder, text: text)
                .focused($focusedField, equals: field)
                .foregroundColor(.white)
                .font(.custom("Quicksand-Regular", size: 15))
                #if os(iOS)
                .textContentType(isEmail ? .emailAddress : (isName ? .name : .none))
                #if os(iOS)
                .keyboardType(isEmail ? .emailAddress : .default)
                #endif
                .autocapitalization(isEmail ? .none : (isName ? .words : .sentences))
                .autocorrectionDisabled(isEmail)
                #endif
                .padding(14)
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            focusedField == field ? Color.potomacYellow : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        }
    }

    @ViewBuilder
    private func secureInputField(
        label: String,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        showText: Binding<Bool>,
        field: Field,
        isNewPassword: Bool = true
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.custom("Quicksand-SemiBold", size: 10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1)

            HStack {
                Group {
                    if showText.wrappedValue {
                        TextField(placeholder, text: text)
                    } else {
                        SecureField(placeholder, text: text)
                    }
                }
                .focused($focusedField, equals: field)
                .foregroundColor(.white)
                .font(.custom("Quicksand-Regular", size: 15))
                #if os(iOS)
                                .textContentType(isNewPassword ? .newPassword : .password)
                #endif

                Button {
                    showText.wrappedValue.toggle()
                } label: {
                    Image(systemName: showText.wrappedValue ? "eye.slash" : "eye")
                        .foregroundColor(.white.opacity(0.4))
                        .font(.system(size: 15))
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        focusedField == field ? Color.potomacYellow : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environment(AuthViewModel())
    }
    .preferredColorScheme(.dark)
}
