import SwiftUI

// MARK: - Watchlist View

struct WatchlistView: View {
    let tickers: [WatchlistItem]
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WATCHLIST")
                .font(.quicksandSemiBold(10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            if tickers.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "star")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.15))
                    Text("Add tickers to your watchlist")
                        .font(.quicksandRegular(12))
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(tickers) { item in
                    WatchlistRow(item: item, onSelect: onSelect)
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

// MARK: - Watchlist Item

struct WatchlistItem: Identifiable {
    let id = UUID()
    let ticker: String
    let name: String
    let price: Double
    let change: Double
    let changePercent: Double
    
    var isPositive: Bool { change >= 0 }
}

// MARK: - Watchlist Row

struct WatchlistRow: View {
    let item: WatchlistItem
    let onSelect: (String) -> Void
    
    var body: some View {
        Button { onSelect(item.ticker) } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.ticker)
                        .font(.quicksandSemiBold(14))
                        .foregroundColor(.white)
                    Text(item.name)
                        .font(.quicksandRegular(10))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "$%.2f", item.price))
                        .font(.quicksandSemiBold(13))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 2) {
                        Image(systemName: item.isPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 8, weight: .bold))
                        Text(String(format: "%+.2f%%", item.changePercent))
                            .font(.quicksandSemiBold(10))
                    }
                    .foregroundColor(item.isPositive ? .chartGreen : .chartRed)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Research Summary Card

struct ResearchSummaryCard: View {
    let ticker: String
    let companyName: String
    let summary: String
    let sentiment: String?
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ticker)
                        .font(.rajdhaniBold(20))
                        .foregroundColor(.white)
                    Text(companyName)
                        .font(.quicksandRegular(12))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                if let sentiment = sentiment {
                    SentimentBadge(sentiment: sentiment)
                }
            }
            
            Text(summary)
                .font(.quicksandRegular(13))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(3)
                .lineLimit(isExpanded ? nil : 4)
            
            if summary.count > 200 {
                Button {
                    withAnimation(AnimationProvider.quick) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Show Less" : "Read More")
                        .font(.quicksandSemiBold(11))
                        .foregroundColor(.potomacYellow)
                }
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

// MARK: - Sentiment Badge

struct SentimentBadge: View {
    let sentiment: String
    
    private var color: Color {
        switch sentiment.lowercased() {
        case "bullish": return .chartGreen
        case "bearish": return .chartRed
        case "neutral": return .chartOrange
        default: return .white.opacity(0.4)
        }
    }
    
    private var icon: String {
        switch sentiment.lowercased() {
        case "bullish": return "arrow.up.right"
        case "bearish": return "arrow.down.right"
        default: return "minus"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(sentiment.capitalized)
                .font(.quicksandSemiBold(10))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.15))
        .cornerRadius(6)
    }
}

// MARK: - Price Target View

struct PriceTargetView: View {
    let currentPrice: Double
    let targetLow: Double
    let targetMedian: Double
    let targetHigh: Double
    
    private var rangeWidth: Double { targetHigh - targetLow }
    private var currentPosition: Double {
        guard rangeWidth > 0 else { return 0.5 }
        return max(0, min(1, (currentPrice - targetLow) / rangeWidth))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PRICE TARGETS")
                .font(.quicksandSemiBold(10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            // Range bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    // Gradient fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.chartRed, .chartOrange, .chartGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 8)
                    
                    // Current price marker
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                        .offset(x: geo.size.width * currentPosition - 7)
                }
            }
            .frame(height: 14)
            
            // Labels
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Low")
                        .font(.quicksandRegular(9))
                        .foregroundColor(.white.opacity(0.3))
                    Text(String(format: "$%.0f", targetLow))
                        .font(.quicksandSemiBold(12))
                        .foregroundColor(.chartRed)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("Median")
                        .font(.quicksandRegular(9))
                        .foregroundColor(.white.opacity(0.3))
                    Text(String(format: "$%.0f", targetMedian))
                        .font(.quicksandSemiBold(12))
                        .foregroundColor(.potomacYellow)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("High")
                        .font(.quicksandRegular(9))
                        .foregroundColor(.white.opacity(0.3))
                    Text(String(format: "$%.0f", targetHigh))
                        .font(.quicksandSemiBold(12))
                        .foregroundColor(.chartGreen)
                }
            }
            
            // Current price
            HStack {
                Text("Current:")
                    .font(.quicksandRegular(11))
                    .foregroundColor(.white.opacity(0.4))
                Text(String(format: "$%.2f", currentPrice))
                    .font(.quicksandSemiBold(13))
                    .foregroundColor(.white)
                
                Spacer()
                
                let upside = ((targetMedian - currentPrice) / currentPrice) * 100
                Text(String(format: "%+.1f%% to median", upside))
                    .font(.quicksandSemiBold(11))
                    .foregroundColor(upside >= 0 ? .chartGreen : .chartRed)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

// MARK: - Sector Comparison

struct SectorComparisonView: View {
    let sectors: [SectorPerformance]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SECTOR PERFORMANCE")
                .font(.quicksandSemiBold(10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            ForEach(sectors) { sector in
                HStack(spacing: 10) {
                    Text(sector.name)
                        .font(.quicksandRegular(12))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 90, alignment: .leading)
                    
                    GeometryReader { geo in
                        let width = max(0, min(geo.size.width, geo.size.width * abs(sector.performance) / 5))
                        HStack(spacing: 0) {
                            if sector.performance < 0 {
                                Spacer()
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.chartRed)
                                    .frame(width: width, height: 16)
                            } else {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.chartGreen)
                                    .frame(width: width, height: 16)
                                Spacer()
                            }
                        }
                    }
                    .frame(height: 16)
                    
                    Text(String(format: "%+.1f%%", sector.performance))
                        .font(.quicksandSemiBold(11))
                        .foregroundColor(sector.performance >= 0 ? .chartGreen : .chartRed)
                        .frame(width: 55, alignment: .trailing)
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

// MARK: - Sector Performance Model

struct SectorPerformance: Identifiable {
    let id = UUID()
    let name: String
    let performance: Double
}

// MARK: - Research Comparison View

struct ResearchComparisonView: View {
    let ticker1: String
    let ticker2: String
    let metrics: [ComparisonRow]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("COMPARISON")
                    .font(.quicksandSemiBold(10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)
                Spacer()
            }
            
            // Header
            HStack {
                Text("Metric")
                    .font(.quicksandSemiBold(10))
                    .foregroundColor(.white.opacity(0.3))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(ticker1)
                    .font(.quicksandSemiBold(11))
                    .foregroundColor(.potomacYellow)
                    .frame(width: 80, alignment: .trailing)
                Text(ticker2)
                    .font(.quicksandSemiBold(11))
                    .foregroundColor(.potomacTurquoise)
                    .frame(width: 80, alignment: .trailing)
            }
            .padding(.bottom, 4)
            
            ForEach(metrics) { row in
                HStack {
                    Text(row.label)
                        .font(.quicksandRegular(12))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(row.value1)
                        .font(.quicksandSemiBold(12))
                        .foregroundColor(.white)
                        .frame(width: 80, alignment: .trailing)
                    Text(row.value2)
                        .font(.quicksandSemiBold(12))
                        .foregroundColor(.white)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.vertical, 2)
                
                if row.id != metrics.last?.id {
                    Divider().background(Color.white.opacity(0.05))
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

// MARK: - Comparison Row

struct ComparisonRow: Identifiable {
    let id = UUID()
    let label: String
    let value1: String
    let value2: String
}