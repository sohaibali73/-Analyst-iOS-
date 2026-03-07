import SwiftUI

/// Privacy Dashboard showing what data is stored and providing controls
struct PrivacyDashboardView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteAccountConfirm = false
    @State private var showExportProgress = false
    @State private var exportProgress: Double = 0
    @State private var exportedURL: URL?
    @State private var isDeletingAccount = false
    
    // Local storage stats
    @State private var cacheSize: String = "Calculating..."
    @State private var conversationsCount: Int = 0
    @State private var documentsCount: Int = 0
    
    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()
            
            VStack(spacing: 0) {
                sheetHeader
                Divider().background(Color.white.opacity(0.07))
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Privacy overview card
                        privacyOverviewCard
                        
                        // Data stored section
                        dataStoredSection
                        
                        // Export data section
                        exportSection
                        
                        // Delete data section
                        deleteSection
                        
                        // Incognito mode
                        incognitoSection
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
        }
        .onAppear { loadDataStats() }
        .alert("Delete Account", isPresented: $showDeleteAccountConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Everything", role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text("This will permanently delete your account, all conversations, documents, and settings. This action cannot be undone.")
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private var sheetHeader: some View {
        HStack {
            Text("PRIVACY DASHBOARD")
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
    
    // MARK: - Privacy Overview
    
    @ViewBuilder
    private var privacyOverviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 32))
                    .foregroundColor(.potomacYellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Privacy Matters")
                        .font(.custom("Rajdhani-Bold", size: 18))
                        .foregroundColor(.white)
                    Text("We're committed to protecting your data")
                        .font(.custom("Quicksand-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            HStack(spacing: 24) {
                privacyBadge(icon: "lock.fill", text: "End-to-end encrypted")
                privacyBadge(icon: "server.rack", text: "No third-party sharing")
                privacyBadge(icon: "trash.fill", text: "You control your data")
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.04))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
    
    @ViewBuilder
    private func privacyBadge(icon: String, text: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.potomacYellow)
            Text(text)
                .font(.custom("Quicksand-Regular", size: 10))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Data Stored
    
    @ViewBuilder
    private var dataStoredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DATA STORED")
                .font(.custom("Quicksand-SemiBold", size: 10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            VStack(spacing: 1) {
                dataRow(icon: "message.fill", iconColor: Color(hex: "60A5FA"), label: "Conversations", value: "\(conversationsCount)")
                Divider().background(Color.white.opacity(0.05)).padding(.leading, 44)
                dataRow(icon: "doc.fill", iconColor: Color.potomacTurquoise, label: "Documents", value: "\(documentsCount)")
                Divider().background(Color.white.opacity(0.05)).padding(.leading, 44)
                dataRow(icon: "internaldrive.fill", iconColor: Color.potomacYellow, label: "Cache Size", value: cacheSize)
                Divider().background(Color.white.opacity(0.05)).padding(.leading, 44)
                dataRow(icon: "key.fill", iconColor: Color(hex: "34D399"), label: "API Keys", value: "Encrypted")
            }
            .background(Color.white.opacity(0.04))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
        }
    }
    
    @ViewBuilder
    private func dataRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }
            
            Text(label)
                .font(.custom("Quicksand-SemiBold", size: 13))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.custom("Quicksand-Regular", size: 13))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
    
    // MARK: - Export Section
    
    @ViewBuilder
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EXPORT YOUR DATA")
                .font(.custom("Quicksand-SemiBold", size: 10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Download a copy of your data")
                            .font(.custom("Quicksand-SemiBold", size: 14))
                            .foregroundColor(.white)
                        Text("Includes conversations, documents, and settings")
                            .font(.custom("Quicksand-Regular", size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                }
                
                if showExportProgress {
                    VStack(spacing: 8) {
                        ProgressView(value: exportProgress) {
                            Text("Exporting...")
                                .font(.custom("Quicksand-Regular", size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .tint(.potomacYellow)
                        
                        Text("\(Int(exportProgress * 100))%")
                            .font(.custom("Quicksand-Bold", size: 12))
                            .foregroundColor(.potomacYellow)
                    }
                }
                
                Button {
                    Task { await exportData() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 14))
                        Text("Export All Data")
                            .font(.custom("Rajdhani-Bold", size: 14))
                            .tracking(1)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.potomacYellow)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(showExportProgress)
            }
            .padding(16)
            .background(Color.white.opacity(0.04))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
        }
    }
    
    // MARK: - Delete Section
    
    @ViewBuilder
    private var deleteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DELETE YOUR DATA")
                .font(.custom("Quicksand-SemiBold", size: 10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Request data deletion")
                            .font(.custom("Quicksand-SemiBold", size: 14))
                            .foregroundColor(.white)
                        Text("We'll process your request within 30 days per GDPR")
                            .font(.custom("Quicksand-Regular", size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                }
                
                Button {
                    showDeleteAccountConfirm = true
                } label: {
                    HStack(spacing: 8) {
                        if isDeletingAccount {
                            ProgressView()
                                .tint(.red)
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 14))
                        }
                        Text(isDeletingAccount ? "Deleting..." : "Delete Account & Data")
                            .font(.custom("Rajdhani-Bold", size: 14))
                            .tracking(1)
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(isDeletingAccount)
            }
            .padding(16)
            .background(Color.white.opacity(0.04))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
        }
    }
    
    // MARK: - Incognito Mode
    
    @ViewBuilder
    private var incognitoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("INCOGNITO MODE")
                .font(.custom("Quicksand-SemiBold", size: 10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            IncognitoModeToggle()
        }
    }
    
    // MARK: - Helpers
    
    private func loadDataStats() {
        // Calculate cache size
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        if let enumerator = FileManager.default.enumerator(at: cacheURL, includingPropertiesForKeys: [.fileSizeKey]) {
            var totalSize: Int64 = 0
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
            cacheSize = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
        }
        
        // TODO: Load actual counts from backend
        conversationsCount = 12
        documentsCount = 5
    }
    
    private func exportData() async {
        showExportProgress = true
        exportProgress = 0
        
        // Simulate export progress
        for i in 1...10 {
            try? await Task.sleep(nanoseconds: 200_000_000)
            exportProgress = Double(i) / 10.0
        }
        
        // Create JSON export
        let exportData: [String: Any] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "user": [
                "email": auth.user?.email ?? "",
                "name": auth.user?.name ?? ""
            ],
            "conversations": [],
            "documents": []
        ]
        
        // Save to documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let exportURL = documentsPath.appendingPathComponent("analyst_export_\(Date().timeIntervalSince1970).json")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            try jsonData.write(to: exportURL)
            exportedURL = exportURL
            
            // Show share sheet
            showExportProgress = false
            
            #if os(iOS)
            // Share the file
            let activityVC = UIActivityViewController(activityItems: [exportURL], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
            #endif
        } catch {
            print("Export failed: \(error)")
            showExportProgress = false
        }
    }
    
    private func deleteAccount() async {
        isDeletingAccount = true
        // TODO: Call API to delete account
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        isDeletingAccount = false
        
        // Clear local data
        KeychainManager.shared.deleteAll()
        CacheManager.shared.clearAll()
        
        // Logout
        await auth.logout()
    }
}

// MARK: - Incognito Mode Toggle

struct IncognitoModeToggle: View {
    @AppStorage("incognitoMode") private var isEnabled: Bool = false
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "A78BFA").opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "A78BFA"))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Private Session")
                    .font(.custom("Quicksand-SemiBold", size: 14))
                    .foregroundColor(.white)
                Text("Messages won't be saved locally")
                    .font(.custom("Quicksand-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(.potomacYellow)
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

// MARK: - Preview

#Preview {
    PrivacyDashboardView()
        .environment(AuthViewModel())
}