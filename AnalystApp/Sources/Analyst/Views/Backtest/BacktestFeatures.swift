import SwiftUI
import Charts

// MARK: - Equity Chart View

struct EquityChartView: View {
    let equityCurve: [EquityPoint]
    @State private var selectedPoint: EquityPoint?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EQUITY CURVE")
                .font(.quicksandSemiBold(10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            equityChart
            
            // Selected point detail
            if let point = selectedPoint {
                selectedPointView(point)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var equityChart: some View {
        let maxEquity = equityCurve.map(\.equity).max() ?? 100000
        Chart(equityCurve) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Equity", point.equity)
            )
            .foregroundStyle(Color.potomacYellow)
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
        .chartYScale(domain: 0...maxEquity)
        .frame(height: 200)
    }
    
    @ViewBuilder
    private func selectedPointView(_ point: EquityPoint) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(point.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.quicksandRegular(10))
                    .foregroundColor(.white.opacity(0.4))
                Text(formatCurrency(point.equity))
                    .font(.quicksandSemiBold(14))
                    .foregroundColor(.potomacYellow)
            }
            
            Spacer()
            
            if let drawdown = point.drawdown, drawdown > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Drawdown")
                        .font(.quicksandRegular(10))
                        .foregroundColor(.white.opacity(0.4))
                    Text("-\(String(format: "%.1f%%", drawdown))")
                        .font(.quicksandSemiBold(14))
                        .foregroundColor(.chartRed)
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}

// MARK: - Equity Point Model

struct EquityPoint: Identifiable {
    let id = UUID()
    let date: Date
    let equity: Double
    let drawdown: Double?
}

// MARK: - Trade List View

struct TradeListView: View {
    let trades: [TradeRecord]
    @State private var filter: TradeFilter = .all
    @State private var sortDescending = true
    
    var filteredTrades: [TradeRecord] {
        var result = trades
        switch filter {
        case .all: break
        case .winners: result = result.filter { $0.pnl ?? 0 > 0 }
        case .losers: result = result.filter { ($0.pnl ?? 0) <= 0 }
        case .long: result = result.filter { $0.direction == "long" }
        case .short: result = result.filter { $0.direction == "short" }
        }
        return sortDescending ? result.reversed() : result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TRADE HISTORY")
                    .font(.quicksandSemiBold(10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)
                
                Spacer()
                
                Menu {
                    Picker("Filter", selection: $filter) {
                        ForEach(TradeFilter.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    Divider()
                    Toggle("Newest First", isOn: $sortDescending)
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            
            if trades.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(filteredTrades) { trade in
                            TradeRowView(trade: trade)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 28))
                .foregroundColor(.white.opacity(0.15))
            Text("No trades recorded")
                .font(.quicksandRegular(13))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Trade Filter

enum TradeFilter: String, CaseIterable {
    case all = "All Trades"
    case winners = "Winners"
    case losers = "Losers"
    case long = "Long Only"
    case short = "Short Only"
}

// MARK: - Trade Row View

struct TradeRowView: View {
    let trade: TradeRecord
    
    var body: some View {
        HStack(spacing: 12) {
            // Direction badge
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(trade.direction == "long" ? Color.chartGreen.opacity(0.15) : Color.chartRed.opacity(0.15))
                    .frame(width: 44, height: 28)
                Text(trade.direction?.uppercased() ?? "?")
                    .font(.quicksandSemiBold(9))
                    .foregroundColor(trade.direction == "long" ? .chartGreen : .chartRed)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(trade.symbol ?? "Unknown")
                    .font(.quicksandSemiBold(13))
                    .foregroundColor(.white)
                
                Text(trade.entryDate?.formatted(date: .abbreviated, time: .omitted) ?? "")
                    .font(.quicksandRegular(10))
                    .foregroundColor(.white.opacity(0.3))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatPnL(trade.pnl))
                    .font(.quicksandSemiBold(13))
                    .foregroundColor((trade.pnl ?? 0) >= 0 ? .chartGreen : .chartRed)
                
                if let pct = trade.pnlPercent {
                    Text("\(pct >= 0 ? "+" : "")\(String(format: "%.1f%%", pct))")
                        .font(.quicksandRegular(10))
                        .foregroundColor(pct >= 0 ? .chartGreen.opacity(0.7) : .chartRed.opacity(0.7))
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.02))
        .cornerRadius(8)
    }
    
    private func formatPnL(_ pnl: Double?) -> String {
        guard let pnl = pnl else { return "-" }
        let prefix = pnl >= 0 ? "+" : ""
        return "\(prefix)$\(String(format: "%.2f", abs(pnl)))"
    }
}

// MARK: - Trade Record Model

struct TradeRecord: Identifiable, Codable {
    let id: String
    let symbol: String?
    let direction: String?
    let entryDate: Date?
    let exitDate: Date?
    let entryPrice: Double?
    let exitPrice: Double?
    let quantity: Double?
    let pnl: Double?
    let pnlPercent: Double?
}

// MARK: - Backtest Comparison View

struct BacktestComparisonView: View {
    let results: [BacktestResult]
    @State private var selectedMetrics: [ComparisonMetric] = [.cagr, .sharpeRatio, .maxDrawdown, .winRate]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("COMPARE BACKTESTS")
                    .font(.quicksandSemiBold(10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)
                
                Spacer()
                
                Menu {
                    ForEach(ComparisonMetric.allCases, id: \.self) { metric in
                        Button {
                            if selectedMetrics.contains(metric) {
                                selectedMetrics.removeAll { $0 == metric }
                            } else {
                                selectedMetrics.append(metric)
                            }
                        } label: {
                            HStack {
                                Text(metric.rawValue)
                                if selectedMetrics.contains(metric) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            
            if results.count < 2 {
                emptyState
            } else {
                Chart {
                    ForEach(results) { result in
                        ForEach(selectedMetrics, id: \.self) { metric in
                            BarMark(
                                x: .value("Backtest", result.filename ?? "Result"),
                                y: .value(metric.rawValue, metric.value(for: result))
                            )
                            .foregroundStyle(by: .value("Metric", metric.rawValue))
                            .position(by: .value("Metric", metric.rawValue))
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.1))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel {
                            Text(String(format: "%.0f", value.as(Double.self) ?? 0))
                                .font(.quicksandRegular(9))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                .chartLegend(position: .bottom, alignment: .leading)
                .frame(height: 200)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 28))
                .foregroundColor(.white.opacity(0.15))
            Text("Upload at least 2 backtests to compare")
                .font(.quicksandRegular(13))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Comparison Metric

enum ComparisonMetric: String, CaseIterable {
    case cagr = "CAGR %"
    case sharpeRatio = "Sharpe"
    case maxDrawdown = "Max DD %"
    case winRate = "Win Rate %"
    case profitFactor = "Profit Factor"
    
    func value(for result: BacktestResult) -> Double {
        guard let metrics = result.metrics else { return 0 }
        switch self {
        case .cagr: return metrics.cagr ?? 0
        case .sharpeRatio: return metrics.sharpeRatio ?? 0
        case .maxDrawdown: return abs(metrics.maxDrawdown ?? 0)
        case .winRate: return metrics.winRate ?? 0
        case .profitFactor: return metrics.profitFactor ?? 0
        }
    }
}

// MARK: - Performance Metrics View

struct PerformanceMetricsView: View {
    let metrics: BacktestMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PERFORMANCE METRICS")
                .font(.quicksandSemiBold(10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricGauge(
                    title: "CAGR",
                    value: metrics.cagr ?? 0,
                    unit: "%",
                    color: (metrics.cagr ?? 0) >= 15 ? .chartGreen : (metrics.cagr ?? 0) >= 0 ? .chartOrange : .chartRed,
                    range: -50...50
                )
                
                MetricGauge(
                    title: "Sharpe Ratio",
                    value: metrics.sharpeRatio ?? 0,
                    unit: "",
                    color: (metrics.sharpeRatio ?? 0) >= 1 ? .chartGreen : (metrics.sharpeRatio ?? 0) >= 0.5 ? .chartOrange : .chartRed,
                    range: -1...3
                )
                
                MetricGauge(
                    title: "Max Drawdown",
                    value: abs(metrics.maxDrawdown ?? 0),
                    unit: "%",
                    color: abs(metrics.maxDrawdown ?? 0) <= 20 ? .chartGreen : abs(metrics.maxDrawdown ?? 0) <= 40 ? .chartOrange : .chartRed,
                    range: 0...60,
                    invertGradient: true
                )
                
                MetricGauge(
                    title: "Win Rate",
                    value: metrics.winRate ?? 0,
                    unit: "%",
                    color: (metrics.winRate ?? 0) >= 50 ? .chartGreen : (metrics.winRate ?? 0) >= 35 ? .chartOrange : .chartRed,
                    range: 0...100
                )
            }
            
            // Additional metrics row
            HStack(spacing: 16) {
                if let pf = metrics.profitFactor {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(pf >= 1.5 ? Color.chartGreen : Color.chartOrange)
                            .frame(width: 8, height: 8)
                        Text("Profit Factor")
                            .font(.quicksandRegular(11))
                            .foregroundColor(.white.opacity(0.4))
                        Text(String(format: "%.2f", pf))
                            .font(.quicksandSemiBold(13))
                            .foregroundColor(.white)
                    }
                }
                
                if let trades = metrics.totalTrades {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.potomacTurquoise)
                            .frame(width: 8, height: 8)
                        Text("Total Trades")
                            .font(.quicksandRegular(11))
                            .foregroundColor(.white.opacity(0.4))
                        Text("\(trades)")
                            .font(.quicksandSemiBold(13))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

// MARK: - Metric Gauge

struct MetricGauge: View {
    let title: String
    let value: Double
    let unit: String
    let color: Color
    let range: ClosedRange<Double>
    var invertGradient: Bool = false
    
    private var normalizedValue: Double {
        max(0, min(1, (value - range.lowerBound) / (range.upperBound - range.lowerBound)))
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.quicksandRegular(10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(0.5)
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 6)
                
                Circle()
                    .trim(from: 0, to: normalizedValue)
                    .stroke(
                        color.gradient,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text(String(format: "%.1f", value))
                        .font(.quicksandSemiBold(18))
                        .foregroundColor(color)
                    Text(unit)
                        .font(.quicksandRegular(9))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .frame(width: 70, height: 70)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Backtest Export View

struct BacktestExportView: View {
    let result: BacktestResult
    @State private var exportFormat: ExportFormat = .pdf
    @State private var includeTrades = true
    @State private var includeCharts = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D0D").ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Format selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("EXPORT FORMAT")
                            .font(.quicksandSemiBold(10))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1.5)
                        
                        HStack(spacing: 8) {
                            ForEach(ExportFormat.allCases, id: \.self) { format in
                                Button {
                                    exportFormat = format
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: format.icon)
                                            .font(.system(size: 12))
                                        Text(format.rawValue)
                                            .font(.quicksandSemiBold(11))
                                    }
                                    .foregroundColor(exportFormat == format ? .black : .white.opacity(0.6))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(exportFormat == format ? Color.potomacYellow : Color.white.opacity(0.06))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Options
                    VStack(alignment: .leading, spacing: 10) {
                        Text("OPTIONS")
                            .font(.quicksandSemiBold(10))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1.5)
                        
                        Toggle("Include Trade List", isOn: $includeTrades)
                            .toggleStyle(.switch)
                            .tint(.potomacYellow)
                        
                        Toggle("Include Charts", isOn: $includeCharts)
                            .toggleStyle(.switch)
                            .tint(.potomacYellow)
                    }
                    
                    Spacer()
                    
                    // Export button
                    Button {
                        // Export logic here
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                            Text("EXPORT")
                                .font(.rajdhaniBold(14))
                                .tracking(2)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.potomacYellow)
                        .cornerRadius(12)
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("EXPORT BACKTEST")
                        .font(.rajdhaniBold(14))
                        .foregroundColor(.white)
                        .tracking(2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.potomacYellow)
                }
            }
        }
    }
}

// MARK: - Export Format

enum ExportFormat: String, CaseIterable {
    case pdf = "PDF"
    case csv = "CSV"
    case json = "JSON"
    
    var icon: String {
        switch self {
        case .pdf: return "doc.fill"
        case .csv: return "tablecells"
        case .json: return "curlybraces"
        }
    }
}