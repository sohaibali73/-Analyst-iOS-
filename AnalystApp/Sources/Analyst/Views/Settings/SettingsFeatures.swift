import SwiftUI

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    @AppStorage("appTheme") private var theme: AppTheme = .dark
    @AppStorage("accentColor") private var accentColorName: String = "gold"
    @AppStorage("fontSize") private var fontSize: FontSizePreference = .medium
    @AppStorage("compactMode") private var compactMode = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D0D").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Theme
                        themeSection
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        
                        // Accent color
                        accentSection
                            .padding(.horizontal, 20)
                        
                        // Font size
                        fontSizeSection
                            .padding(.horizontal, 20)
                        
                        // Compact mode
                        compactSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("APPEARANCE")
                        .font(.rajdhaniBold(14))
                        .foregroundColor(.white)
                        .tracking(2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.potomacYellow)
                }
            }
        }
    }
    
    // MARK: - Theme Section
    @ViewBuilder
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("THEME")
                .font(.quicksandSemiBold(10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            HStack(spacing: 10) {
                ForEach(AppTheme.allCases, id: \.self) { themeOption in
                    Button {
                        theme = themeOption
                        HapticManager.shared.lightImpact()
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(themeOption.previewColor)
                                    .frame(height: 48)
                                Image(systemName: themeOption.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(themeOption == .dark ? .white : .black)
                            }
                            
                            Text(themeOption.rawValue)
                                .font(.quicksandSemiBold(11))
                                .foregroundColor(theme == themeOption ? .potomacYellow : .white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(theme == themeOption ? Color.potomacYellow.opacity(0.1) : Color.white.opacity(0.03))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme == themeOption ? Color.potomacYellow.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Accent Section
    @ViewBuilder
    private var accentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACCENT COLOR")
                .font(.quicksandSemiBold(10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            HStack(spacing: 12) {
                ForEach(AccentColorOption.allCases, id: \.self) { option in
                    Button {
                        accentColorName = option.rawValue
                        HapticManager.shared.lightImpact()
                    } label: {
                        Circle()
                            .fill(option.color)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: accentColorName == option.rawValue ? 2 : 0)
                            )
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .opacity(accentColorName == option.rawValue ? 1 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Font Size Section
    @ViewBuilder
    private var fontSizeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TEXT SIZE")
                    .font(.quicksandSemiBold(10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)
                Spacer()
                Text(fontSize.rawValue)
                    .font(.quicksandSemiBold(11))
                    .foregroundColor(.potomacYellow)
            }
            
            Picker("", selection: $fontSize) {
                ForEach(FontSizePreference.allCases, id: \.self) { size in
                    Text(size.rawValue).tag(size)
                }
            }
            .pickerStyle(.segmented)
            
            // Preview
            Text("The quick brown fox jumps over the lazy dog")
                .font(.quicksandRegular(fontSize.previewSize))
                .foregroundColor(.white.opacity(0.6))
                .padding(12)
                .background(Color.white.opacity(0.03))
                .cornerRadius(8)
        }
    }
    
    // MARK: - Compact Section
    @ViewBuilder
    private var compactSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $compactMode) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Compact Mode")
                        .font(.quicksandSemiBold(14))
                        .foregroundColor(.white)
                    Text("Reduce spacing and padding for more content")
                        .font(.quicksandRegular(11))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .toggleStyle(.switch)
            .tint(.potomacYellow)
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

// MARK: - Accent Color Option

enum AccentColorOption: String, CaseIterable {
    case gold
    case blue
    case green
    case purple
    case red
    
    var color: Color {
        switch self {
        case .gold: return .potomacYellow
        case .blue: return .chartBlue
        case .green: return .chartGreen
        case .purple: return Color(hex: "A78BFA")
        case .red: return .chartRed
        }
    }
}

// MARK: - Font Size Preference

enum FontSizePreference: String, CaseIterable, Codable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    
    var previewSize: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 14
        case .large: return 16
        }
    }
}

// MARK: - Notification Settings

struct NotificationSettingsView: View {
    @AppStorage("notifyChat") private var notifyChat = true
    @AppStorage("notifyAFL") private var notifyAFL = true
    @AppStorage("notifyBacktest") private var notifyBacktest = true
    @AppStorage("notifyMarket") private var notifyMarket = false
    @AppStorage("notifySound") private var notifySound = true
    @AppStorage("notifyHaptic") private var notifyHaptic = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D0D").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Activity notifications
                        activitySection
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        
                        // Feedback
                        feedbackSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("NOTIFICATIONS")
                        .font(.rajdhaniBold(14))
                        .foregroundColor(.white)
                        .tracking(2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.potomacYellow)
                }
            }
        }
    }
    
    @ViewBuilder
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACTIVITY ALERTS")
                .font(.quicksandSemiBold(10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            NotificationToggle(title: "Chat Responses", subtitle: "When Yang finishes responding", icon: "message.fill", color: .potomacYellow, isOn: $notifyChat)
            NotificationToggle(title: "AFL Generation", subtitle: "When code generation completes", icon: "chevron.left.forwardslash.chevron.right", color: .potomacTurquoise, isOn: $notifyAFL)
            NotificationToggle(title: "Backtest Results", subtitle: "When analysis is ready", icon: "chart.line.uptrend.xyaxis", color: .chartGreen, isOn: $notifyBacktest)
            NotificationToggle(title: "Market Alerts", subtitle: "Price and volume alerts", icon: "bell.badge.fill", color: .chartOrange, isOn: $notifyMarket)
        }
    }
    
    @ViewBuilder
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FEEDBACK")
                .font(.quicksandSemiBold(10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            NotificationToggle(title: "Sound", subtitle: "Play sounds for actions", icon: "speaker.wave.2.fill", color: .white.opacity(0.6), isOn: $notifySound)
            NotificationToggle(title: "Haptics", subtitle: "Vibration feedback", icon: "iphone.radiowaves.left.and.right", color: .white.opacity(0.6), isOn: $notifyHaptic)
        }
    }
}

// MARK: - Notification Toggle

struct NotificationToggle: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.quicksandSemiBold(13))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.quicksandRegular(10))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .toggleStyle(.switch)
        .tint(.potomacYellow)
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var nickname: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D0D").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("NAME")
                                .font(.quicksandSemiBold(10))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1.5)
                            TextField("Your name", text: $name)
                                .font(.quicksandRegular(14))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("NICKNAME")
                                .font(.quicksandSemiBold(10))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1.5)
                            TextField("Display nickname", text: $nickname)
                                .font(.quicksandRegular(14))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.quicksandRegular(12))
                                .foregroundColor(.chartRed)
                        }

                        Button {
                            Task { await saveProfile() }
                        } label: {
                            HStack(spacing: 8) {
                                if isSaving { ProgressView().tint(.black) }
                                Text("Save Changes")
                                    .font(.quicksandSemiBold(14))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.potomacYellow)
                            .cornerRadius(12)
                        }
                        .disabled(isSaving)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("EDIT PROFILE").font(.rajdhaniBold(14)).foregroundColor(.white).tracking(2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.potomacYellow)
                }
            }
            .onAppear {
                name = auth.user?.name ?? ""
                nickname = auth.user?.nickname ?? ""
            }
        }
    }

    @MainActor
    private func saveProfile() async {
        isSaving = true
        errorMessage = nil
        do {
            try await auth.updateProfile(
                name: name.isEmpty ? nil : name,
                nickname: nickname.isEmpty ? nil : nickname
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

// MARK: - API Keys Sheet

struct APIKeysSheet: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var claudeKey: String = ""
    @State private var tavilyKey: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D0D").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("CLAUDE API KEY")
                                    .font(.quicksandSemiBold(10))
                                    .foregroundColor(.white.opacity(0.4))
                                    .tracking(1.5)
                                Spacer()
                                if auth.user?.hasClaudeApiKey == true {
                                    Text("Configured ✓")
                                        .font(.quicksandSemiBold(10))
                                        .foregroundColor(.chartGreen)
                                }
                            }
                            SecureField("sk-ant-...", text: $claudeKey)
                                .font(.quicksandRegular(14))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                            Text("Leave blank to keep current key")
                                .font(.quicksandRegular(10))
                                .foregroundColor(.white.opacity(0.25))
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("TAVILY API KEY")
                                    .font(.quicksandSemiBold(10))
                                    .foregroundColor(.white.opacity(0.4))
                                    .tracking(1.5)
                                Spacer()
                                if auth.user?.hasTavilyApiKey == true {
                                    Text("Configured ✓")
                                        .font(.quicksandSemiBold(10))
                                        .foregroundColor(.chartGreen)
                                }
                            }
                            SecureField("tvly-...", text: $tavilyKey)
                                .font(.quicksandRegular(14))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                            Text("Leave blank to keep current key")
                                .font(.quicksandRegular(10))
                                .foregroundColor(.white.opacity(0.25))
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.quicksandRegular(12))
                                .foregroundColor(.chartRed)
                        }

                        Button {
                            Task { await saveKeys() }
                        } label: {
                            HStack(spacing: 8) {
                                if isSaving { ProgressView().tint(.black) }
                                Text("Save Keys")
                                    .font(.quicksandSemiBold(14))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.potomacYellow)
                            .cornerRadius(12)
                        }
                        .disabled(isSaving)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("API KEYS").font(.rajdhaniBold(14)).foregroundColor(.white).tracking(2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.potomacYellow)
                }
            }
        }
    }

    @MainActor
    private func saveKeys() async {
        isSaving = true
        errorMessage = nil
        do {
            try await auth.updateAPIKeys(
                claudeKey: claudeKey.isEmpty ? nil : claudeKey,
                tavilyKey: tavilyKey.isEmpty ? nil : tavilyKey
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

// MARK: - Change Password Sheet

struct ChangePasswordSheet: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D0D").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CURRENT PASSWORD")
                                .font(.quicksandSemiBold(10))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1.5)
                            SecureField("Enter current password", text: $currentPassword)
                                .font(.quicksandRegular(14))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("NEW PASSWORD")
                                .font(.quicksandSemiBold(10))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1.5)
                            SecureField("Minimum 8 characters", text: $newPassword)
                                .font(.quicksandRegular(14))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("CONFIRM PASSWORD")
                                .font(.quicksandSemiBold(10))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1.5)
                            SecureField("Repeat new password", text: $confirmPassword)
                                .font(.quicksandRegular(14))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.quicksandRegular(12))
                                .foregroundColor(.chartRed)
                        }

                        Button {
                            Task { await changePassword() }
                        } label: {
                            HStack(spacing: 8) {
                                if isSaving { ProgressView().tint(.black) }
                                Text("Change Password")
                                    .font(.quicksandSemiBold(14))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(canSubmit ? Color.potomacYellow : Color.potomacYellow.opacity(0.5))
                            .cornerRadius(12)
                        }
                        .disabled(!canSubmit || isSaving)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("CHANGE PASSWORD").font(.rajdhaniBold(14)).foregroundColor(.white).tracking(2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.potomacYellow)
                }
            }
        }
    }

    private var canSubmit: Bool {
        !currentPassword.isEmpty && newPassword.count >= 8 && newPassword == confirmPassword
    }

    @MainActor
    private func changePassword() async {
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        isSaving = true
        errorMessage = nil
        do {
            try await auth.changePassword(current: currentPassword, new: newPassword)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

// MARK: - Data Management View

struct DataManagementView: View {
    @State private var showClearCache = false
    @State private var showClearHistory = false
    @State private var showDeleteAccount = false
    @State private var cacheSize: String = "Calculating..."
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D0D").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Storage info
                        storageSection
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        
                        // Actions
                        actionsSection
                            .padding(.horizontal, 20)
                        
                        // Danger zone
                        dangerSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("DATA & STORAGE")
                        .font(.rajdhaniBold(14))
                        .foregroundColor(.white)
                        .tracking(2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.potomacYellow)
                }
            }
            .confirmationDialog("Clear Cache", isPresented: $showClearCache) {
                Button("Clear Cache", role: .destructive) {
                    Task {
                        await CacheManager.shared.clear()
                        cacheSize = "0 items"
                        HapticManager.shared.success()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Clear Chat History", isPresented: $showClearHistory) {
                Button("Clear All History", role: .destructive) {
                    HapticManager.shared.success()
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Delete Account", isPresented: $showDeleteAccount) {
                Button("Delete Account", role: .destructive) { }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account and all data. This cannot be undone.")
            }
            .task {
                let stats = await CacheManager.shared.stats()
                cacheSize = "\(stats.itemCount) items"
            }
        }
    }
    
    @ViewBuilder
    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STORAGE")
                .font(.quicksandSemiBold(10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            HStack(spacing: 16) {
                StorageItem(label: "Cache", value: cacheSize, icon: "internaldrive", color: .potomacYellow)
                StorageItem(label: "Documents", value: "—", icon: "doc.fill", color: .chartBlue)
                StorageItem(label: "History", value: "—", icon: "clock.fill", color: .chartGreen)
            }
        }
    }
    
    @ViewBuilder
    private var actionsSection: some View {
        VStack(spacing: 8) {
            DataActionRow(title: "Clear Cache", subtitle: "Remove cached API responses", icon: "trash", color: .chartOrange) {
                showClearCache = true
            }
            
            DataActionRow(title: "Clear Chat History", subtitle: "Delete all conversations", icon: "message.badge.fill", color: .chartRed) {
                showClearHistory = true
            }
            
            DataActionRow(title: "Export Data", subtitle: "Download all your data", icon: "square.and.arrow.up", color: .chartBlue) {
                // Export action
            }
        }
    }
    
    @ViewBuilder
    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DANGER ZONE")
                .font(.quicksandSemiBold(10))
                .foregroundColor(.chartRed.opacity(0.6))
                .tracking(1.5)
            
            Button {
                showDeleteAccount = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.xmark")
                        .font(.system(size: 16))
                        .foregroundColor(.chartRed)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delete Account")
                            .font(.quicksandSemiBold(14))
                            .foregroundColor(.chartRed)
                        Text("Permanently delete your account and all data")
                            .font(.quicksandRegular(11))
                            .foregroundColor(.chartRed.opacity(0.6))
                    }
                    
                    Spacer()
                }
                .padding(14)
                .background(Color.chartRed.opacity(0.08))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.chartRed.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Storage Item

struct StorageItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(value)
                .font(.quicksandSemiBold(12))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.quicksandRegular(9))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }
}

// MARK: - Data Action Row

struct DataActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.quicksandSemiBold(13))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.quicksandRegular(10))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(12)
            .background(Color.white.opacity(0.03))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

