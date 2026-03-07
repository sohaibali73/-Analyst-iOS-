import SwiftUI

// MARK: - Market Overview Widget

struct MarketOverviewWidget: View {
    let indices: [MarketIndex]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MARKET OVERVIEW")
                    .font(.quicksandSemiBold(10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)
                
                Spacer()
                
                Text("Live")
                    .font(.quicksandSemiBold(9))
                    .foregroundColor(.chartGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.chartGreen.opacity(0.15))
                    .cornerRadius(4)
            }
            
            ForEach(indices) { index in
                MarketIndexRow(index: index)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Market Index Model

struct MarketIndex: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let change: Double
    let changePercent: Double
    
    var isPositive: Bool { change >= 0 }
}

// MARK: - Market Index Row

struct MarketIndexRow: View {
    let index: MarketIndex
    
    var body: some View {
        HStack(spacing: 12) {
            Text(index.name)
                .font(.quicksandSemiBold(13))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(String(format: "%.2f", index.value))
                .font(.quicksandSemiBold(13))
                .foregroundColor(.white)
            
            HStack(spacing: 2) {
                Image(systemName: index.isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 9, weight: .bold))
                Text(String(format: "%+.2f%%", index.changePercent))
                    .font(.quicksandSemiBold(11))
            }
            .foregroundColor(index.isPositive ? .chartGreen : .chartRed)
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Activity Feed Widget

struct ActivityFeedWidget: View {
    let activities: [ActivityItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT ACTIVITY")
                .font(.quicksandSemiBold(10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            if activities.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.15))
                    Text("No recent activity")
                        .font(.quicksandRegular(12))
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(activities) { activity in
                    ActivityRow(activity: activity)
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

// MARK: - Activity Item Model

struct ActivityItem: Identifiable {
    let id = UUID()
    let type: ActivityType
    let title: String
    let subtitle: String
    let timestamp: Date
    
    enum ActivityType {
        case chat
        case afl
        case backtest
        case knowledge
        case research
        
        var icon: String {
            switch self {
            case .chat: return "message.fill"
            case .afl: return "chevron.left.forwardslash.chevron.right"
            case .backtest: return "chart.line.uptrend.xyaxis"
            case .knowledge: return "cylinder.fill"
            case .research: return "magnifyingglass"
            }
        }
        
        var color: Color {
            switch self {
            case .chat: return .potomacYellow
            case .afl: return .potomacTurquoise
            case .backtest: return .chartGreen
            case .knowledge: return .chartBlue
            case .research: return .chartOrange
            }
        }
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(activity.type.color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: activity.type.icon)
                    .font(.system(size: 13))
                    .foregroundColor(activity.type.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.quicksandSemiBold(12))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(activity.subtitle)
                    .font(.quicksandRegular(10))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(activity.timestamp, style: .relative)
                .font(.quicksandRegular(10))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Quick Stats Widget

struct QuickStatsWidget: View {
    let stats: [QuickStat]
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(stats) { stat in
                QuickStatCard(stat: stat)
            }
        }
    }
}

// MARK: - Quick Stat Model

struct QuickStat: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: Double?
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let stat: QuickStat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: stat.icon)
                    .font(.system(size: 12))
                    .foregroundColor(stat.color)
                Spacer()
                if let trend = stat.trend {
                    HStack(spacing: 2) {
                        Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 8, weight: .bold))
                        Text(String(format: "%+.0f%%", trend))
                            .font(.quicksandSemiBold(9))
                    }
                    .foregroundColor(trend >= 0 ? .chartGreen : .chartRed)
                }
            }
            
            Text(stat.value)
                .font(.rajdhaniBold(22))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(stat.title)
                .font(.quicksandRegular(9))
                .foregroundColor(.white.opacity(0.4))
                .tracking(0.5)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(stat.color.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Onboarding Tip Card

struct OnboardingTipCard: View {
    let tip: OnboardingTip
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.potomacYellow.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: tip.icon)
                    .font(.system(size: 18))
                    .foregroundColor(.potomacYellow)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(tip.title)
                    .font(.quicksandSemiBold(13))
                    .foregroundColor(.white)
                Text(tip.message)
                    .font(.quicksandRegular(11))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color.potomacYellow.opacity(0.08), Color.potomacYellow.opacity(0.02)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.potomacYellow.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Onboarding Tip Model

struct OnboardingTip: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let message: String
}

// MARK: - Streak Widget

struct StreakWidget: View {
    let currentStreak: Int
    let bestStreak: Int
    let weekActivity: [Bool]
    
    var body: some View {
        HStack(spacing: 16) {
            // Streak count
            VStack(spacing: 4) {
                Text("\(currentStreak)")
                    .font(.rajdhaniBold(32))
                    .foregroundColor(.potomacYellow)
                Text("DAY STREAK")
                    .font(.quicksandSemiBold(8))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)
            }
            
            // Week dots
            VStack(alignment: .leading, spacing: 4) {
                Text("This Week")
                    .font(.quicksandRegular(10))
                    .foregroundColor(.white.opacity(0.4))
                
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { day in
                        let active = day < weekActivity.count ? weekActivity[day] : false
                        Circle()
                            .fill(active ? Color.potomacYellow : Color.white.opacity(0.1))
                            .frame(width: 12, height: 12)
                    }
                }
                
                Text("Best: \(bestStreak) days")
                    .font(.quicksandRegular(9))
                    .foregroundColor(.white.opacity(0.3))
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}