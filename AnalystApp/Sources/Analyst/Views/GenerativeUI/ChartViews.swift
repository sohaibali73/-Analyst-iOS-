import SwiftUI
import Charts

// MARK: - Live Stock Chart

struct LiveStockChartResult {
    let symbol: String
    let companyName: String?
    let data: [CandleData]
    let period: String?
    let interval: String?
    let chartType: String
    let currentPrice: Double?
    let change: Double?
    let changePercent: Double?

    static func from(toolCall: ToolCall) -> LiveStockChartResult {
        let args = toolCall.argumentsDict
        let result = toolCall.resultDict
        let candles = (result["data"] as? [[String: Any]] ?? []).compactMap { CandleData.from(dict: $0) }
        return LiveStockChartResult(
            symbol: args["symbol"] as? String ?? result["symbol"] as? String ?? "",
            companyName: result["company_name"] as? String,
            data: candles,
            period: result["period"] as? String ?? "1M",
            interval: result["interval"] as? String ?? "1D",
            chartType: result["chart_type"] as? String ?? "candlestick",
            currentPrice: result["current_price"] as? Double,
            change: result["change"] as? Double,
            changePercent: result["change_percent"] as? Double
        )
    }
}

struct CandleData {
    let date: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int?

    static func from(dict: [String: Any]) -> CandleData? {
        guard let date = dict["date"] as? String,
              let open = dict["open"] as? Double,
              let high = dict["high"] as? Double,
              let low = dict["low"] as? Double,
              let close = dict["close"] as? Double else { return nil }
        return CandleData(date: date, open: open, high: high, low: low, close: close, volume: dict["volume"] as? Int)
    }
}

struct LiveStockChartView: View {
    let result: LiveStockChartResult

    @State private var selectedChartType: ChartType = .candlestick
    @State private var selectedCandle: CandleData?

    enum ChartType: String, CaseIterable {
        case candlestick, line, area
    }

    private var isUp: Bool {
        guard let first = result.data.first, let last = result.data.last else { return true }
        return last.close >= first.open
    }
    private var chartColor: Color { isUp ? .chartGreen : .chartRed }
    private var displayPrice: Double { result.currentPrice ?? result.data.last?.close ?? 0 }
    private var displayChange: Double {
        result.change ?? (result.data.count >= 2 ? (result.data.last?.close ?? 0) - (result.data.first?.open ?? 0) : 0)
    }
    private var displayPercent: Double {
        if let pct = result.changePercent { return pct }
        guard let first = result.data.first else { return 0 }
        return ((result.data.last?.close ?? first.open) - first.open) / first.open * 100
    }
    private var priceRange: (min: Double, max: Double) {
        let prices = result.data.flatMap { [$0.high, $0.low] }
        return (prices.min() ?? 0, prices.max() ?? 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.companyName ?? result.symbol)
                        .font(.quicksandRegular(12))
                        .foregroundColor(.white.opacity(0.5))
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(String(format: "$%.2f", displayPrice))
                            .font(.system(size: 28, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                        HStack(spacing: 3) {
                            Image(systemName: displayChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 12, weight: .semibold))
                            Text(String(format: "%+.2f (%+.2f%%)", displayChange, displayPercent))
                                .font(.quicksandSemiBold(14))
                        }
                        .foregroundColor(chartColor)
                    }
                }
                Spacer()
                // Chart type selector
                HStack(spacing: 4) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Button { selectedChartType = type } label: {
                            Text(type.rawValue.capitalized)
                                .font(.quicksandSemiBold(10))
                                .foregroundColor(selectedChartType == type ? .potomacYellow : .white.opacity(0.4))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(selectedChartType == type ? Color.potomacYellow.opacity(0.15) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }
            .padding(20)

            // Selected candle info
            if let candle = selectedCandle {
                HStack(spacing: 16) {
                    Text(candle.date)
                    Text("O: \(String(format: "%.2f", candle.open))")
                    Text("H: \(String(format: "%.2f", candle.high))").foregroundColor(.chartGreen)
                    Text("L: \(String(format: "%.2f", candle.low))").foregroundColor(.chartRed)
                    Text("C: \(String(format: "%.2f", candle.close))")
                }
                .font(.firaCode(10))
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }

            chartView.frame(height: 180).padding(.horizontal, 8)

            if !result.data.isEmpty {
                volumeView.frame(height: 40).padding(.horizontal, 8)
            }

            // Footer
            HStack {
                Text("\(result.period ?? "1M") · \(result.interval ?? "1D")")
                    .font(.quicksandRegular(11))
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(Color.chartGreen).frame(width: 6, height: 6)
                    Text("Live").font(.quicksandSemiBold(11))
                }
            }
            .foregroundColor(.white.opacity(0.4))
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "0f0f1a"), Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
    }

    @ViewBuilder
    private var chartView: some View {
        if result.data.isEmpty {
            VStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.3))
                Text("No chart data available")
                    .font(.quicksandRegular(13))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        } else {
            GeometryReader { geometry in
                let w = geometry.size.width
                let h = geometry.size.height
                let barW = w / CGFloat(result.data.count)
                let range = priceRange.max - priceRange.min

                ZStack {
                    // Grid lines
                    ForEach([0.25, 0.5, 0.75], id: \.self) { pct in
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: h * (1 - pct)))
                            path.addLine(to: CGPoint(x: w, y: h * (1 - pct)))
                        }
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    }

                    switch selectedChartType {
                    case .candlestick:
                        candlestickCanvas(w: w, h: h, barW: barW, range: range)
                    case .line:
                        lineCanvas(w: w, h: h, barW: barW, range: range, isArea: false)
                    case .area:
                        lineCanvas(w: w, h: h, barW: barW, range: range, isArea: true)
                    }

                    // Touch targets
                    ForEach(Array(result.data.enumerated()), id: \.element.date) { idx, _ in
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: barW, height: h)
                            .position(x: CGFloat(idx) * barW + barW / 2, y: h / 2)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in selectedCandle = result.data[idx] }
                                    .onEnded { _ in selectedCandle = nil }
                            )
                    }

                    // Crosshair
                    if let candle = selectedCandle,
                       let idx = result.data.firstIndex(where: { $0.date == candle.date }) {
                        Path { path in
                            let x = CGFloat(idx) * barW + barW / 2
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: h))
                        }
                        .stroke(Color.potomacYellow.opacity(0.3),
                                style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func candlestickCanvas(w: CGFloat, h: CGFloat, barW: CGFloat, range: Double) -> some View {
        Canvas { ctx, _ in
            for (i, candle) in result.data.enumerated() {
                let x = CGFloat(i) * barW + barW / 2
                let color = candle.close >= candle.open ? Color.chartGreen : Color.chartRed
                let highY = h - ((candle.high - priceRange.min) / range) * h
                let lowY  = h - ((candle.low  - priceRange.min) / range) * h
                let openY = h - ((candle.open - priceRange.min) / range) * h
                let closeY = h - ((candle.close - priceRange.min) / range) * h

                var wick = Path()
                wick.move(to: CGPoint(x: x, y: highY))
                wick.addLine(to: CGPoint(x: x, y: lowY))
                ctx.stroke(wick, with: .color(color), lineWidth: 1)

                let bodyH = max(abs(closeY - openY), 1)
                let bodyRect = CGRect(x: x - 3, y: min(openY, closeY), width: 6, height: bodyH)
                ctx.fill(Path(roundedRect: bodyRect, cornerRadius: 1), with: .color(color))
            }
        }
    }

    @ViewBuilder
    private func lineCanvas(w: CGFloat, h: CGFloat, barW: CGFloat, range: Double, isArea: Bool) -> some View {
        Canvas { ctx, size in
            var line = Path()
            var area = Path()

            for (i, candle) in result.data.enumerated() {
                let x = CGFloat(i) * barW + barW / 2
                let y = h - ((candle.close - priceRange.min) / range) * h
                if i == 0 {
                    line.move(to: CGPoint(x: x, y: y))
                    area.move(to: CGPoint(x: x, y: h))
                    area.addLine(to: CGPoint(x: x, y: y))
                } else {
                    line.addLine(to: CGPoint(x: x, y: y))
                    area.addLine(to: CGPoint(x: x, y: y))
                }
                if i == result.data.count - 1 {
                    area.addLine(to: CGPoint(x: x, y: h))
                    area.closeSubpath()
                }
            }

            if isArea {
                ctx.fill(area, with: .linearGradient(
                    Gradient(colors: [chartColor.opacity(0.25), chartColor.opacity(0)]),
                    startPoint: CGPoint(x: size.width / 2, y: 0),
                    endPoint: CGPoint(x: size.width / 2, y: size.height)
                ))
            }
            ctx.stroke(line, with: .color(chartColor), lineWidth: 2)

            for (i, candle) in result.data.enumerated() {
                let x = CGFloat(i) * barW + barW / 2
                let y = h - ((candle.close - priceRange.min) / range) * h
                ctx.fill(Path(ellipseIn: CGRect(x: x - 3, y: y - 3, width: 6, height: 6)), with: .color(chartColor))
            }
        }
    }

    @ViewBuilder
    private var volumeView: some View {
        let maxVol = result.data.compactMap(\.volume).max() ?? 1
        HStack(spacing: 2) {
            ForEach(result.data, id: \.date) { candle in
                if let vol = candle.volume {
                    let h = CGFloat(vol) / CGFloat(maxVol) * 35 + 5
                    RoundedRectangle(cornerRadius: 1)
                        .fill((candle.close >= candle.open ? Color.chartGreen : Color.chartRed).opacity(0.3))
                        .frame(width: 6, height: h)
                }
            }
        }
    }
}

// MARK: - Technical Analysis

struct TechnicalAnalysisResult {
    let symbol: String
    let timeframe: String?
    let overallSignal: String
    let summary: String?
    let indicators: TechnicalIndicators
    let supportLevels: [Double]
    let resistanceLevels: [Double]
    let currentPrice: Double?
    let movingAverages: [MovingAverage]

    static func from(toolCall: ToolCall) -> TechnicalAnalysisResult {
        let args = toolCall.argumentsDict
        let result = toolCall.resultDict
        let indicators = (result["indicators"] as? [String: Any]).map { TechnicalIndicators.from(dict: $0) } ?? TechnicalIndicators()
        let movingAverages = (result["moving_averages"] as? [[String: Any]] ?? []).compactMap { MovingAverage.from(dict: $0) }
        return TechnicalAnalysisResult(
            symbol: args["symbol"] as? String ?? result["symbol"] as? String ?? "",
            timeframe: result["timeframe"] as? String ?? "Daily",
            overallSignal: result["overall_signal"] as? String ?? "neutral",
            summary: result["summary"] as? String,
            indicators: indicators,
            supportLevels: result["support_levels"] as? [Double] ?? [],
            resistanceLevels: result["resistance_levels"] as? [Double] ?? [],
            currentPrice: result["current_price"] as? Double,
            movingAverages: movingAverages
        )
    }
}

struct TechnicalIndicators {
    var trend: [IndicatorValue] = []
    var momentum: [IndicatorValue] = []
    var volatility: [IndicatorValue] = []
    var volume: [IndicatorValue] = []

    static func from(dict: [String: Any]) -> TechnicalIndicators {
        func parse(_ key: String) -> [IndicatorValue] {
            (dict[key] as? [[String: Any]] ?? []).compactMap { IndicatorValue.from(dict: $0) }
        }
        return TechnicalIndicators(trend: parse("trend"), momentum: parse("momentum"),
                                   volatility: parse("volatility"), volume: parse("volume"))
    }
}

struct IndicatorValue {
    let name: String
    let value: String
    let signal: String
    let description: String?

    static func from(dict: [String: Any]) -> IndicatorValue? {
        guard let name = dict["name"] as? String else { return nil }
        let value: String
        if let n = dict["value"] as? Double { value = String(format: "%.2f", n) }
        else { value = dict["value"] as? String ?? "—" }
        return IndicatorValue(name: name, value: value,
                              signal: dict["signal"] as? String ?? "neutral",
                              description: dict["description"] as? String)
    }
}

struct MovingAverage {
    let period: String
    let value: Double
    let signal: String

    static func from(dict: [String: Any]) -> MovingAverage? {
        guard let period = dict["period"] as? String,
              let value = dict["value"] as? Double else { return nil }
        return MovingAverage(period: period, value: value, signal: dict["signal"] as? String ?? "neutral")
    }
}

// MARK: - Signal Color Helper

private func signalStyle(for signal: String) -> (bg: Color, text: Color) {
    switch signal.lowercased() {
    case "strong_buy": return (Color.chartGreen.opacity(0.15), Color.chartGreen)
    case "buy":        return (Color.chartGreen.opacity(0.10), Color(hex: "4ADE80"))
    case "sell":       return (Color.chartRed.opacity(0.10),   Color(hex: "F87171"))
    case "strong_sell":return (Color.chartRed.opacity(0.15),   Color.chartRed)
    default:           return (Color.gray.opacity(0.10),       Color.gray)
    }
}

// MARK: - Technical Analysis View

struct TechnicalAnalysisView: View {
    let result: TechnicalAnalysisResult
    @State private var expandedSection: String? = "trend"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            GaugeMeter(signal: result.overallSignal, color: signalStyle(for: result.overallSignal).text)
                .padding(.horizontal, 20)
            summarySection
            supportResistanceSection
            movingAveragesSection
            indicatorSectionsView
        }
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [Color(hex: "0f0f1a"), Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
    }

    @ViewBuilder
    private var headerSection: some View {
        let style = signalStyle(for: result.overallSignal)
        HStack {
            Image(systemName: "waveform").font(.system(size: 16, weight: .medium)).foregroundColor(.chartPurple)
            Text(result.symbol).font(.rajdhaniBold(18)).foregroundColor(.potomacYellow)
            Text(result.timeframe ?? "Daily")
                .font(.quicksandRegular(11)).foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 8).padding(.vertical, 2)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            Spacer()
            Text(result.overallSignal.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.quicksandSemiBold(12)).foregroundColor(style.text)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(style.bg).clipShape(Capsule())
        }
        .padding(20)
    }

    @ViewBuilder
    private var summarySection: some View {
        if let summary = result.summary {
            Text(summary)
                .font(.quicksandRegular(13)).foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
                .padding(.horizontal, 20).padding(.top, 16)
        }
    }

    @ViewBuilder
    private var supportResistanceSection: some View {
        if !result.supportLevels.isEmpty || !result.resistanceLevels.isEmpty {
            HStack(spacing: 12) {
                if !result.resistanceLevels.isEmpty {
                    srColumn(title: "Resistance", levels: result.resistanceLevels,
                             textColor: Color(hex: "F87171"), bgColor: Color.chartRed.opacity(0.08))
                }
                if let price = result.currentPrice {
                    VStack(spacing: 4) {
                        Text("Price").font(.quicksandSemiBold(10)).foregroundColor(.potomacYellow)
                        Text(String(format: "$%.2f", price))
                            .font(.system(size: 16, weight: .heavy, design: .monospaced))
                            .foregroundColor(.potomacYellow)
                    }
                    .frame(maxWidth: .infinity).padding(10)
                    .background(Color.potomacYellow.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                if !result.supportLevels.isEmpty {
                    srColumn(title: "Support", levels: result.supportLevels,
                             textColor: Color(hex: "4ADE80"), bgColor: Color.chartGreen.opacity(0.08))
                }
            }
            .padding(.horizontal, 20).padding(.top, 16)
        }
    }

    @ViewBuilder
    private func srColumn(title: String, levels: [Double], textColor: Color, bgColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.quicksandSemiBold(10)).foregroundColor(textColor)
            ForEach(levels.prefix(3), id: \.self) { level in
                Text(String(format: "$%.2f", level))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(textColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(10)
        .background(bgColor).clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var movingAveragesSection: some View {
        if !result.movingAverages.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(result.movingAverages, id: \.period) { ma in
                        let style = signalStyle(for: ma.signal)
                        Text("\(ma.period): \(String(format: "$%.2f", ma.value))")
                            .font(.quicksandSemiBold(11)).foregroundColor(style.text)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(style.bg).clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 12)
        }
    }

    @ViewBuilder
    private var indicatorSectionsView: some View {
        if !result.indicators.trend.isEmpty {
            indicatorSection("Trend", items: result.indicators.trend, icon: "arrow.up.right", color: .chartBlue, key: "trend")
        }
        if !result.indicators.momentum.isEmpty {
            indicatorSection("Momentum", items: result.indicators.momentum, icon: "gauge", color: .chartPurple, key: "momentum")
        }
        if !result.indicators.volatility.isEmpty {
            indicatorSection("Volatility", items: result.indicators.volatility, icon: "waveform", color: .chartOrange, key: "volatility")
        }
        if !result.indicators.volume.isEmpty {
            indicatorSection("Volume", items: result.indicators.volume, icon: "chart.bar.fill", color: .chartGreen, key: "volume")
        }
    }

    @ViewBuilder
    private func indicatorSection(_ title: String, items: [IndicatorValue], icon: String, color: Color, key: String) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedSection = expandedSection == key ? nil : key
                }
            } label: {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: icon).font(.system(size: 12)).foregroundColor(color)
                        Text(title.uppercased()).font(.quicksandSemiBold(12)).foregroundColor(.white)
                        Text("(\(items.count))").font(.quicksandRegular(11)).foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                    Image(systemName: expandedSection == key ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .medium)).foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 20).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if expandedSection == key {
                VStack(spacing: 4) {
                    ForEach(items, id: \.name) { item in
                        IndicatorRow(indicator: item, style: signalStyle(for: item.signal))
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 12)
            }
        }
    }
}

struct GaugeMeter: View {
    let signal: String
    let color: Color

    private var position: CGFloat {
        switch signal.lowercased() {
        case "strong_sell": return 0.1
        case "sell":        return 0.3
        case "buy":         return 0.7
        case "strong_buy":  return 0.9
        default:            return 0.5
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                LinearGradient(
                    colors: [.chartRed, .chartOrange, .gray, Color(hex: "4ADE80"), .chartGreen],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(height: 8).clipShape(Capsule())

                Circle()
                    .fill(color).frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color(hex: "1a1a2e"), lineWidth: 2))
                    .offset(x: position * geo.size.width - 8)
                    .shadow(color: color, radius: 4)
            }
            .frame(height: 16)
        }
        .frame(height: 16)
    }
}

struct IndicatorRow: View {
    let indicator: IndicatorValue
    let style: (bg: Color, text: Color)

    private var signalIcon: String {
        switch indicator.signal.lowercased() {
        case "buy", "strong_buy":   return "arrow.up"
        case "sell", "strong_sell": return "arrow.down"
        default:                     return "minus"
        }
    }

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: signalIcon).font(.system(size: 10, weight: .semibold)).foregroundColor(style.text)
                Text(indicator.name).font(.quicksandRegular(13)).foregroundColor(.white)
            }
            Spacer()
            HStack(spacing: 10) {
                Text(indicator.value)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundColor(.white)
                Text(indicator.signal.uppercased())
                    .font(.quicksandSemiBold(10)).foregroundColor(style.text)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(style.bg).clipShape(Capsule())
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Data Chart

struct DataChartResult {
    let title: String?
    let subtitle: String?
    let chartType: String
    let data: [ChartDataPoint]
    let series: [ChartSeries]
    let labels: [String]
    let xLabel: String?
    let yLabel: String?
    let showValues: Bool
    let showLegend: Bool

    static func from(toolCall: ToolCall) -> DataChartResult {
        let args = toolCall.argumentsDict
        let result = toolCall.resultDict
        let data = (result["data"] as? [[String: Any]] ?? []).compactMap { ChartDataPoint.from(dict: $0) }
        let series = (result["series"] as? [[String: Any]] ?? []).compactMap { ChartSeries.from(dict: $0) }
        return DataChartResult(
            title: result["title"] as? String,
            subtitle: result["subtitle"] as? String,
            chartType: result["chart_type"] as? String ?? args["chart_type"] as? String ?? "bar",
            data: data, series: series,
            labels: result["labels"] as? [String] ?? [],
            xLabel: result["x_label"] as? String,
            yLabel: result["y_label"] as? String,
            showValues: result["show_values"] as? Bool ?? true,
            showLegend: result["show_legend"] as? Bool ?? true
        )
    }
}

struct ChartDataPoint {
    let label: String
    let value: Double
    let color: Color?

    static func from(dict: [String: Any]) -> ChartDataPoint? {
        guard let label = dict["label"] as? String,
              let value = dict["value"] as? Double else { return nil }
        return ChartDataPoint(label: label, value: value,
                              color: (dict["color"] as? String).map { Color(hex: $0) })
    }
}

struct ChartSeries {
    let name: String
    let data: [Double]
    let color: Color?

    static func from(dict: [String: Any]) -> ChartSeries? {
        guard let name = dict["name"] as? String,
              let data = dict["data"] as? [Double] else { return nil }
        return ChartSeries(name: name, data: data,
                           color: (dict["color"] as? String).map { Color(hex: $0) })
    }
}

struct DataChartView: View {
    let result: DataChartResult
    @State private var isFullscreen = false

    private let defaultColors: [Color] = [
        .potomacYellow, .chartBlue, .chartGreen, .chartPurple, .chartOrange,
        .chartRed, .chartTurquoise, Color(hex: "818CF8"), Color(hex: "FBBF24"), Color(hex: "34D399")
    ]
    private func color(_ i: Int, custom: Color? = nil) -> Color { custom ?? defaultColors[i % defaultColors.count] }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: chartIcon).font(.system(size: 14, weight: .medium)).foregroundColor(.potomacYellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title ?? "Data Chart").font(.quicksandSemiBold(14)).foregroundColor(.white)
                    if let sub = result.subtitle {
                        Text(sub).font(.quicksandRegular(11)).foregroundColor(.white.opacity(0.4))
                    }
                }
                Spacer()
                Button {
                    isFullscreen.toggle()
                } label: {
                    Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                        .padding(6).background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(16)

            Divider().overlay(Color.white.opacity(0.06))

            ScrollView {
                chartContent.padding(16)
            }
            .frame(maxHeight: isFullscreen ? 500 : 300)

            if result.showLegend && result.series.count > 1 {
                Divider().overlay(Color.white.opacity(0.06))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(result.series.enumerated()), id: \.element.name) { i, s in
                            HStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 2).fill(color(i, custom: s.color)).frame(width: 12, height: 3)
                                Text(s.name).font(.quicksandRegular(11)).foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding(12)
                }
            }
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "0f0f1a"), Color(hex: "1a1a2e")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
    }

    @ViewBuilder
    private var chartContent: some View {
        switch result.chartType {
        case "bar":
            BarChartSwiftUI(data: result.data, colors: defaultColors, showValues: result.showValues)
        case "horizontal_bar":
            HorizontalBarChartSwiftUI(data: result.data, colors: defaultColors, showValues: result.showValues)
        case "line":
            if result.series.isEmpty {
                LineChartSwiftUI(data: result.data, labels: result.labels, isArea: false, color: .potomacYellow)
            } else {
                MultiLineChartSwiftUI(series: result.series, labels: result.labels, isArea: false, colors: defaultColors)
            }
        case "area":
            if result.series.isEmpty {
                LineChartSwiftUI(data: result.data, labels: result.labels, isArea: true, color: .potomacYellow)
            } else {
                MultiLineChartSwiftUI(series: result.series, labels: result.labels, isArea: true, colors: defaultColors)
            }
        case "pie":
            PieChartSwiftUI(data: result.data, colors: defaultColors, isDonut: false, showValues: result.showValues)
        case "donut":
            PieChartSwiftUI(data: result.data, colors: defaultColors, isDonut: true, showValues: result.showValues)
        default:
            Text("Unsupported chart type: \(result.chartType)")
                .font(.quicksandRegular(13)).foregroundColor(.white.opacity(0.5))
        }
    }

    private var chartIcon: String {
        switch result.chartType {
        case "bar", "horizontal_bar": return "chart.bar.fill"
        case "line", "area":          return "chart.line.uptrend.xyaxis"
        case "pie", "donut":          return "chart.pie"
        default:                       return "chart.bar"
        }
    }
}

// MARK: - Bar Chart

struct BarChartSwiftUI: View {
    let data: [ChartDataPoint]
    let colors: [Color]
    let showValues: Bool

    @State private var hoveredIndex: Int?
    private var maxValue: Double { data.map(\.value).max() ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(data.enumerated()), id: \.element.label) { i, pt in
                    let h = (pt.value / maxValue) * 160 + 4
                    let c = pt.color ?? colors[i % colors.count]
                    let hovered = hoveredIndex == i

                    VStack(spacing: 4) {
                        if showValues || hovered {
                            Text(String(format: "%.0f", pt.value))
                                .font(.quicksandSemiBold(11)).foregroundColor(c)
                        }
                        RoundedRectangle(cornerRadius: 4).fill(c)
                            .frame(width: 36, height: h)
                            .opacity(hovered ? 1 : 0.85)
                            .shadow(color: hovered ? c.opacity(0.4) : .clear, radius: 4)
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hoveredIndex = hoveredIndex == i ? nil : i
                        }
                    }
                }
            }
            .frame(height: 180)

            HStack(spacing: 6) {
                ForEach(data, id: \.label) { pt in
                    Text(pt.label)
                        .font(.quicksandRegular(10)).foregroundColor(.white.opacity(0.5))
                        .frame(width: 36).lineLimit(1)
                }
            }
        }
    }
}

// MARK: - Horizontal Bar Chart

struct HorizontalBarChartSwiftUI: View {
    let data: [ChartDataPoint]
    let colors: [Color]
    let showValues: Bool

    private var maxValue: Double { data.map(\.value).max() ?? 1 }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(data.enumerated()), id: \.element.label) { i, pt in
                let pct = pt.value / maxValue
                let c = pt.color ?? colors[i % colors.count]

                HStack(spacing: 10) {
                    Text(pt.label)
                        .font(.quicksandRegular(12)).foregroundColor(.white.opacity(0.6))
                        .frame(width: 80, alignment: .trailing).lineLimit(1)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.04))
                            RoundedRectangle(cornerRadius: 4).fill(c)
                                .frame(width: geo.size.width * CGFloat(pct))
                        }
                    }
                    .frame(height: 24)

                    if showValues {
                        Text(String(format: "%.0f", pt.value))
                            .font(.quicksandSemiBold(11)).foregroundColor(.white)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
    }
}

// MARK: - Line Chart

struct LineChartSwiftUI: View {
    let data: [ChartDataPoint]
    let labels: [String]
    let isArea: Bool
    let color: Color

    @State private var selectedPoint: Int?

    private var minValue: Double { data.map(\.value).min() ?? 0 }
    private var maxValue: Double { data.map(\.value).max() ?? 1 }
    private var range: Double { max(maxValue - minValue, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                ZStack {
                    // Grid
                    ForEach([0.25, 0.5, 0.75], id: \.self) { pct in
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: h * (1 - pct)))
                            p.addLine(to: CGPoint(x: w, y: h * (1 - pct)))
                        }
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    }

                    Canvas { ctx, size in
                        let pts = data.enumerated().map { (i, pt) -> CGPoint in
                            CGPoint(
                                x: CGFloat(i) / CGFloat(max(data.count - 1, 1)) * w,
                                y: h - ((pt.value - minValue) / range) * h
                            )
                        }

                        if isArea, let first = pts.first, let last = pts.last {
                            var area = Path()
                            area.move(to: CGPoint(x: first.x, y: h))
                            pts.forEach { area.addLine(to: $0) }
                            area.addLine(to: CGPoint(x: last.x, y: h))
                            area.closeSubpath()
                            ctx.fill(area, with: .linearGradient(
                                Gradient(colors: [color.opacity(0.25), color.opacity(0)]),
                                startPoint: CGPoint(x: size.width / 2, y: 0),
                                endPoint: CGPoint(x: size.width / 2, y: size.height)
                            ))
                        }

                        var line = Path()
                        for (i, pt) in pts.enumerated() {
                            if i == 0 { line.move(to: pt) } else { line.addLine(to: pt) }
                        }
                        ctx.stroke(line, with: .color(color), lineWidth: 2.5)

                        for pt in pts {
                            ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 3, y: pt.y - 3, width: 6, height: 6)), with: .color(color))
                        }
                    }

                    // Tap targets
                    ForEach(Array(data.enumerated()), id: \.element.label) { i, _ in
                        let x = CGFloat(i) / CGFloat(max(data.count - 1, 1)) * w
                        let y = h - ((data[i].value - minValue) / range) * h
                        Circle()
                            .fill(color)
                            .frame(width: selectedPoint == i ? 8 : 6, height: selectedPoint == i ? 8 : 6)
                            .overlay(Circle().stroke(Color(hex: "0f0f1a"), lineWidth: 2))
                            .position(x: x, y: y)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedPoint = selectedPoint == i ? nil : i
                                }
                            }
                    }
                }
            }
            .frame(height: 160)

            if !labels.isEmpty {
                HStack {
                    ForEach(labels, id: \.self) { label in
                        Text(label)
                            .font(.quicksandRegular(10)).foregroundColor(.white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

// MARK: - Multi-Line Chart

struct MultiLineChartSwiftUI: View {
    let series: [ChartSeries]
    let labels: [String]
    let isArea: Bool
    let colors: [Color]

    private var allValues: [Double] { series.flatMap(\.data) }
    private var minValue: Double { allValues.min() ?? 0 }
    private var maxValue: Double { allValues.max() ?? 1 }
    private var range: Double { max(maxValue - minValue, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                ZStack {
                    ForEach([0.25, 0.5, 0.75], id: \.self) { pct in
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: h * (1 - pct)))
                            p.addLine(to: CGPoint(x: w, y: h * (1 - pct)))
                        }
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    }

                    Canvas { ctx, size in
                        for (si, s) in series.enumerated() {
                            let c = s.color ?? colors[si % colors.count]
                            let pts = s.data.enumerated().map { (i, val) -> CGPoint in
                                CGPoint(
                                    x: CGFloat(i) / CGFloat(max(s.data.count - 1, 1)) * w,
                                    y: h - ((val - minValue) / range) * h
                                )
                            }

                            if isArea, let first = pts.first, let last = pts.last {
                                var area = Path()
                                area.move(to: CGPoint(x: first.x, y: h))
                                pts.forEach { area.addLine(to: $0) }
                                area.addLine(to: CGPoint(x: last.x, y: h))
                                area.closeSubpath()
                                ctx.fill(area, with: .linearGradient(
                                    Gradient(colors: [c.opacity(0.2), c.opacity(0)]),
                                    startPoint: CGPoint(x: size.width / 2, y: 0),
                                    endPoint: CGPoint(x: size.width / 2, y: size.height)
                                ))
                            }

                            var line = Path()
                            for (i, pt) in pts.enumerated() {
                                if i == 0 { line.move(to: pt) } else { line.addLine(to: pt) }
                            }
                            ctx.stroke(line, with: .color(c), lineWidth: 2)
                        }
                    }
                }
            }
            .frame(height: 160)

            if !labels.isEmpty {
                HStack {
                    ForEach(labels, id: \.self) { label in
                        Text(label)
                            .font(.quicksandRegular(10)).foregroundColor(.white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

// MARK: - Pie / Donut Chart

struct PieChartSwiftUI: View {
    let data: [ChartDataPoint]
    let colors: [Color]
    let isDonut: Bool
    let showValues: Bool

    @State private var selectedSlice: Int?
    private var total: Double { data.map(\.value).reduce(0, +) }

    var body: some View {
        HStack(spacing: 20) {
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                ZStack {
                    ForEach(Array(slices.enumerated()), id: \.offset) { i, slice in
                        PieSlice(startAngle: slice.startAngle, endAngle: slice.endAngle, color: slice.color)
                            .opacity(selectedSlice == nil || selectedSlice == i ? 1 : 0.4)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedSlice = selectedSlice == i ? nil : i
                                }
                            }
                    }
                    if isDonut {
                        Circle().fill(Color(hex: "0f0f1a")).frame(width: size * 0.45, height: size * 0.45)
                        if let sel = selectedSlice, sel < data.count {
                            VStack(spacing: 2) {
                                Text(String(format: "%.1f%%", data[sel].value / total * 100))
                                    .font(.system(size: 18, weight: .heavy)).foregroundColor(.white)
                                Text(data[sel].label)
                                    .font(.quicksandRegular(10)).foregroundColor(.white.opacity(0.6)).lineLimit(1)
                            }
                        }
                    }
                }
                .frame(width: size, height: size)
            }
            .frame(width: 180, height: 180)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(data.enumerated()), id: \.element.label) { i, pt in
                    let c = pt.color ?? colors[i % colors.count]
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3).fill(c).frame(width: 10, height: 10)
                        Text(pt.label).font(.quicksandRegular(12)).foregroundColor(.white).lineLimit(1)
                        Spacer()
                        Text(showValues ? String(format: "%.0f", pt.value) : String(format: "%.1f%%", pt.value / total * 100))
                            .font(.quicksandSemiBold(12)).foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(selectedSlice == i ? Color.white.opacity(0.05) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSlice = selectedSlice == i ? nil : i
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var slices: [(startAngle: Angle, endAngle: Angle, color: Color)] {
        var result: [(Angle, Angle, Color)] = []
        var start = Angle.degrees(-90)
        for (i, pt) in data.enumerated() {
            let sweep = Angle.degrees(pt.value / total * 360)
            result.append((start, start + sweep, pt.color ?? colors[i % colors.count]))
            start += sweep
        }
        return result
    }
}

struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    let color: Color

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        p.move(to: center)
        p.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        p.closeSubpath()
        return p
    }

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.degrees, endAngle.degrees) }
        set { startAngle = .degrees(newValue.first); endAngle = .degrees(newValue.second) }
    }
}
