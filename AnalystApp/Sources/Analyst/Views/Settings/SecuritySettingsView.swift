import SwiftUI

/// Security settings view for biometric auth, auto-lock, and privacy controls
struct SecuritySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var biometricAuth = BiometricAuthManager.shared
    @ObservedObject private var autoLock = AutoLockManager.shared
    
    @State private var showPrivacyDashboard = false
    @State private var isTogglingBiometric = false
    
    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()
            
            VStack(spacing: 0) {
                sheetHeader
                Divider().background(Color.white.opacity(0.07))
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Biometric section
                        biometricSection
                        
                        // Auto-lock section
                        if biometricAuth.isEnabled {
                            autoLockSection
                        }
                        
                        // Privacy section
                        privacySection
                        
                        // App protection section
                        appProtectionSection
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
        }
        .sheet(isPresented: $showPrivacyDashboard) {
            PrivacyDashboardView()
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private var sheetHeader: some View {
        HStack {
            Text("SECURITY")
                .font(.custom("Rajdhani-Bold", size: 16))
                .foregroundColor(.white)
                .tracking(3)
            Spacer()
            Button { dismiss() } label: {
                ZStack {
                    Circle().fill(Color.white.opacity(0.08)).frame(width: 30, height: 30)
                    Image(systemName: "xmark").font(.system(size: 12, weight: .semibold)).foregroundColor(.white.opacity(0.5))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }
    
    // MARK: - Biometric Section
    
    @ViewBuilder
    private var biometricSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BIOMETRIC AUTHENTICATION")
                .font(.custom("Quicksand-SemiBold", size: 10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            VStack(spacing: 1) {
                // Biometric toggle
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.potomacYellow.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: biometricAuth.biometricType.iconName)
                            .font(.system(size: 15))
                            .foregroundColor(.potomacYellow)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(biometricAuth.biometricType.name)
                            .font(.custom("Quicksand-SemiBold", size: 14))
                            .foregroundColor(.white)
                        Text(biometricAuth.isAvailable ? "Unlock app with biometrics" : "Not available on this device")
                            .font(.custom("Quicksand-Regular", size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    Spacer()
                    
                    if isTogglingBiometric {
                        ProgressView()
                            .tint(.potomacYellow)
                    } else {
                        Toggle("", isOn: Binding(
                            get: { biometricAuth.isEnabled },
                            set: { newValue in Task { await toggleBiometric(newValue) } }
                        ))
                        .labelsHidden()
                        .tint(.potomacYellow)
                        .disabled(!biometricAuth.isAvailable)
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.04))
                
                if biometricAuth.isEnabled {
                    Divider().background(Color.white.opacity(0.05)).padding(.leading, 44)
                    
                    // Status row
                    HStack {
                        Text("Status")
                            .font(.custom("Quicksand-Regular", size: 13))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(biometricAuth.isUnlocked ? Color.green : Color.potomacYellow)
                                .frame(width: 8, height: 8)
                            Text(biometricAuth.isUnlocked ? "Unlocked" : "Locked")
                                .font(.custom("Quicksand-SemiBold", size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.02))
                }
            }
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
            
            // Info text
            if biometricAuth.isAvailable {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                    Text("When enabled, you'll need to authenticate each time you open the app")
                        .font(.custom("Quicksand-Regular", size: 11))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
    }
    
    // MARK: - Auto-Lock Section
    
    @ViewBuilder
    private var autoLockSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AUTO-LOCK")
                .font(.custom("Quicksand-SemiBold", size: 10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            VStack(spacing: 1) {
                ForEach(AutoLockManager.AutoLockDuration.allCases) { duration in
                    Button {
                        autoLock.duration = duration
                        HapticManager.shared.selection()
                    } label: {
                        HStack {
                            Text(duration.displayText)
                                .font(.custom("Quicksand-SemiBold", size: 14))
                                .foregroundColor(.white)
                            Spacer()
                            if autoLock.duration == duration {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.potomacYellow)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(autoLock.duration == duration ? Color.potomacYellow.opacity(0.08) : Color.clear)
                    }
                    .buttonStyle(.plain)
                    
                    if duration.id != AutoLockManager.AutoLockDuration.allCases.last?.id {
                        Divider().background(Color.white.opacity(0.05)).padding(.leading, 14)
                    }
                }
            }
            .background(Color.white.opacity(0.04))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
        }
    }
    
    // MARK: - Privacy Section
    
    @ViewBuilder
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PRIVACY")
                .font(.custom("Quicksand-SemiBold", size: 10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            VStack(spacing: 1) {
                settingsRow(
                    icon: "shield.checkered",
                    iconColor: Color.potomacYellow,
                    title: "Privacy Dashboard",
                    subtitle: "View and manage your data"
                ) {
                    showPrivacyDashboard = true
                }
                
                Divider().background(Color.white.opacity(0.05)).padding(.leading, 44)
                
                settingsRow(
                    icon: "eye.slash.fill",
                    iconColor: Color(hex: "A78BFA"),
                    title: "Incognito Mode",
                    subtitle: "Don't save messages locally",
                    toggle: true,
                    isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "incognitoMode") },
                        set: { UserDefaults.standard.set($0, forKey: "incognitoMode") }
                    )
                )
            }
            .background(Color.white.opacity(0.04))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
        }
    }
    
    // MARK: - App Protection Section
    
    @ViewBuilder
    private var appProtectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APP PROTECTION")
                .font(.custom("Quicksand-SemiBold", size: 10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            VStack(spacing: 1) {
                settingsRow(
                    icon: "rectangle.dashed.badge.record",
                    iconColor: Color(hex: "F97316"),
                    title: "Screenshot Prevention",
                    subtitle: "Block screenshots in sensitive views",
                    toggle: true,
                    isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "screenshotPrevention") },
                        set: { UserDefaults.standard.set($0, forKey: "screenshotPrevention") }
                    )
                )
                
                Divider().background(Color.white.opacity(0.05)).padding(.leading, 44)
                
                settingsRow(
                    icon: "clipboard.fill",
                    iconColor: Color.potomacTurquoise,
                    title: "Secure Pasteboard",
                    subtitle: "Clear clipboard after 30 seconds",
                    toggle: true,
                    isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "securePasteboard") },
                        set: { UserDefaults.standard.set($0, forKey: "securePasteboard") }
                    )
                )
            }
            .background(Color.white.opacity(0.04))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
        }
    }
    
    // MARK: - Helpers
    
    @ViewBuilder
    private func settingsRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        toggle: Bool = false,
        isOn: Binding<Bool>? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        Button(action: { action?() }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("Quicksand-SemiBold", size: 14))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.custom("Quicksand-Regular", size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Spacer()
                
                if toggle, let isOn = isOn {
                    Toggle("", isOn: isOn)
                        .labelsHidden()
                        .tint(.potomacYellow)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.2))
                }
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }
    
    private func toggleBiometric(_ enable: Bool) async {
        isTogglingBiometric = true
        HapticManager.shared.selection()
        
        if enable {
            _ = await biometricAuth.enable()
        } else {
            biometricAuth.disable()
        }
        
        isTogglingBiometric = false
    }
}

// MARK: - Preview

#Preview {
    SecuritySettingsView()
}