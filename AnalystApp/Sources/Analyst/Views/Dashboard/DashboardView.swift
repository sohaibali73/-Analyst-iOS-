import SwiftUI

// MARK: - Dashboard Navigation Destination

enum DashboardDestination: Hashable {
    case backtest
    case research
    case presentations
}

// MARK: - Dashboard View

struct DashboardView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(TabViewModel.self) private var tabVM

    @State private var recentConversations: [Conversation] = []
    @State private var isLoadingRecents = false
    @State private var navigationPath = NavigationPath()
    @State private var showSkeletons = true
    @State private var marketData: [MarketTicker] = []
    @State private var isRefreshing = false

    private let featureCards: [(icon: String, color: String, title: String, subtitle: String, destination: DashboardAction)] = [
        ("bubble.left.and.bubble.right.fill", "FEC00F", "AI Chat", "Ask Yang about markets", .tab(.chat)),
        ("chevron.left.forwardslash.chevron.right", "00DED1", "AFL Generator", "Generate trading strategies", .tab(.afl)),
        ("cylinder.fill", "A78BFA", "Knowledge Base", "Upload & search documents", .tab(.knowledge)),
        ("chart.line.uptrend.xyaxis", "34D399", "Backtest", "Analyze strategy performance", .navigate(.backtest)),
        ("magnifyingglass.circle.fill", "3B82F6", "Research", "Deep company research", .navigate(.research)),
        ("doc.richtext.fill", "F472B6", "Presentations", "Generate presentations", .navigate(.presentations)),
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color(hex: "0D0D0D").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // ── Hero Banner ─────────────────────────────
                        heroBanner
                            .padding(.top, 16)
                            .padding(.horizontal, 20)
                            .animatedEntry()
                        
                        // ── Market Pulse Strip ─────────────────────
                        marketPulseStrip
                            .padding(.top, 20)
                            .animatedEntry(delay: 0.1)

                        // ── Quick Actions ──────────────────────────
                        quickActionsRow
                            .padding(.top, 20)
                            .padding(.horizontal, 20)
                            .animatedEntry(delay: 0.15)

                        Divider()
                            .background(Color.white.opacity(0.07))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)

                        // ── Feature Cards Grid ─────────────────────
                        sectionHeader("Features", icon: "sparkles")
                            .padding(.horizontal, 24)
                            .padding(.bottom, 12)
                            .animatedEntry(delay: 0.2)

                        if showSkeletons {
                            featureCardsGridSkeleton
                                .padding(.horizontal, 24)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        withAnimation(AnimationProvider.fadeIn()) {
                                            showSkeletons = false
                                        }
                                    }
                                }
                        } else {
                            featureCardsGrid
                                .padding(.horizontal, 24)
                                .transition(.fade)
                        }

                        // ── Recent Conversations ───────────────────
                        if isLoadingRecents {
                            Divider()
                                .background(Color.white.opacity(0.07))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 20)
                            
                            sectionHeader("Recent Conversations", icon: "clock.arrow.circlepath")
                                .padding(.horizontal, 24)
                                .padding(.bottom, 12)
                            
                            recentConversationsSkeleton
                                .padding(.horizontal, 24)
                        } else if !recentConversations.isEmpty {
                            Divider()
                                .background(Color.white.opacity(0.07))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 20)

                            sectionHeader("Recent Conversations", icon: "clock.arrow.circlepath")
                                .padding(.horizontal, 24)
                                .padding(.bottom, 12)

                            recentConversationsSection
                                .padding(.horizontal, 24)
                        } else {
                            // Empty state
                            Divider()
                                .background(Color.white.opacity(0.07))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 20)
                            
                            emptyConversationsState
                                .padding(.horizontal, 24)
                        }

                        Spacer().frame(height: 120)
                    }
                }
                .refreshable {
                    await refreshData()
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: DashboardDestination.self) { destination in
                switch destination {
                case .backtest:
                    BacktestView()
                case .research:
                    ResearcherView()
                case .presentations:
                    PresentationsView()
                }
            }
        }
        .task {
            await loadInitialData()
        }
    }
    
    // MARK: - Hero Banner
    
    @ViewBuilder
    private var heroBanner: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top row: Greeting + Date
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(greetingText)
                        .font(.quicksandMedium(15))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(auth.user?.displayName ?? "Trader")
                        .font(.rajdhaniBold(32))
                        .foregroundColor(Color.potomacYellow)
                }
                
                Spacer()
                
                // Date and avatar
                VStack(alignment: .trailing, spacing: 8) {
                    Text(formattedDate)
                        .font(.quicksandRegular(12))
                        .foregroundColor(.white.opacity(0.3))
                    
                    // Avatar with glow
                    ZStack {
                        Circle()
                            .fill(Color.potomacYellow.opacity(0.15))
                            .frame(width: 52, height: 52)
                            .blur(radius: 8)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.potomacYellow, .potomacYellowDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        if let initials = auth.user?.initials {
                            Text(initials)
                                .font(.rajdhaniBold(18))
                                .foregroundColor(.black)
                        } else {
                            Image("potomac-icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                        }
                    }
                }
            }
            
            // Market sentiment bar
            HStack(spacing: 10) {
                marketSentimentIndicator
                
                Text(marketSentimentText)
                    .font(.quicksandSemiBold(13))
                    .foregroundColor(marketSentimentColor)
                
                Spacer()
                
                Text("What would you like to do today?")
                    .font(.quicksandRegular(12))
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.top, 16)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.potomacYellow.opacity(0.3), .potomacYellow.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .overlay(alignment: .bottom) {
            // Bottom glow
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.potomacYellow.opacity(0.15))
                .frame(height: 1)
                .blur(radius: 6)
                .padding(.horizontal, 12)
        }
    }
    
    @ViewBuilder
    private var marketSentimentIndicator: some View {
        HStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(marketSentimentColor.opacity(index <= marketSentimentLevel ? 1 : 0.2))
                    .frame(width: 4, height: CGFloat(8 + index * 3))
            }
        }
    }
    
    private var marketSentimentLevel: Int {
        // Mock sentiment level (0-3)
        let hour = Calendar.current.component(.hour, from: Date())
        return hour % 4
    }
    
    private var marketSentimentText: String {
        switch marketSentimentLevel {
        case 0: return "Bearish Market"
        case 1: return "Neutral Market"
        case 2: return "Bullish Market"
        default: return "Strong Bull Market"
        }
    }
    
    private var marketSentimentColor: Color {
        switch marketSentimentLevel {
        case 0: return .chartRed
        case 1: return .potomacYellow
        case 2: return .accentGreen
        default: return .chartGreen
        }
    }
    
    // MARK: - Market Pulse Strip
    
    @ViewBuilder
    private var marketPulseStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(marketTickers) { ticker in
                    MarketTickerCard(ticker: ticker)
                        .staggeredEntry(index: marketTickers.firstIndex(of: ticker) ?? 0, totalCount: marketTickers.count, baseDelay: 0.2)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var marketTickers: [MarketTicker] {
        // Mock data - in production, this would come from an API
        [
            MarketTicker(symbol: "SPX", name: "S&P 500", price: 5234.18, change: 0.85),
            MarketTicker(symbol: "NDX", name: "Nasdaq", price: 18345.67, change: 1.12),
            MarketTicker(symbol: "AAPL", name: "Apple", price: 189.45, change: -0.34),
            MarketTicker(symbol: "BTC", name: "Bitcoin", price: 67432.00, change: 2.45),
            MarketTicker(symbol: "GLD", name: "Gold", price: 2034.50, change: 0.23),
        ]
    }

    // MARK: - Quick Actions Row

    @ViewBuilder
    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            PillButton(
                icon: "plus.message.fill",
                label: "New Chat",
                color: Color.potomacYellow
            ) {
                HapticManager.shared.lightImpact()
                tabVM.select(.chat)
            }

            PillButton(
                icon: "chevron.left.forwardslash.chevron.right",
                label: "Generate AFL",
                color: Color.potomacTurquoise
            ) {
                HapticManager.shared.lightImpact()
                tabVM.select(.afl)
            }

            PillButton(
                icon: "arrow.up.doc.fill",
                label: "Upload Doc",
                color: Color(hex: "A78BFA")
            ) {
                HapticManager.shared.lightImpact()
                tabVM.select(.knowledge)
            }
        }
    }

    // MARK: - Feature Cards Grid

    @ViewBuilder
    private var featureCardsGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(featureCards.enumerated()), id: \.element.title) { index, card in
                PremiumFeatureCard(
                    icon: card.icon,
                    iconColor: Color(hex: card.color),
                    title: card.title,
                    subtitle: card.subtitle
                ) {
                    HapticManager.shared.mediumImpact()
                    handleAction(card.destination)
                }
                .staggeredEntry(index: index, totalCount: featureCards.count, baseDelay: 0.3)
            }
        }
    }

    // MARK: - Recent Conversations

    @ViewBuilder
    private var recentConversationsSection: some View {
        VStack(spacing: 8) {
            ForEach(Array(recentConversations.prefix(5).enumerated()), id: \.element.id) { index, conversation in
                RecentConversationRow(conversation: conversation) {
                    HapticManager.shared.lightImpact()
                    tabVM.select(.chat)
                }
                .staggeredEntry(index: index, totalCount: min(5, recentConversations.count), baseDelay: 0.4)
            }
        }
    }
    
    // MARK: - Empty State
    
    @ViewBuilder
    private var emptyConversationsState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.potomacYellow.opacity(0.08))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.potomacYellow.opacity(0.6))
            }
            
            VStack(spacing: 6) {
                Text("No conversations yet")
                    .font(.rajdhaniBold(18))
                    .foregroundColor(.white)
                    .tracking(0.5)
                
                Text("Start a conversation with Yang to begin")
                    .font(.quicksandRegular(13))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Button {
                HapticManager.shared.lightImpact()
                tabVM.select(.chat)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.message.fill")
                        .font(.system(size: 14))
                    Text("Start Chat")
                        .font(.quicksandSemiBold(14))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.potomacYellow)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    // MARK: - Skeleton Views
    
    @ViewBuilder
    private var featureCardsGridSkeleton: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<6, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        SkeletonView(cornerRadius: 10, height: 40, width: 40)
                        Spacer()
                        SkeletonView(cornerRadius: 4, height: 11, width: 11)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        SkeletonView(cornerRadius: 4, height: 14, width: 100)
                        SkeletonView(cornerRadius: 4, height: 11, width: 140)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
            }
        }
    }
    
    @ViewBuilder
    private var recentConversationsSkeleton: some View {
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 14) {
                    SkeletonView(cornerRadius: 19, height: 38, width: 38)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        SkeletonView(cornerRadius: 4, height: 14, width: 160)
                        SkeletonView(cornerRadius: 4, height: 12, width: 100)
                    }
                    
                    Spacer()
                    
                    SkeletonView(cornerRadius: 4, height: 11, width: 50)
                }
                .padding(12)
                .background(Color.white.opacity(0.03))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Section Header

    @ViewBuilder
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.potomacYellow)

            Text(title)
                .font(.rajdhaniBold(13))
                .foregroundColor(.white.opacity(0.5))
                .tracking(2)

            Spacer()
        }
    }

    // MARK: - Helpers

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        case 17..<22: return "Good evening,"
        default: return "Welcome back,"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: Date())
    }

    private func handleAction(_ action: DashboardAction) {
        switch action {
        case .tab(let tab):
            tabVM.select(tab)
        case .navigate(let destination):
            navigationPath.append(destination)
        }
    }

    @MainActor
    private func loadInitialData() async {
        await loadRecentConversations()
    }
    
    @MainActor
    private func refreshData() async {
        isRefreshing = true
        await loadRecentConversations()
        isRefreshing = false
    }

    @MainActor
    private func loadRecentConversations() async {
        isLoadingRecents = true
        defer { isLoadingRecents = false }
        do {
            let conversations = try await APIClient.shared.getConversations()
            recentConversations = Array(conversations.prefix(5))
        } catch {
            // Silently fail — dashboard still usable
            print("⚠️ Dashboard: Failed to load recent conversations: \(error)")
        }
    }
}

// MARK: - Market Ticker Model

struct MarketTicker: Identifiable, Equatable {
    let id = UUID()
    let symbol: String
    let name: String
    let price: Double
    let change: Double
    
    var formattedPrice: String {
        if symbol == "BTC" {
            return String(format: "$%.0f", price)
        }
        return String(format: "%.2f", price)
    }
    
    var formattedChange: String {
        let sign = change >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, change)
    }
    
    static func == (lhs: MarketTicker, rhs: MarketTicker) -> Bool {
        lhs.symbol == rhs.symbol
    }
}

// MARK: - Market Ticker Card

struct MarketTickerCard: View {
    let ticker: MarketTicker
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Symbol and name
            HStack(spacing: 6) {
                Text(ticker.symbol)
                    .font(.rajdhaniBold(14))
                    .foregroundColor(.white)
                
                Text(ticker.name)
                    .font(.quicksandRegular(10))
                    .foregroundColor(.white.opacity(0.35))
            }
            
            // Price
            Text(ticker.formattedPrice)
                .font(.rajdhaniSemiBold(18))
                .foregroundColor(.white)
            
            // Change
            HStack(spacing: 4) {
                Image(systemName: ticker.change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 9, weight: .semibold))
                Text(ticker.formattedChange)
                    .font(.quicksandSemiBold(11))
            }
            .foregroundColor(ticker.change >= 0 ? .chartGreen : .chartRed)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(AnimationProvider.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in
                    isPressed = false
                    HapticManager.shared.lightImpact()
                }
        )
    }
}

// MARK: - Dashboard Action

enum DashboardAction: Hashable {
    case tab(TabViewModel.Tab)
    case navigate(DashboardDestination)
}

// MARK: - Premium Feature Card

struct PremiumFeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    // Gradient icon background
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [iconColor.opacity(0.25), iconColor.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(iconColor.opacity(0.3), lineWidth: 0.5)
                            )

                        Image(systemName: icon)
                            .font(.system(size: 17))
                            .foregroundColor(iconColor)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.15))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.rajdhaniBold(14))
                        .foregroundColor(.white)
                        .tracking(0.5)

                    Text(subtitle)
                        .font(.quicksandRegular(11))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .overlay(alignment: .bottom) {
                // Bottom glow
                RoundedRectangle(cornerRadius: 14)
                    .fill(iconColor.opacity(0.2))
                    .frame(height: 1)
                    .blur(radius: 4)
                    .padding(.horizontal, 8)
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(AnimationProvider.Spring.snappy.animation, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                    HapticManager.shared.lightImpact()
                }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Recent Conversation Row

struct RecentConversationRow: View {
    let conversation: Conversation
    let action: () -> Void
    
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.potomacYellow.opacity(0.10))
                        .frame(width: 38, height: 38)

                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.potomacYellow)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(conversation.displayTitle)
                        .font(.quicksandSemiBold(14))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage)
                            .font(.quicksandRegular(12))
                            .foregroundColor(.white.opacity(0.35))
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(conversation.formattedDate)
                        .font(.quicksandRegular(11))
                        .foregroundColor(.white.opacity(0.3))
                    
                    // Conversation type badge
                    Text("Chat")
                        .font(.quicksandSemiBold(9))
                        .foregroundColor(.potomacYellow.opacity(0.6))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.potomacYellow.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(AnimationProvider.quick, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environment(AuthViewModel())
        .environment(TabViewModel())
        .preferredColorScheme(.dark)
}