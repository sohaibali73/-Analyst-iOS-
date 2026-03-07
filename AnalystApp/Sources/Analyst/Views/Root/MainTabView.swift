import SwiftUI

struct MainTabView: View {
    @Environment(TabViewModel.self) private var tabVM
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("appTheme") private var appTheme: AppTheme = .dark
    
    var body: some View {
        Group {
            if sizeClass == .compact {
                iphoneLayout
            } else {
                ipadLayout
            }
        }
        .preferredColorScheme(appTheme.colorScheme)
    }
    
    // MARK: - iPhone Layout with Custom Tab Bar
    
    @ViewBuilder
    private var iphoneLayout: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch tabVM.selectedTab {
                case .dashboard:
                    DashboardView()
                case .chat:
                    ChatView()
                case .afl:
                    AFLGeneratorView()
                case .knowledge:
                    KnowledgeBaseView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            
            // Custom Tab Bar
            CustomTabBar()
        }
        .ignoresSafeArea(.keyboard)
    }
    
    // MARK: - iPad/Mac Layout
    
    @ViewBuilder
    private var ipadLayout: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 260, max: 320)
        } detail: {
            NavigationStack {
                switch tabVM.selectedTab {
                case .dashboard:
                    DashboardView()
                case .chat:
                    ChatView()
                case .afl:
                    AFLGeneratorView()
                case .knowledge:
                    KnowledgeBaseView()
                case .settings:
                    SettingsView()
                }
            }
        }
        .tint(.potomacYellow)
    }
}

// MARK: - Sidebar View (iPad/Mac)

struct SidebarView: View {
    @Environment(TabViewModel.self) private var tabVM
    @Environment(AuthViewModel.self) private var auth
    @State private var hoveredTab: TabViewModel.Tab?
    
    var body: some View {
        List {
            // Main Navigation Section
            Section {
                ForEach(TabViewModel.Tab.allCases, id: \.self) { tab in
                    SidebarTabRow(
                        tab: tab,
                        isSelected: tabVM.selectedTab == tab,
                        isHovered: hoveredTab == tab
                    ) {
                        tabVM.select(tab)
                    }
                    .onHover { hovering in
                        withAnimation(.easeOut(duration: 0.15)) {
                            hoveredTab = hovering ? tab : nil
                        }
                    }
                }
            } header: {
                Text("Navigation")
                    .font(.quicksandSemiBold(10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)
                    .textCase(nil)
            }
            
            // Features Section
            Section {
                ForEach(TabViewModel.Feature.allCases, id: \.self) { feature in
                    SidebarFeatureRow(feature: feature)
                }
            } header: {
                Text("Features")
                    .font(.quicksandSemiBold(10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)
                    .textCase(nil)
            }
            
            // Profile Section
            Section {
                if let user = auth.user {
                    HStack(spacing: 12) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.potomacYellow, .potomacYellowDark],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                            
                            Text(user.initials)
                                .font(.rajdhaniBold(16))
                                .foregroundStyle(.black)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.displayName)
                                .font(.quicksandSemiBold(14))
                                .foregroundColor(.white)
                            
                            Text(user.email)
                                .font(.quicksandRegular(11))
                                .foregroundColor(.white.opacity(0.4))
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 8)
                }
            } header: {
                Text("Account")
                    .font(.quicksandSemiBold(10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)
                    .textCase(nil)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Analyst")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // Refresh action
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }
}

// MARK: - Sidebar Tab Row

struct SidebarTabRow: View {
    let tab: TabViewModel.Tab
    let isSelected: Bool
    let isHovered: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.potomacYellow.opacity(0.15))
                            .frame(width: 32, height: 32)
                    }
                    
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? .potomacYellow : .white.opacity(0.5))
                }
                .frame(width: 32, height: 32)
                
                // Label
                Text(tab.rawValue)
                    .font(.quicksandSemiBold(14))
                    .foregroundColor(isSelected ? .potomacYellow : .white.opacity(0.7))
                
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.potomacYellow.opacity(0.08) : isHovered ? Color.white.opacity(0.03) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sidebar Feature Row

struct SidebarFeatureRow: View {
    let feature: TabViewModel.Feature
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: feature.iconColor).opacity(0.12))
                    .frame(width: 32, height: 32)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: feature.iconColor))
            }
            
            // Label
            Text(feature.rawValue)
                .font(.quicksandRegular(14))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.2))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.white.opacity(0.03) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environment(AuthViewModel())
        .environment(TabViewModel())
}