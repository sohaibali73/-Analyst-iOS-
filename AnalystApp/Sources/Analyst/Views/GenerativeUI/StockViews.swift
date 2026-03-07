import SwiftUI

// MARK: - Stock Card View

struct StockCardResult {
    let symbol: String
    let dataType: String?
    let success: Bool
    let error: String?
    
    // Price data
    let currentPrice: Double?
    let previousClose: Double?
    let open: Double?
    let dayHigh: Double?
    let dayLow: Double?
    let volume: Int?
    let marketCap: Double?
    let companyName: String?
    
    // History data
    let history: [StockHistoryEntry]?
    
    // Info data
    let name: String?
    let sector: String?
    let industry: String?
    let description: String?
    let exchange: String?
    
    let cached: Bool
    let fetchTimeMs: Int?
    
    static func from(toolCall: ToolCall) -> StockCardResult {
        let args = toolCall.argumentsDict
        let result = toolCall.resultDict
        
        func value<T>(_ key: String, from dict: [String: Any]) -> T? {
            dict[key] as? T
        }
        
        return StockCardResult(
            symbol: value("symbol", from: args) ?? value("symbol", from: result) ?? "",
            dataType: value("data_type", from: result),
            success: value("success", from: result) ?? true,
            error: value("error", from: result),
            currentPrice: value("current_price", from: result),
            previousClose: value("previous_close", from: result),
            open: value("open", from: result),
            dayHigh: value("day_high", from: result),
            dayLow: value("day_low", from: result),
            volume: value("volume", from: result),
            marketCap: value("market_cap", from: result),
            companyName: value("company_name", from: result),
            history: nil, // Parse from result if needed
            name: value("name", from: result),
            sector: value("sector", from: result),
            industry: value("industry", from: result),
            description: value("description", from: result),
            exchange: value("exchange", from: result),
            cached: value("cached", from: result) ?? false,
            fetchTimeMs: value("fetch_time_ms", from: result)
        )
    }
}

struct StockHistoryEntry: Codable {
    let date: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int
}

struct StockCardView: View {
    let result: StockCardResult
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "Stock Error", error: error)
        } else if result.dataType == "price" {
            StockPriceCard(result: result)
        } else if result.dataType == "info" {
            StockInfoCard(result: result)
        } else {
            StockPriceCard(result: result)
        }
    }
}

// MARK: - Stock Price Card

struct StockPriceCard: View {
    let result: StockCardResult
    
    private var change: Double? {
        guard let price = result.currentPrice, let prev = result.previousClose else { return nil }
        return price - prev
    }
    
    private var changePercent: Double? {
        guard let change = change, let prev = result.previousClose else { return nil }
        return (change / prev) * 100
    }
    
    private var isUp: Bool {
        (change ?? 0) >= 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.companyName ?? result.symbol)
                        .font(.quicksandRegular(14))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(result.symbol)
                        .font(.rajdhaniBold(20))
                        .foregroundColor(.potomacYellow)
                }
                
                Spacer()
                
                // Change badge
                HStack(spacing: 4) {
                    Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .semibold))
                    
                    if let pct = changePercent {
                        Text(String(format: "%+.2f%%", pct))
                            .font(.quicksandSemiBold(13))
                    }
                }
                .foregroundColor(isUp ? .chartGreen : .chartRed)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isUp ? Color.chartGreen.opacity(0.15) : Color.chartRed.opacity(0.15))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Price
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if let price = result.currentPrice {
                    Text(String(format: "$%.2f", price))
                        .font(.system(size: 36, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                } else {
                    Text("N/A")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 4)
            
            if let change = change {
                Text(String(format: "%+.2f today", change))
                    .font(.quicksandRegular(14))
                    .foregroundColor(isUp ? .chartGreen : .chartRed)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
            
            Divider().overlay(Color.white.opacity(0.08))
            
            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatItem(label: "Open", value: result.open.map { String(format: "$%.2f", $0) })
                StatItem(label: "Prev Close", value: result.previousClose.map { String(format: "$%.2f", $0) })
                StatItem(label: "Day High", value: result.dayHigh.map { String(format: "$%.2f", $0) }, color: .chartGreen)
                StatItem(label: "Day Low", value: result.dayLow.map { String(format: "$%.2f", $0) }, color: .chartRed)
                StatItem(label: "Volume", value: result.volume.map { formatNumber($0) })
                StatItem(label: "Market Cap", value: result.marketCap.map { formatNumber($0) })
            }
            .padding(20)
            
            // Footer
            HStack {
                Text(result.cached ? "📦 Cached" : "⚡ Live")
                    .font(.quicksandRegular(11))
                    .foregroundColor(.white.opacity(0.4))
                
                Spacer()
                
                if let time = result.fetchTimeMs {
                    Text("\(time)ms")
                        .font(.quicksandRegular(11))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e"), Color(hex: "0f3460")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
    }
    
    private func formatNumber(_ num: Double) -> String {
        if num >= 1e12 { return String(format: "$%.2fT", num / 1e12) }
        if num >= 1e9 { return String(format: "$%.2fB", num / 1e9) }
        if num >= 1e6 { return String(format: "$%.2fM", num / 1e6) }
        if num >= 1e3 { return String(format: "$%.1fK", num / 1e3) }
        return String(format: "%.0f", num)
    }
    
    private func formatNumber(_ num: Int) -> String {
        formatNumber(Double(num))
    }
}

// MARK: - Stock Info Card

struct StockInfoCard: View {
    let result: StockCardResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Symbol
            Text(result.symbol)
                .font(.rajdhaniBold(20))
                .foregroundColor(.potomacYellow)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            if let name = result.name {
                Text(name)
                    .font(.quicksandSemiBold(16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
            
            // Tags
            HStack(spacing: 8) {
                if let sector = result.sector {
                    TagView(text: sector, color: .potomacYellow)
                }
                if let industry = result.industry {
                    TagView(text: industry, color: .chartPurple)
                }
                if let exchange = result.exchange {
                    TagView(text: exchange, color: .chartGreen)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            if let desc = result.description {
                Text(desc)
                    .font(.quicksandRegular(13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let label: String
    let value: String?
    var color: Color = .white
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.quicksandRegular(10))
                .foregroundColor(.white.opacity(0.5))
            
            Text(value ?? "N/A")
                .font(.quicksandSemiBold(15))
                .foregroundColor(color)
        }
    }
}

// MARK: - Tag View

struct TagView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.quicksandSemiBold(12))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Error Card View

struct ErrorCardView: View {
    let title: String
    let error: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.chartRed)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.quicksandSemiBold(14))
                    .foregroundColor(.chartRed)
                
                Text(error)
                    .font(.quicksandRegular(12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.chartRed.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.chartRed.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Market Overview View

struct MarketOverviewResult {
    let success: Bool
    let error: String?
    let indices: [String: MarketQuote]
    let commodities: [String: MarketQuote]
    let crypto: [String: MarketQuote]
    let bonds: [String: MarketQuote]
    let marketSentiment: String?
    
    static func from(toolCall: ToolCall) -> MarketOverviewResult {
        let result = toolCall.resultDict
        
        func parseQuotes(_ key: String) -> [String: MarketQuote] {
            guard let dict = result[key] as? [String: [String: Any]] else { return [:] }
            return dict.compactMapValues { MarketQuote.from(dict: $0) }
        }
        
        return MarketOverviewResult(
            success: result["success"] as? Bool ?? true,
            error: result["error"] as? String,
            indices: parseQuotes("indices"),
            commodities: parseQuotes("commodities"),
            crypto: parseQuotes("crypto"),
            bonds: parseQuotes("bonds"),
            marketSentiment: result["market_sentiment"] as? String
        )
    }
}

struct MarketQuote {
    let price: Double
    let change: Double
    let changePercent: Double
    
    static func from(dict: [String: Any]) -> MarketQuote? {
        guard let price = dict["price"] as? Double else { return nil }
        return MarketQuote(
            price: price,
            change: dict["change"] as? Double ?? 0,
            changePercent: dict["change_percent"] as? Double ?? 0
        )
    }
}

struct MarketOverviewView: View {
    let result: MarketOverviewResult
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "Market Error", error: error)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "globe")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.potomacYellow)
                    
                    Text("Market Overview")
                        .font(.rajdhaniBold(16))
                        .foregroundColor(.potomacYellow)
                    
                    Spacer()
                    
                    if let sentiment = result.marketSentiment {
                        Text(sentiment.capitalized)
                            .font(.quicksandSemiBold(11))
                            .foregroundColor(sentimentColor(sentiment))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(sentimentColor(sentiment).opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .padding(20)
                
                if !result.indices.isEmpty {
                    MarketSection(title: "Indices", quotes: result.indices)
                }
                
                if !result.commodities.isEmpty {
                    MarketSection(title: "Commodities", quotes: result.commodities)
                }
                
                if !result.crypto.isEmpty {
                    MarketSection(title: "Crypto", quotes: result.crypto)
                }
                
                if !result.bonds.isEmpty {
                    MarketSection(title: "Bonds", quotes: result.bonds)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
        }
    }
    
    private func sentimentColor(_ sentiment: String) -> Color {
        switch sentiment.lowercased() {
        case "bullish": return .chartGreen
        case "bearish": return .chartRed
        default: return .chartOrange
        }
    }
}

struct MarketSection: View {
    let title: String
    let quotes: [String: MarketQuote]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.quicksandSemiBold(10))
                .foregroundColor(.white.opacity(0.4))
                .padding(.horizontal, 20)
            
            ForEach(Array(quotes.keys.sorted()), id: \.self) { key in
                if let quote = quotes[key] {
                    QuoteRow(name: key, quote: quote)
                }
            }
        }
        .padding(.bottom, 12)
    }
}

struct QuoteRow: View {
    let name: String
    let quote: MarketQuote
    
    var isUp: Bool { quote.change >= 0 }
    
    var body: some View {
        HStack {
            Text(name)
                .font(.quicksandRegular(13))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(String(format: "%.2f", quote.price))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
            
            HStack(spacing: 2) {
                Image(systemName: isUp ? "arrow.up" : "arrow.down")
                    .font(.system(size: 10, weight: .semibold))
                Text(String(format: "%+.2f%%", quote.changePercent))
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isUp ? .chartGreen : .chartRed)
            .frame(width: 65, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }
}

// MARK: - Stock Screener View

struct StockScreenerResult {
    let success: Bool
    let error: String?
    let results: [ScreenResult]
    let filters: ScreenerFilters
    let fetchTimeMs: Int?
    
    static func from(toolCall: ToolCall) -> StockScreenerResult {
        let result = toolCall.resultDict
        
        var screenResults: [ScreenResult] = []
        if let resultsArray = result["results"] as? [[String: Any]] {
            screenResults = resultsArray.compactMap { ScreenResult.from(dict: $0) }
        }
        
        var filters = ScreenerFilters()
        if let filtersDict = result["filters"] as? [String: Any] {
            filters = ScreenerFilters(
                sector: filtersDict["sector"] as? String,
                minMarketCap: filtersDict["min_market_cap"] as? Double,
                maxPERatio: filtersDict["max_pe_ratio"] as? Double,
                minDividendYield: filtersDict["min_dividend_yield"] as? Double
            )
        }
        
        return StockScreenerResult(
            success: result["success"] as? Bool ?? true,
            error: result["error"] as? String,
            results: screenResults,
            filters: filters,
            fetchTimeMs: result["fetch_time_ms"] as? Int
        )
    }
}

struct ScreenResult {
    let symbol: String
    let name: String
    let sector: String
    let price: Double
    let marketCapB: Double
    let peRatio: Double?
    let dividendYield: Double
    let fiftyTwoWChange: Double
    
    static func from(dict: [String: Any]) -> ScreenResult? {
        guard let symbol = dict["symbol"] as? String,
              let name = dict["name"] as? String else { return nil }
        
        return ScreenResult(
            symbol: symbol,
            name: name,
            sector: dict["sector"] as? String ?? "",
            price: dict["price"] as? Double ?? 0,
            marketCapB: dict["market_cap_b"] as? Double ?? 0,
            peRatio: dict["pe_ratio"] as? Double,
            dividendYield: dict["dividend_yield"] as? Double ?? 0,
            fiftyTwoWChange: dict["52w_change"] as? Double ?? 0
        )
    }
}

struct ScreenerFilters {
    let sector: String?
    let minMarketCap: Double?
    let maxPERatio: Double?
    let minDividendYield: Double?
    
    init(sector: String? = nil, minMarketCap: Double? = nil, maxPERatio: Double? = nil, minDividendYield: Double? = nil) {
        self.sector = sector
        self.minMarketCap = minMarketCap
        self.maxPERatio = maxPERatio
        self.minDividendYield = minDividendYield
    }
}

struct StockScreenerView: View {
    let result: StockScreenerResult
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "Stock Screener Error", error: error)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.potomacYellow)
                    
                    Text("Stock Screener")
                        .font(.rajdhaniBold(16))
                        .foregroundColor(.potomacYellow)
                    
                    Text("\(result.results.count) results")
                        .font(.quicksandRegular(12))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                    
                    if let time = result.fetchTimeMs {
                        Text("\(time)ms")
                            .font(.quicksandRegular(11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(20)
                
                // Filter tags
                if hasActiveFilters {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.4))
                            
                            if let sector = result.filters.sector {
                                FilterTag(text: sector, color: .potomacYellow)
                            }
                            if let cap = result.filters.minMarketCap {
                                FilterTag(text: "Cap > $\(Int(cap))B", color: .chartBlue)
                            }
                            if let pe = result.filters.maxPERatio {
                                FilterTag(text: "PE < \(Int(pe))", color: .chartGreen)
                            }
                            if let div = result.filters.minDividendYield {
                                FilterTag(text: "Div > \(Int(div))%", color: .chartPurple)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 12)
                }
                
                // Results table
                ScrollView {
                    VStack(spacing: 0) {
                        // Header row
                        HStack(spacing: 4) {
                            Text("Symbol")
                                .frame(width: 60, alignment: .leading)
                            Text("Name")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Price")
                                .frame(width: 60, alignment: .trailing)
                            Text("52W")
                                .frame(width: 55, alignment: .trailing)
                        }
                        .font(.quicksandSemiBold(10))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.03))
                        
                        ForEach(result.results.prefix(15), id: \.symbol) { stock in
                            ScreenerRow(stock: stock)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
        }
    }
    
    private var hasActiveFilters: Bool {
        result.filters.sector != nil ||
        result.filters.minMarketCap != nil ||
        result.filters.maxPERatio != nil ||
        result.filters.minDividendYield != nil
    }
}

struct FilterTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.quicksandSemiBold(11))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

struct ScreenerRow: View {
    let stock: ScreenResult
    
    var body: some View {
        HStack(spacing: 4) {
            Text(stock.symbol)
                .font(.quicksandSemiBold(13))
                .foregroundColor(.potomacYellow)
                .frame(width: 60, alignment: .leading)
            
            Text(stock.name)
                .font(.quicksandRegular(12))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(String(format: "$%.2f", stock.price))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 60, alignment: .trailing)
            
            HStack(spacing: 2) {
                Image(systemName: stock.fiftyTwoWChange >= 0 ? "arrow.up" : "arrow.down")
                    .font(.system(size: 8, weight: .semibold))
                Text(String(format: "%+.0f%%", stock.fiftyTwoWChange))
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(stock.fiftyTwoWChange >= 0 ? .chartGreen : .chartRed)
            .frame(width: 55, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.02))
    }
}

// MARK: - Stock Comparison View

struct StockComparisonResult {
    let success: Bool
    let error: String?
    let symbols: [String]
    let comparisons: [ComparisonData]
    let fetchTimeMs: Int?
    
    static func from(toolCall: ToolCall) -> StockComparisonResult {
        let result = toolCall.resultDict
        
        var comparisons: [ComparisonData] = []
        if let compsArray = result["comparisons"] as? [[String: Any]] {
            comparisons = compsArray.compactMap { ComparisonData.from(dict: $0) }
        }
        
        return StockComparisonResult(
            success: result["success"] as? Bool ?? true,
            error: result["error"] as? String,
            symbols: result["symbols"] as? [String] ?? [],
            comparisons: comparisons,
            fetchTimeMs: result["fetch_time_ms"] as? Int
        )
    }
}

struct ComparisonData {
    let symbol: String
    let name: String
    let sector: String
    let price: Double
    let marketCapB: Double
    let peRatio: Double?
    let forwardPE: Double?
    let revenueB: Double?
    let profitMargin: Double?
    let dividendYield: Double?
    let beta: Double?
    let fiftyTwoWChange: Double
    let error: String?
    
    static func from(dict: [String: Any]) -> ComparisonData? {
        guard let symbol = dict["symbol"] as? String else { return nil }
        
        return ComparisonData(
            symbol: symbol,
            name: dict["name"] as? String ?? "",
            sector: dict["sector"] as? String ?? "",
            price: dict["price"] as? Double ?? 0,
            marketCapB: dict["market_cap_b"] as? Double ?? 0,
            peRatio: dict["pe_ratio"] as? Double,
            forwardPE: dict["forward_pe"] as? Double,
            revenueB: dict["revenue_b"] as? Double,
            profitMargin: dict["profit_margin"] as? Double,
            dividendYield: dict["dividend_yield"] as? Double,
            beta: dict["beta"] as? Double,
            fiftyTwoWChange: dict["52w_change"] as? Double ?? 0,
            error: dict["error"] as? String
        )
    }
}

struct StockComparisonView: View {
    let result: StockComparisonResult
    
    private let metrics: [(key: String, label: String)] = [
        ("price", "Price"),
        ("marketCapB", "Mkt Cap"),
        ("peRatio", "P/E"),
        ("revenueB", "Revenue"),
        ("profitMargin", "Margin"),
        ("dividendYield", "Div Yield"),
        ("beta", "Beta"),
        ("fiftyTwoWChange", "52W Chg")
    ]
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "Compare Error", error: error)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.potomacYellow)
                    
                    Text("Stock Comparison")
                        .font(.rajdhaniBold(16))
                        .foregroundColor(.potomacYellow)
                    
                    Spacer()
                    
                    if let time = result.fetchTimeMs {
                        Text("\(time)ms")
                            .font(.quicksandRegular(11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(20)
                
                // Comparison table
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header row
                        HStack(spacing: 0) {
                            Text("Metric")
                                .font(.quicksandSemiBold(11))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 80, alignment: .leading)
                            
                            ForEach(result.comparisons, id: \.symbol) { comp in
                                Text(comp.symbol)
                                    .font(.quicksandBold(12))
                                    .foregroundColor(.potomacYellow)
                                    .frame(width: 80, alignment: .trailing)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.03))
                        
                        ForEach(metrics, id: \.key) { metric in
                            HStack(spacing: 0) {
                                Text(metric.label)
                                    .font(.quicksandRegular(11))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 80, alignment: .leading)
                                
                                ForEach(result.comparisons, id: \.symbol) { comp in
                                    Text(formatMetric(key: metric.key, data: comp))
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(colorForMetric(key: metric.key, data: comp))
                                        .frame(width: 80, alignment: .trailing)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.01))
                        }
                    }
                }
                .padding(.bottom, 12)
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
        }
    }
    
    private func formatMetric(key: String, data: ComparisonData) -> String {
        if data.error != nil { return "—" }
        
        switch key {
        case "price": return String(format: "$%.2f", data.price)
        case "marketCapB": return String(format: "$%.1fB", data.marketCapB)
        case "peRatio": return data.peRatio.map { String(format: "%.1f", $0) } ?? "—"
        case "revenueB": return data.revenueB.map { String(format: "$%.1fB", $0) } ?? "—"
        case "profitMargin": return data.profitMargin.map { String(format: "%.1f%%", $0) } ?? "—"
        case "dividendYield": return data.dividendYield.map { String(format: "%.2f%%", $0) } ?? "—"
        case "beta": return data.beta.map { String(format: "%.2f", $0) } ?? "—"
        case "fiftyTwoWChange": return String(format: "%+.1f%%", data.fiftyTwoWChange)
        default: return "—"
        }
    }
    
    private func colorForMetric(key: String, data: ComparisonData) -> Color {
        if key == "fiftyTwoWChange" {
            return data.fiftyTwoWChange >= 0 ? .chartGreen : .chartRed
        }
        if key == "profitMargin", let margin = data.profitMargin {
            return margin > 20 ? .chartGreen : margin > 10 ? .chartOrange : .chartRed
        }
        return .white
    }
}