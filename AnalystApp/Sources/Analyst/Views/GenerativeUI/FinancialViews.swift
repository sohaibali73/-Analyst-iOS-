import SwiftUI

// MARK: - Sector Performance View

struct SectorPerformanceResult {
    let success: Bool
    let error: String?
    let period: String?
    let sectors: [SectorData]
    let best: SectorData?
    let worst: SectorData?
    
    static func from(toolCall: ToolCall) -> SectorPerformanceResult {
        let result = toolCall.resultDict
        
        var sectorData: [SectorData] = []
        if let sectorsArray = result["sectors"] as? [[String: Any]] {
            sectorData = sectorsArray.compactMap { SectorData.from(dict: $0) }
        }
        
        var bestSector: SectorData?
        var worstSector: SectorData?
        if let bestDict = result["best"] as? [String: Any] {
            bestSector = SectorData.from(dict: bestDict)
        }
        if let worstDict = result["worst"] as? [String: Any] {
            worstSector = SectorData.from(dict: worstDict)
        }
        
        return SectorPerformanceResult(
            success: result["success"] as? Bool ?? true,
            error: result["error"] as? String,
            period: result["period"] as? String ?? "1mo",
            sectors: sectorData,
            best: bestSector,
            worst: worstSector
        )
    }
}

struct SectorData {
    let name: String
    let etf: String
    let changePercent: Double
    let currentPrice: Double
    
    static func from(dict: [String: Any]) -> SectorData? {
        guard let name = dict["name"] as? String else { return nil }
        
        return SectorData(
            name: name,
            etf: dict["etf"] as? String ?? "",
            changePercent: dict["change_percent"] as? Double ?? 0,
            currentPrice: dict["current_price"] as? Double ?? 0
        )
    }
}

struct SectorPerformanceView: View {
    let result: SectorPerformanceResult
    
    private var maxAbs: Double {
        max(result.sectors.map { abs($0.changePercent) }.max() ?? 1, 1)
    }
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "Sector Error", error: error)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.potomacYellow)
                    
                    Text("Sector Performance")
                        .font(.rajdhaniBold(16))
                        .foregroundColor(.potomacYellow)
                    
                    Text("(\(result.period ?? "1mo"))")
                        .font(.quicksandRegular(12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(20)
                
                // Sectors
                ForEach(result.sectors, id: \.name) { sector in
                    HStack(spacing: 8) {
                        Text(sector.name)
                            .font(.quicksandRegular(12))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 110, alignment: .leading)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: sector.changePercent >= 0 ? .trailing : .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.05))
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(sector.changePercent >= 0 ? Color.chartGreen.opacity(0.5) : Color.chartRed.opacity(0.5))
                                    .frame(width: abs(sector.changePercent) / maxAbs * geometry.size.width)
                            }
                        }
                        .frame(height: 20)
                        
                        HStack(spacing: 2) {
                            Image(systemName: sector.changePercent >= 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 10, weight: .semibold))
                            Text(String(format: "%+.1f%%", sector.changePercent))
                                .font(.quicksandSemiBold(12))
                        }
                        .foregroundColor(sector.changePercent >= 0 ? .chartGreen : .chartRed)
                        .frame(width: 55, alignment: .trailing)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                }
            }
            .padding(.bottom, 16)
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
}

// MARK: - Position Sizer View

struct PositionSizerResult {
    let success: Bool
    let error: String?
    let symbol: String?
    let accountSize: Double?
    let riskPercent: Double?
    let entryPrice: Double?
    let stopLossPrice: Double?
    let riskPerShare: Double?
    let maxRiskAmount: Double?
    let recommendedShares: Int?
    let positionValue: Double?
    let positionPercent: Double?
    let potentialLoss: Double?
    let rewardTargets: [String: Double]?
    
    static func from(toolCall: ToolCall) -> PositionSizerResult {
        let result = toolCall.resultDict
        
        var targets: [String: Double]?
        if let targetsDict = result["reward_targets"] as? [String: Double] {
            targets = targetsDict
        }
        
        return PositionSizerResult(
            success: result["success"] as? Bool ?? true,
            error: result["error"] as? String,
            symbol: result["symbol"] as? String ?? toolCall.argumentsDict["symbol"] as? String,
            accountSize: result["account_size"] as? Double,
            riskPercent: result["risk_percent"] as? Double,
            entryPrice: result["entry_price"] as? Double,
            stopLossPrice: result["stop_loss_price"] as? Double,
            riskPerShare: result["risk_per_share"] as? Double,
            maxRiskAmount: result["max_risk_amount"] as? Double,
            recommendedShares: result["recommended_shares"] as? Int,
            positionValue: result["position_value"] as? Double,
            positionPercent: result["position_percent"] as? Double,
            potentialLoss: result["potential_loss"] as? Double,
            rewardTargets: targets
        )
    }
}

struct PositionSizerView: View {
    let result: PositionSizerResult
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "Position Size Error", error: error)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "scalemass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.potomacYellow)
                    
                    Text("Position Sizer")
                        .font(.rajdhaniBold(16))
                        .foregroundColor(.potomacYellow)
                    
                    if let symbol = result.symbol {
                        Text("(\(symbol))")
                            .font(.quicksandRegular(12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(24)
                
                // Recommended shares
                VStack(spacing: 4) {
                    Text("\(result.recommendedShares ?? 0)")
                        .font(.system(size: 42, weight: .heavy, design: .monospaced))
                        .foregroundColor(.chartGreen)
                    
                    Text("Recommended Shares")
                        .font(.quicksandRegular(14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
                
                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    PositionStatItem(label: "Account Size", value: formatCurrency(result.accountSize))
                    PositionStatItem(label: "Risk/Trade", value: result.riskPercent.map { "\($0)%" })
                    PositionStatItem(label: "Entry Price", value: formatCurrency(result.entryPrice))
                    PositionStatItem(label: "Stop Loss", value: formatCurrency(result.stopLossPrice), color: .chartRed)
                    PositionStatItem(label: "Position Value", value: formatCurrency(result.positionValue))
                    PositionStatItem(label: "Position %", value: result.positionPercent.map { "\($0)%" })
                    PositionStatItem(label: "Risk/Share", value: formatCurrency(result.riskPerShare), color: .chartOrange)
                    PositionStatItem(label: "Max Loss", value: formatCurrency(result.potentialLoss), color: .chartRed)
                }
                .padding(.horizontal, 20)
                
                // Reward targets
                if let targets = result.rewardTargets, !targets.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "target")
                                .font(.system(size: 12))
                            Text("Reward Targets")
                        }
                        .font(.quicksandSemiBold(11))
                        .foregroundColor(.white.opacity(0.4))
                        
                        HStack(spacing: 8) {
                            ForEach(Array(targets.keys.sorted()), id: \.self) { key in
                                if let value = targets[key] {
                                    VStack(spacing: 2) {
                                        Text(key)
                                            .font(.quicksandRegular(10))
                                            .foregroundColor(.chartGreen)
                                        Text(String(format: "$%.2f", value))
                                            .font(.quicksandSemiBold(13))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(Color.chartGreen.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "0f3460")],
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
    
    private func formatCurrency(_ value: Double?) -> String {
        guard let v = value else { return "—" }
        return String(format: "$%.2f", v)
    }
}

struct PositionStatItem: View {
    let label: String
    let value: String?
    var color: Color = .white
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.quicksandRegular(10))
                .foregroundColor(.white.opacity(0.4))
            
            Text(value ?? "—")
                .font(.quicksandSemiBold(14))
                .foregroundColor(color)
                .fontDesign(.monospaced)
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Options Snapshot View

struct OptionsSnapshotResult {
    let success: Bool
    let error: String?
    let symbol: String?
    let currentPrice: Double?
    let expirations: [String]
    let nearestExpiration: String?
    let putCallRatio: Double?
    let totalCallVolume: Int?
    let totalPutVolume: Int?
    let averageIV: Double?
    let topCalls: [OptionData]
    let topPuts: [OptionData]
    
    static func from(toolCall: ToolCall) -> OptionsSnapshotResult {
        let result = toolCall.resultDict
        
        var calls: [OptionData] = []
        var puts: [OptionData] = []
        if let callsArray = result["top_calls"] as? [[String: Any]] {
            calls = callsArray.compactMap { OptionData.from(dict: $0) }
        }
        if let putsArray = result["top_puts"] as? [[String: Any]] {
            puts = putsArray.compactMap { OptionData.from(dict: $0) }
        }
        
        return OptionsSnapshotResult(
            success: result["success"] as? Bool ?? true,
            error: result["error"] as? String,
            symbol: result["symbol"] as? String ?? toolCall.argumentsDict["symbol"] as? String,
            currentPrice: result["current_price"] as? Double,
            expirations: result["expirations"] as? [String] ?? [],
            nearestExpiration: result["nearest_expiration"] as? String,
            putCallRatio: result["put_call_ratio"] as? Double,
            totalCallVolume: result["total_call_volume"] as? Int,
            totalPutVolume: result["total_put_volume"] as? Int,
            averageIV: result["average_iv"] as? Double,
            topCalls: calls,
            topPuts: puts
        )
    }
}

struct OptionData {
    let strike: Double
    let last: Double
    let volume: Int
    let oi: Int
    let iv: Double
    
    static func from(dict: [String: Any]) -> OptionData? {
        guard let strike = dict["strike"] as? Double else { return nil }
        
        return OptionData(
            strike: strike,
            last: dict["last"] as? Double ?? 0,
            volume: dict["volume"] as? Int ?? 0,
            oi: dict["oi"] as? Int ?? 0,
            iv: dict["iv"] as? Double ?? 0
        )
    }
}

struct OptionsSnapshotView: View {
    let result: OptionsSnapshotResult
    
    private var pcColor: Color {
        guard let ratio = result.putCallRatio else { return .gray }
        if ratio > 1 { return .chartRed }
        if ratio < 0.7 { return .chartGreen }
        return .chartOrange
    }
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "Options Error", error: error)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "square.on.square")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.potomacYellow)
                    
                    Text("\(result.symbol ?? "") Options")
                        .font(.rajdhaniBold(16))
                        .foregroundColor(.potomacYellow)
                    
                    if let exp = result.nearestExpiration {
                        Text("Exp: \(exp)")
                            .font(.quicksandRegular(12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(20)
                
                // Stats
                HStack(spacing: 10) {
                    OptionStatBox(label: "Price", value: result.currentPrice.map { String(format: "$%.2f", $0) } ?? "—")
                    OptionStatBox(label: "P/C Ratio", value: result.putCallRatio.map { String(format: "%.2f", $0) } ?? "—", color: pcColor)
                    OptionStatBox(label: "Avg IV", value: result.averageIV.map { "\($0)%" } ?? "—")
                    OptionStatBox(label: "Expirations", value: "\(result.expirations.count)")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Top calls/puts
                HStack(alignment: .top, spacing: 12) {
                    // Calls
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                            Text("Top Calls")
                        }
                        .font(.quicksandSemiBold(11))
                        .foregroundColor(.chartGreen)
                        
                        Text("Vol: \(result.totalCallVolume?.formatted() ?? "0")")
                            .font(.quicksandRegular(10))
                            .foregroundColor(.white.opacity(0.4))
                        
                        OptionsTable(options: result.topCalls)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Puts
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                            Text("Top Puts")
                        }
                        .font(.quicksandSemiBold(11))
                        .foregroundColor(.chartRed)
                        
                        Text("Vol: \(result.totalPutVolume?.formatted() ?? "0")")
                            .font(.quicksandRegular(10))
                            .foregroundColor(.white.opacity(0.4))
                        
                        OptionsTable(options: result.topPuts)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
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
}

struct OptionStatBox: View {
    let label: String
    let value: String
    var color: Color = .white
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.quicksandRegular(10))
                .foregroundColor(.white.opacity(0.4))
            
            Text(value)
                .font(.quicksandSemiBold(16))
                .foregroundColor(color)
                .fontDesign(.monospaced)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct OptionsTable: View {
    let options: [OptionData]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Text("Strike")
                    .frame(width: 45, alignment: .leading)
                Text("Last")
                    .frame(width: 40, alignment: .trailing)
                Text("Vol")
                    .frame(width: 35, alignment: .trailing)
                Text("IV")
                    .frame(width: 30, alignment: .trailing)
            }
            .font(.quicksandSemiBold(9))
            .foregroundColor(.white.opacity(0.4))
            .padding(.bottom, 4)
            
            ForEach(Array(options.prefix(5).enumerated()), id: \.element.strike) { _, opt in
                HStack(spacing: 4) {
                    Text(String(format: "$%.0f", opt.strike))
                        .frame(width: 45, alignment: .leading)
                    Text(String(format: "$%.2f", opt.last))
                        .frame(width: 40, alignment: .trailing)
                    Text(opt.volume.formatted())
                        .frame(width: 35, alignment: .trailing)
                    Text(String(format: "%.0f%%", opt.iv))
                        .frame(width: 30, alignment: .trailing)
                        .foregroundColor(.chartOrange)
                }
                .font(.firaCode(10))
                .foregroundColor(.white.opacity(0.7))
                .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - Risk Metrics View

struct RiskMetricsResult {
    let success: Bool
    let error: String?
    let symbol: String?
    let benchmark: String?
    let period: String?
    let annualReturn: Double?
    let annualVolatility: Double?
    let sharpeRatio: Double?
    let sortinoRatio: Double?
    let maxDrawdown: Double?
    let var95: Double?
    let var99: Double?
    let beta: Double?
    let alpha: Double?
    let tradingDays: Int?
    
    static func from(toolCall: ToolCall) -> RiskMetricsResult {
        let result = toolCall.resultDict
        
        return RiskMetricsResult(
            success: result["success"] as? Bool ?? true,
            error: result["error"] as? String,
            symbol: result["symbol"] as? String ?? toolCall.argumentsDict["symbol"] as? String,
            benchmark: result["benchmark"] as? String,
            period: result["period"] as? String,
            annualReturn: result["annual_return"] as? Double,
            annualVolatility: result["annual_volatility"] as? Double,
            sharpeRatio: result["sharpe_ratio"] as? Double,
            sortinoRatio: result["sortino_ratio"] as? Double,
            maxDrawdown: result["max_drawdown"] as? Double,
            var95: result["var_95"] as? Double,
            var99: result["var_99"] as? Double,
            beta: result["beta"] as? Double,
            alpha: result["alpha"] as? Double,
            tradingDays: result["trading_days"] as? Int
        )
    }
}

struct RiskMetricsView: View {
    let result: RiskMetricsResult
    
    private var sharpeRating: String {
        guard let sharpe = result.sharpeRatio else { return "—" }
        if sharpe >= 2 { return "Excellent" }
        if sharpe >= 1 { return "Good" }
        if sharpe >= 0.5 { return "Average" }
        if sharpe >= 0 { return "Poor" }
        return "Bad"
    }
    
    private var sharpeColor: Color {
        guard let sharpe = result.sharpeRatio else { return .gray }
        if sharpe >= 1 { return .chartGreen }
        if sharpe >= 0.5 { return .chartOrange }
        return .chartRed
    }
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "Risk Error", error: error)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "gauge")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.potomacYellow)
                    
                    Text("\(result.symbol ?? "") Risk Analysis")
                        .font(.rajdhaniBold(16))
                        .foregroundColor(.potomacYellow)
                    
                    if let benchmark = result.benchmark, let period = result.period {
                        Text("vs \(benchmark) (\(period))")
                            .font(.quicksandRegular(11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(20)
                
                // Main metrics
                HStack(spacing: 20) {
                    // Sharpe
                    VStack(spacing: 2) {
                        Text(String(format: "%.2f", result.sharpeRatio ?? 0))
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(sharpeColor)
                        Text("Sharpe")
                            .font(.quicksandRegular(11))
                            .foregroundColor(.white.opacity(0.5))
                        Text(sharpeRating)
                            .font(.quicksandSemiBold(10))
                            .foregroundColor(sharpeColor)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Annual return
                    VStack(spacing: 2) {
                        Text(String(format: "%+.1f%%", result.annualReturn ?? 0))
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor((result.annualReturn ?? 0) >= 0 ? .chartGreen : .chartRed)
                        Text("Annual Return")
                            .font(.quicksandRegular(11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Max DD
                    VStack(spacing: 2) {
                        Text(String(format: "%.1f%%", result.maxDrawdown ?? 0))
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.chartRed)
                        Text("Max Drawdown")
                            .font(.quicksandRegular(11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    RiskMetricItem(label: "Sortino", value: result.sortinoRatio.map { String(format: "%.2f", $0) }, color: (result.sortinoRatio ?? 0) >= 1 ? .chartGreen : .chartOrange)
                    RiskMetricItem(label: "Beta", value: result.beta.map { String(format: "%.2f", $0) })
                    RiskMetricItem(label: "Alpha", value: result.alpha.map { String(format: "%+.1f%%", $0) }, color: (result.alpha ?? 0) > 0 ? .chartGreen : .chartRed)
                    RiskMetricItem(label: "Volatility", value: result.annualVolatility.map { String(format: "%.1f%%", $0) }, color: .chartOrange)
                    RiskMetricItem(label: "VaR 95%", value: result.var95.map { String(format: "%.1f%%", $0) }, color: .chartRed)
                    RiskMetricItem(label: "VaR 99%", value: result.var99.map { String(format: "%.1f%%", $0) }, color: .chartRed)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "0f3460")],
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
}

struct RiskMetricItem: View {
    let label: String
    let value: String?
    var color: Color = .white
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label.uppercased())
                .font(.quicksandRegular(10))
                .foregroundColor(.white.opacity(0.4))
            
            Text(value ?? "—")
                .font(.quicksandSemiBold(14))
                .foregroundColor(color)
                .fontDesign(.monospaced)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Correlation Matrix View

struct CorrelationMatrixResult {
    let success: Bool
    let error: String?
    let symbols: [String]
    let period: String?
    let matrix: [CorrelationRow]
    let notablePairs: [CorrelationPair]
    
    static func from(toolCall: ToolCall) -> CorrelationMatrixResult {
        let result = toolCall.resultDict
        
        var rows: [CorrelationRow] = []
        if let matrixArray = result["matrix"] as? [[String: Any]] {
            rows = matrixArray.compactMap { CorrelationRow.from(dict: $0) }
        }
        
        var pairs: [CorrelationPair] = []
        if let pairsArray = result["notable_pairs"] as? [[String: Any]] {
            pairs = pairsArray.compactMap { CorrelationPair.from(dict: $0) }
        }
        
        return CorrelationMatrixResult(
            success: result["success"] as? Bool ?? true,
            error: result["error"] as? String,
            symbols: result["symbols"] as? [String] ?? [],
            period: result["period"] as? String ?? "6mo",
            matrix: rows,
            notablePairs: pairs
        )
    }
}

struct CorrelationRow {
    let symbol: String
    let correlations: [String: Double]
    
    static func from(dict: [String: Any]) -> CorrelationRow? {
        guard let symbol = dict["symbol"] as? String,
              let correlations = dict["correlations"] as? [String: Double] else { return nil }
        
        return CorrelationRow(symbol: symbol, correlations: correlations)
    }
}

struct CorrelationPair {
    let pair: String
    let correlation: Double
    
    static func from(dict: [String: Any]) -> CorrelationPair? {
        guard let pair = dict["pair"] as? String,
              let correlation = dict["correlation"] as? Double else { return nil }
        
        return CorrelationPair(pair: pair, correlation: correlation)
    }
}

struct CorrelationMatrixView: View {
    let result: CorrelationMatrixResult
    
    private func corrColor(_ v: Double) -> Color {
        if v >= 0.7 { return .chartGreen }
        if v >= 0.3 { return Color(hex: "86EFAC") }
        if v >= -0.3 { return .white.opacity(0.5) }
        if v >= -0.7 { return Color(hex: "FCA5A5") }
        return .chartRed
    }
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "Correlation Error", error: error)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "circle.hexagongrid")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.potomacYellow)
                    
                    Text("Correlation Matrix")
                        .font(.rajdhaniBold(16))
                        .foregroundColor(.potomacYellow)
                    
                    Text("(\(result.period ?? "6mo"))")
                        .font(.quicksandRegular(12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(20)
                
                // Matrix
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header row
                        HStack(spacing: 0) {
                            Text("")
                                .frame(width: 50, height: 28)
                            
                            ForEach(result.symbols, id: \.self) { symbol in
                                Text(symbol)
                                    .font(.quicksandBold(12))
                                    .foregroundColor(.potomacYellow)
                                    .frame(width: 50, height: 28)
                            }
                        }
                        
                        ForEach(result.matrix, id: \.symbol) { row in
                            HStack(spacing: 0) {
                                Text(row.symbol)
                                    .font(.quicksandBold(12))
                                    .foregroundColor(.potomacYellow)
                                    .frame(width: 50, height: 28)
                                
                                ForEach(result.symbols, id: \.self) { colSymbol in
                                    let value = row.correlations[colSymbol] ?? 0
                                    Text(value == 1 ? "1.00" : String(format: "%.2f", value))
                                        .font(.firaCode(11))
                                        .foregroundColor(corrColor(value))
                                        .frame(width: 50, height: 28)
                                        .background(Color.white.opacity(abs(value) * 0.05))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Notable pairs
                if !result.notablePairs.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notable Pairs")
                            .font(.quicksandSemiBold(11))
                            .foregroundColor(.white.opacity(0.4))
                        
                        HStack(spacing: 6) {
                            ForEach(result.notablePairs, id: \.pair) { pair in
                                HStack(spacing: 4) {
                                    Text(pair.pair)
                                        .foregroundColor(.white.opacity(0.7))
                                    Text(":")
                                        .foregroundColor(.white.opacity(0.3))
                                    Text(String(format: "%.2f", pair.correlation))
                                        .foregroundColor(corrColor(pair.correlation))
                                        .fontWeight(.semibold)
                                }
                                .font(.quicksandRegular(11))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(20)
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
}

// MARK: - Dividend Card View

struct DividendCardResult {
    let success: Bool
    let error: String?
    let symbol: String?
    let name: String?
    let annualDividend: Double?
    let dividendYield: Double?
    let payoutRatio: Double?
    let exDividendDate: String?
    let frequency: String?
    let fiveYearAvgYield: Double?
    let history: [DividendPayment]
    
    static func from(toolCall: ToolCall) -> DividendCardResult {
        let result = toolCall.resultDict
        
        var payments: [DividendPayment] = []
        if let historyArray = result["history"] as? [[String: Any]] {
            payments = historyArray.compactMap { DividendPayment.from(dict: $0) }
        }
        
        return DividendCardResult(
            success: result["success"] as? Bool ?? true,
            error: result["error"] as? String,
            symbol: result["symbol"] as? String ?? toolCall.argumentsDict["symbol"] as? String,
            name: result["name"] as? String,
            annualDividend: result["annual_dividend"] as? Double,
            dividendYield: result["dividend_yield"] as? Double,
            payoutRatio: result["payout_ratio"] as? Double,
            exDividendDate: result["ex_dividend_date"] as? String,
            frequency: result["frequency"] as? String,
            fiveYearAvgYield: result["5y_avg_yield"] as? Double,
            history: payments
        )
    }
}

struct DividendPayment {
    let date: String
    let amount: Double
    
    static func from(dict: [String: Any]) -> DividendPayment? {
        guard let date = dict["date"] as? String,
              let amount = dict["amount"] as? Double else { return nil }
        
        return DividendPayment(date: date, amount: amount)
    }
}

struct DividendCardView: View {
    let result: DividendCardResult
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "Dividend Error", error: error)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.chartGreen)
                    
                    Text(result.symbol ?? "")
                        .font(.rajdhaniBold(16))
                        .foregroundColor(.potomacYellow)
                    
                    Text("Dividends")
                        .font(.quicksandRegular(12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(24)
                
                // Yield
                VStack(spacing: 4) {
                    Text(String(format: "%.2f%%", result.dividendYield ?? 0))
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(.chartGreen)
                    
                    Text("Annual Yield • \(String(format: "$%.2f", result.annualDividend ?? 0))/share")
                        .font(.quicksandRegular(13))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
                
                // Stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    DividendStatItem(label: "Payout Ratio", value: result.payoutRatio.map { String(format: "%.1f%%", $0) })
                    DividendStatItem(label: "5Y Avg Yield", value: result.fiveYearAvgYield.map { String(format: "%.2f%%", $0) })
                    DividendStatItem(label: "Frequency", value: result.frequency ?? "Quarterly")
                    DividendStatItem(label: "Ex-Div Date", value: result.exDividendDate ?? "—")
                }
                .padding(.horizontal, 24)
                
                // History chart
                if !result.history.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Recent Payments")
                            .font(.quicksandSemiBold(11))
                            .foregroundColor(.white.opacity(0.4))
                        
                        HStack(alignment: .bottom, spacing: 4) {
                            let maxAmount = result.history.map(\.amount).max() ?? 1
                            
                            ForEach(result.history, id: \.date) { payment in
                                let height = (payment.amount / maxAmount) * 36 + 4
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.chartGreen.opacity(0.5))
                                    .frame(width: 20, height: height)
                            }
                        }
                        .frame(height: 40)
                    }
                    .padding(24)
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
}

struct DividendStatItem: View {
    let label: String
    let value: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.quicksandRegular(10))
                .foregroundColor(.white.opacity(0.4))
            
            Text(value ?? "—")
                .font(.quicksandSemiBold(14))
                .foregroundColor(.white)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Backtest Results View

struct BacktestResultsResult {
    let success: Bool
    let error: String?
    let symbol: String?
    let strategy: String?
    let period: String?
    let parameters: BacktestParameters?
    let totalReturn: Double?
    let buyHoldReturn: Double?
    let excessReturn: Double?
    let totalTrades: Int?
    let winRate: Double?
    let maxDrawdown: Double?
    let annualVolatility: Double?
    let sharpeRatio: Double?
    let tradingDays: Int?
    let startDate: String?
    let endDate: String?
    
    static func from(toolCall: ToolCall) -> BacktestResultsResult {
        let result = toolCall.resultDict
        
        var params: BacktestParameters?
        if let paramsDict = result["parameters"] as? [String: Any] {
            params = BacktestParameters.from(dict: paramsDict)
        }
        
        return BacktestResultsResult(
            success: result["success"] as? Bool ?? true,
            error: result["error"] as? String,
            symbol: result["symbol"] as? String,
            strategy: result["strategy"] as? String,
            period: result["period"] as? String,
            parameters: params,
            totalReturn: result["total_return"] as? Double,
            buyHoldReturn: result["buy_hold_return"] as? Double,
            excessReturn: result["excess_return"] as? Double,
            totalTrades: result["total_trades"] as? Int,
            winRate: result["win_rate"] as? Double,
            maxDrawdown: result["max_drawdown"] as? Double,
            annualVolatility: result["annual_volatility"] as? Double,
            sharpeRatio: result["sharpe_ratio"] as? Double,
            tradingDays: result["trading_days"] as? Int,
            startDate: result["start_date"] as? String,
            endDate: result["end_date"] as? String
        )
    }
}

struct BacktestParameters {
    let fastPeriod: Int?
    let slowPeriod: Int?
    
    static func from(dict: [String: Any]) -> BacktestParameters {
        BacktestParameters(
            fastPeriod: dict["fast_period"] as? Int,
            slowPeriod: dict["slow_period"] as? Int
        )
    }
}

struct BacktestResultsView: View {
    let result: BacktestResultsResult
    
    private var strategyLabel: String {
        (result.strategy ?? "").replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    private var beatsBuyHold: Bool {
        (result.excessReturn ?? 0) > 0
    }
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "Backtest Error", error: error)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.potomacYellow)
                    
                    Text("Backtest: \(result.symbol ?? "")")
                        .font(.rajdhaniBold(16))
                        .foregroundColor(.potomacYellow)
                }
                .padding(20)
                
                // Strategy info
                HStack {
                    Text(strategyLabel)
                        .font(.quicksandSemiBold(12))
                        .foregroundColor(.white)
                    
                    if let fast = result.parameters?.fastPeriod, let slow = result.parameters?.slowPeriod {
                        Text("(\(fast)/\(slow))")
                            .font(.quicksandRegular(12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    if let start = result.startDate, let end = result.endDate {
                        Text("• \(start) → \(end)")
                            .font(.quicksandRegular(11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Returns comparison
                HStack(spacing: 20) {
                    VStack(spacing: 2) {
                        Text(String(format: "%+.1f%%", result.totalReturn ?? 0))
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor((result.totalReturn ?? 0) >= 0 ? .chartGreen : .chartRed)
                        Text("Strategy Return")
                            .font(.quicksandRegular(11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 2) {
                        Text(String(format: "%+.1f%%", result.buyHoldReturn ?? 0))
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor((result.buyHoldReturn ?? 0) >= 0 ? .chartGreen : .chartRed)
                        Text("Buy & Hold")
                            .font(.quicksandRegular(11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                
                // Excess return
                HStack {
                    Text(beatsBuyHold ? "✅ Beats" : "❌ Underperforms")
                    Text("Buy & Hold by")
                    Text(String(format: "%.1f%%", abs(result.excessReturn ?? 0)))
                        .fontWeight(.bold)
                }
                .font(.quicksandSemiBold(13))
                .foregroundColor(beatsBuyHold ? .chartGreen : .chartRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(beatsBuyHold ? Color.chartGreen.opacity(0.1) : Color.chartRed.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    BacktestStatItem(label: "Trades", value: result.totalTrades)
                    BacktestStatItem(label: "Win Rate", value: result.winRate.map { "\($0)%" }, color: (result.winRate ?? 0) >= 50 ? .chartGreen : .chartRed)
                    BacktestStatItem(label: "Sharpe", value: result.sharpeRatio.map { String(format: "%.2f", $0) }, color: (result.sharpeRatio ?? 0) >= 1 ? .chartGreen : .chartOrange)
                    BacktestStatItem(label: "Max DD", value: result.maxDrawdown.map { "\($0)%" }, color: .chartRed)
                    BacktestStatItem(label: "Volatility", value: result.annualVolatility.map { "\($0)%" }, color: .chartOrange)
                    BacktestStatItem(label: "Days", value: result.tradingDays)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "0f3460")],
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
}

struct BacktestStatItem: View {
    let label: String
    let value: Any?
    var color: Color = .white
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label.uppercased())
                .font(.quicksandRegular(10))
                .foregroundColor(.white.opacity(0.4))
            
            if let v = value as? Int {
                Text("\(v)")
                    .font(.quicksandSemiBold(14))
                    .foregroundColor(color)
                    .fontDesign(.monospaced)
            } else if let v = value as? String {
                Text(v)
                    .font(.quicksandSemiBold(14))
                    .foregroundColor(color)
                    .fontDesign(.monospaced)
            } else {
                Text("—")
                    .font(.quicksandSemiBold(14))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}