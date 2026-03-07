import SwiftUI

struct SettingsView: View {
    @Environment(AuthViewModel.self) private var auth
    @AppStorage("appTheme") private var appTheme: AppTheme = .dark
    @AppStorage("notifyHaptic") private var hapticEnabled: Bool = true
    
    // Sheet routing
    @State private var showProfileSheet = false
    @State private var showAPIKeysSheet = false
    @State private var showPasswordSheet = false
    @State private var showAppearance = false
    @State private var showNotifications = false
    @State private var showDataManagement = false
    @State private var showSecurity = false
    @State private var showAbout = false
    @State private var showVoiceSettings = false
    @State private var showAIPreferences = false
    @State private var showSignOutConfirm = false

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 0) {
                settingsNavBar
                Divider().background(Color.white.opacity(0.07))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Profile Header Card
                        profileHeaderCard
                            .animatedEntry()
                        
                        // AI Preferences Section
                        settingsSection(
                            title: "AI PREFERENCES",
                            icon: "brain.head.profile",
                            iconColor: .potomacTurquoise,
                            rows: [
                                SettingsRowData(icon: "slider.horizontal.3", iconColor: .potomacTurquoise, title: "Response Style", subtitle: "Balanced") {
                                    showAIPreferences = true
                                },
                                SettingsRowData(icon: "textformat", iconColor: Color(hex: "A78BFA"), title: "Auto-name Conversations", subtitle: hapticEnabled ? "On" : "Off") {
                                    // Toggle setting
                                },
                            ]
                        )
                        .animatedEntry(delay: 0.1)

                        // Account Section
                        settingsSection(
                            title: "ACCOUNT",
                            icon: "person.circle.fill",
                            iconColor: Color(hex: "60A5FA"),
                            rows: [
                                SettingsRowData(icon: "person.fill", iconColor: Color(hex: "60A5FA"), title: "Edit Profile", subtitle: auth.user?.name ?? auth.user?.email ?? "") {
                                    showProfileSheet = true
                                },
                                SettingsRowData(icon: "key.fill", iconColor: .potomacYellow, title: "API Keys", subtitle: "Claude & Tavily") {
                                    showAPIKeysSheet = true
                                },
                                SettingsRowData(icon: "lock.shield.fill", iconColor: Color(hex: "34D399"), title: "Change Password", subtitle: "Update your password") {
                                    showPasswordSheet = true
                                },
                            ]
                        )
                        .animatedEntry(delay: 0.15)

                        // Preferences Section
                        settingsSection(
                            title: "PREFERENCES",
                            icon: "gearshape.fill",
                            iconColor: .white.opacity(0.5),
                            rows: [
                                SettingsRowData(icon: "paintbrush.fill", iconColor: Color(hex: "A78BFA"), title: "Appearance", subtitle: appTheme.displayName) {
                                    showAppearance = true
                                },
                                SettingsRowData(icon: "speaker.wave.2.fill", iconColor: .potomacTurquoise, title: "Voice Settings", subtitle: "Rate, voice & silence") {
                                    showVoiceSettings = true
                                },
                                SettingsRowData(icon: "bell.fill", iconColor: Color(hex: "F97316"), title: "Notifications", subtitle: "Alerts & feedback") {
                                    showNotifications = true
                                },
                                SettingsRowData(icon: "internaldrive.fill", iconColor: Color(hex: "8B5CF6"), title: "Data & Storage", subtitle: "Cache, history & export") {
                                    showDataManagement = true
                                },
                            ]
                        )
                        .animatedEntry(delay: 0.2)

                        // Security Section
                        settingsSection(
                            title: "SECURITY",
                            icon: "lock.shield",
                            iconColor: .potomacYellow,
                            rows: [
                                SettingsRowData(icon: "faceid", iconColor: .potomacYellow, title: "Security & Privacy", subtitle: "Face ID, auto-lock, data controls") {
                                    showSecurity = true
                                },
                            ]
                        )
                        .animatedEntry(delay: 0.25)

                        // Support Section
                        settingsSection(
                            title: "SUPPORT",
                            icon: "questionmark.circle.fill",
                            iconColor: Color(hex: "60A5FA"),
                            rows: [
                                SettingsRowData(icon: "questionmark.circle.fill", iconColor: Color(hex: "60A5FA"), title: "Help & FAQ", subtitle: nil) {
                                    openURL("https://potomac.ai/support")
                                },
                                SettingsRowData(icon: "envelope.fill", iconColor: .potomacTurquoise, title: "Contact Support", subtitle: nil) {
                                    openURL("mailto:support@potomac.ai")
                                },
                                SettingsRowData(icon: "info.circle.fill", iconColor: .white.opacity(0.5), title: "About", subtitle: "Version 1.0.0") {
                                    showAbout = true
                                },
                            ]
                        )
                        .animatedEntry(delay: 0.3)

                        appInfoSection
                            .animatedEntry(delay: 0.35)

                        signOutButton
                            .padding(.horizontal, 24)
                            .padding(.bottom, 120)
                            .animatedEntry(delay: 0.4)
                    }
                    .padding(.top, 16)
                }
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .sheet(isPresented: $showProfileSheet) {
            EditProfileSheet()
        }
        .sheet(isPresented: $showAPIKeysSheet) {
            APIKeysSheet()
        }
        .sheet(isPresented: $showPasswordSheet) {
            ChangePasswordSheet()
        }
        .sheet(isPresented: $showAppearance) {
            AppearanceSettingsView()
        }
        .sheet(isPresented: $showVoiceSettings) {
            VoiceSettingsSheet()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showDataManagement) {
            DataManagementView()
        }
        .sheet(isPresented: $showSecurity) {
            SecuritySettingsView()
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .sheet(isPresented: $showAIPreferences) {
            AIPreferencesSheet()
        }
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirm) {
            Button("Sign Out", role: .destructive) {
                Task { await auth.logout() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    // MARK: - Nav Bar
    @ViewBuilder
    private var settingsNavBar: some View {
        HStack {
            Spacer()
            Text("SETTINGS")
                .font(.custom("Rajdhani-Bold", size: 16))
                .foregroundColor(.white)
                .tracking(3)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Profile Header Card
    @ViewBuilder
    private var profileHeaderCard: some View {
        Button {
            showProfileSheet = true
        } label: {
            HStack(spacing: 16) {
                // Avatar with gradient ring
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.potomacYellow, .potomacTurquoise],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 64, height: 64)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.potomacYellow, .potomacYellowDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Text(auth.user?.initials ?? "P")
                        .font(.custom("Rajdhani-Bold", size: 22))
                        .foregroundColor(.black)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(auth.user?.displayName ?? "Trader")
                        .font(.custom("Rajdhani-Bold", size: 20))
                        .foregroundColor(.white)
                    
                    Text(auth.user?.email ?? "")
                        .font(.custom("Quicksand-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.4))
                    
                    // Member badge
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.potomacYellow)
                        Text("Potomac AI")
                            .font(.custom("Quicksand-SemiBold", size: 10))
                            .foregroundColor(.potomacYellow)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.potomacYellow.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(16)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.potomacYellow.opacity(0.2), .potomacTurquoise.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .overlay(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.potomacYellow.opacity(0.15))
                    .frame(height: 1)
                    .blur(radius: 6)
                    .padding(.horizontal, 8)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }

    // MARK: - Settings Section
    @ViewBuilder
    private func settingsSection(title: String, icon: String, iconColor: Color, rows: [SettingsRowData]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.custom("Quicksand-SemiBold", size: 10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)
            }
            .padding(.horizontal, 24)

            // Section Content
            VStack(spacing: 1) {
                ForEach(rows) { row in
                    PremiumSettingsRow(data: row)
                    if row.id != rows.last?.id {
                        Divider()
                            .background(Color.white.opacity(0.05))
                            .padding(.leading, 66)
                    }
                }
            }
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .padding(.horizontal, 24)
        }
    }

    // MARK: - App Info
    @ViewBuilder
    private var appInfoSection: some View {
        VStack(spacing: 8) {
            Image("potomac-icon")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .shadow(color: .potomacYellow.opacity(0.2), radius: 8)

            Text("Analyst by Potomac")
                .font(.custom("Rajdhani-Bold", size: 14))
                .foregroundColor(.white.opacity(0.5))
                .tracking(1)

            Text("Break the status quo.")
                .font(.custom("Quicksand-Regular", size: 11))
                .foregroundColor(.potomacYellow.opacity(0.5))
                .italic()
            
            Text("Version 1.0.0")
                .font(.custom("Quicksand-Regular", size: 11))
                .foregroundColor(.white.opacity(0.2))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Sign Out
    @ViewBuilder
    private var signOutButton: some View {
        Button {
            showSignOutConfirm = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15))
                Text("SIGN OUT")
                    .font(.custom("Rajdhani-Bold", size: 15))
                    .tracking(2)
            }
            .foregroundColor(.chartRed)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color.chartRed.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.chartRed.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.pressable)
    }

    private func openURL(_ urlString: String) {
        #if os(iOS)
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

// MARK: - Premium Settings Row

struct PremiumSettingsRow: View {
    let data: SettingsRowData
    @State private var isPressed = false
    
    var body: some View {
        Button(action: data.action) {
            HStack(spacing: 14) {
                // Icon with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [data.iconColor.opacity(0.2), data.iconColor.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(data.iconColor.opacity(0.3), lineWidth: 0.5)
                        )
                    
                    Image(systemName: data.icon)
                        .font(.system(size: 15))
                        .foregroundColor(data.iconColor)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(data.title)
                        .font(.custom("Quicksand-SemiBold", size: 14))
                        .foregroundColor(.white)
                    if let sub = data.subtitle, !sub.isEmpty {
                        Text(sub)
                            .font(.custom("Quicksand-Regular", size: 11))
                            .foregroundColor(.white.opacity(0.35))
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isPressed ? Color.white.opacity(0.03) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Settings Row Data

struct SettingsRowData: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let action: () -> Void
}

// MARK: - Voice Settings Sheet

struct VoiceSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("voiceRate") private var voiceRate: Double = 0.5
    @AppStorage("autoDetectSilence") private var autoDetectSilence: Bool = true
    @AppStorage("silenceThreshold") private var silenceThreshold: Double = 1.5
    
    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()
            
            VStack(spacing: 0) {
                sheetHeader(title: "VOICE SETTINGS") { dismiss() }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Voice Rate
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("SPEECH RATE")
                                    .font(.quicksandSemiBold(10))
                                    .foregroundColor(.white.opacity(0.4))
                                    .tracking(1.5)
                                
                                Spacer()
                                
                                Text(voiceRate < 0.33 ? "Slow" : voiceRate < 0.66 ? "Normal" : "Fast")
                                    .font(.quicksandSemiBold(12))
                                    .foregroundColor(.potomacYellow)
                            }
                            
                            Slider(value: $voiceRate, in: 0...1)
                                .tint(.potomacYellow)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(12)
                        
                        // Auto-detect Silence
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("AUTO-DETECT SILENCE")
                                        .font(.quicksandSemiBold(10))
                                        .foregroundColor(.white.opacity(0.4))
                                        .tracking(1.5)
                                    
                                    Text("Automatically stop listening when you stop speaking")
                                        .font(.quicksandRegular(12))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $autoDetectSilence)
                                    .tint(.potomacYellow)
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(12)
                        
                        // Silence Threshold
                        if autoDetectSilence {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("SILENCE THRESHOLD")
                                        .font(.quicksandSemiBold(10))
                                        .foregroundColor(.white.opacity(0.4))
                                        .tracking(1.5)
                                    
                                    Spacer()
                                    
                                    Text(String(format: "%.1fs", silenceThreshold))
                                        .font(.quicksandSemiBold(12))
                                        .foregroundColor(.potomacYellow)
                                }
                                
                                Slider(value: $silenceThreshold, in: 0.5...3.0)
                                    .tint(.potomacYellow)
                                
                                Text("How long to wait before stopping")
                                    .font(.quicksandRegular(11))
                                    .foregroundColor(.white.opacity(0.25))
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(12)
                        }
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
        }
    }
}

// MARK: - AI Preferences Sheet

struct AIPreferencesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("aiResponseLength") private var responseLength: ResponseLength = .balanced
    @AppStorage("aiTone") private var tone: AITone = .professional
    
    enum ResponseLength: String, CaseIterable {
        case concise = "Concise"
        case balanced = "Balanced"
        case detailed = "Detailed"
    }
    
    enum AITone: String, CaseIterable {
        case professional = "Professional"
        case casual = "Casual"
        case technical = "Technical"
    }
    
    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()
            
            VStack(spacing: 0) {
                sheetHeader(title: "AI PREFERENCES") { dismiss() }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Response Length
                        VStack(alignment: .leading, spacing: 12) {
                            Text("RESPONSE LENGTH")
                                .font(.quicksandSemiBold(10))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1.5)
                            
                            HStack(spacing: 8) {
                                ForEach(ResponseLength.allCases, id: \.self) { length in
                                    Button {
                                        responseLength = length
                                        HapticManager.shared.lightImpact()
                                    } label: {
                                        Text(length.rawValue)
                                            .font(.quicksandSemiBold(13))
                                            .foregroundColor(responseLength == length ? .black : .white.opacity(0.5))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(responseLength == length ? Color.potomacYellow : Color.white.opacity(0.05))
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(12)
                        
                        // Tone
                        VStack(alignment: .leading, spacing: 12) {
                            Text("RESPONSE TONE")
                                .font(.quicksandSemiBold(10))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1.5)
                            
                            VStack(spacing: 8) {
                                ForEach(AITone.allCases, id: \.self) { t in
                                    Button {
                                        tone = t
                                        HapticManager.shared.lightImpact()
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(t.rawValue)
                                                    .font(.quicksandSemiBold(14))
                                                    .foregroundColor(tone == t ? .potomacYellow : .white)
                                                
                                                Text(toneDescription(t))
                                                    .font(.quicksandRegular(11))
                                                    .foregroundColor(.white.opacity(0.3))
                                            }
                                            
                                            Spacer()
                                            
                                            if tone == t {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.potomacYellow)
                                            }
                                        }
                                        .padding(12)
                                        .background(tone == t ? Color.potomacYellow.opacity(0.08) : Color.white.opacity(0.03))
                                        .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(12)
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
        }
    }
    
    private func toneDescription(_ tone: AITone) -> String {
        switch tone {
        case .professional: return "Formal and business-like"
        case .casual: return "Friendly and conversational"
        case .technical: return "Detailed with technical terms"
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()
            
            VStack(spacing: 0) {
                sheetHeader(title: "ABOUT") { dismiss() }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo and version
                        VStack(spacing: 12) {
                            Image("potomac-icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: .potomacYellow.opacity(0.3), radius: 16)
                            
                            Text("Analyst")
                                .font(.rajdhaniBold(28))
                                .foregroundColor(.white)
                                .tracking(2)
                            
                            Text("Version 1.0.0 (Build 1)")
                                .font(.quicksandRegular(13))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.top, 20)
                        
                        // Description
                        Text("Analyst by Potomac is your AI-powered trading assistant. Generate AFL strategies, analyze markets, and make informed decisions with Yang.")
                            .font(.quicksandRegular(14))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 24)
                        
                        // Links
                        VStack(spacing: 12) {
                            AboutLinkRow(icon: "doc.text.fill", title: "Privacy Policy", color: Color(hex: "60A5FA")) {
                                // Open privacy policy
                            }
                            
                            AboutLinkRow(icon: "doc.text.fill", title: "Terms of Service", color: .potomacTurquoise) {
                                // Open terms
                            }
                            
                            AboutLinkRow(icon: "star.fill", title: "Rate on App Store", color: .potomacYellow) {
                                // Open App Store
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Credits
                        VStack(spacing: 8) {
                            Text("Made with ❤️ by Potomac AI")
                                .font(.quicksandSemiBold(12))
                                .foregroundColor(.white.opacity(0.4))
                            
                            Text("© 2025 Potomac AI. All rights reserved.")
                                .font(.quicksandRegular(11))
                                .foregroundColor(.white.opacity(0.25))
                        }
                        .padding(.top, 20)
                        
                        Spacer().frame(height: 40)
                    }
                }
            }
        }
    }
}

// MARK: - About Link Row

struct AboutLinkRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.quicksandSemiBold(14))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.25))
            }
            .padding(12)
            .background(isPressed ? Color.white.opacity(0.05) : Color.white.opacity(0.03))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Shared Sheet Components

@ViewBuilder
private func sheetHeader(title: String, onClose: @escaping () -> Void) -> some View {
    HStack {
        Text(title)
            .font(.custom("Rajdhani-Bold", size: 16))
            .foregroundColor(.white)
            .tracking(3)
        Spacer()
        Button(action: onClose) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 30, height: 30)
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .buttonStyle(.pressable)
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 18)
    Divider().background(Color.white.opacity(0.07))
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(AuthViewModel())
        .preferredColorScheme(.dark)
}