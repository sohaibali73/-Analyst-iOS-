import SwiftUI

struct MetricsGridView: View {
    let metrics: BacktestMetrics

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            MetricCard(
                label: "CAGR",
                value: formatPercent(metrics.cagr),
                color: metricColor(metrics.cagr, positiveIsGood: true)
            )
            MetricCard(
                label: "SHARPE RATIO",
                value: formatDecimal(metrics.sharpeRatio),
                color: metricColor(metrics.sharpeRatio, positiveIsGood: true)
            )
            MetricCard(
                label: "MAX DRAWDOWN",
                value: formatPercent(metrics.maxDrawdown),
                color: drawdownColor(metrics.maxDrawdown)
            )
            MetricCard(
                label: "WIN RATE",
                value: formatPercent(metrics.winRate),
                color: winRateColor(metrics.winRate)
            )
            MetricCard(
                label: "PROFIT FACTOR",
                value: formatDecimal(metrics.profitFactor),
                color: profitFactorColor(metrics.profitFactor)
            )
            MetricCard(
                label: "TOTAL TRADES",
                value: formatInt(metrics.totalTrades),
                color: Color.potomacYellow
            )
        }
    }

    // MARK: - Formatters

    private func formatPercent(_ value: Double?) -> String {
        guard let value = value else { return "—" }
        return String(format: "%.2f%%", value)
    }

    private func formatDecimal(_ value: Double?) -> String {
        guard let value = value else { return "—" }
        return String(format: "%.2f", value)
    }

    private func formatInt(_ value: Int?) -> String {
        guard let value = value else { return "—" }
        return "\(value)"
    }

    // MARK: - Color Logic

    private func metricColor(_ value: Double?, positiveIsGood: Bool) -> Color {
        guard let value = value else { return .white.opacity(0.5) }
        if positiveIsGood {
            return value >= 0 ? Color(hex: "22C55E") : Color(hex: "DC2626")
        } else {
            return value <= 0 ? Color(hex: "22C55E") : Color(hex: "DC2626")
        }
    }

    private func drawdownColor(_ value: Double?) -> Color {
        guard let value = value else { return .white.opacity(0.5) }
        let absVal = abs(value)
        if absVal < 10 { return Color(hex: "22C55E") }
        else if absVal < 25 { return Color(hex: "F97316") }
        else { return Color(hex: "DC2626") }
    }

    private func winRateColor(_ value: Double?) -> Color {
        guard let value = value else { return .white.opacity(0.5) }
        if value >= 50 { return Color(hex: "22C55E") }
        else if value >= 40 { return Color(hex: "F97316") }
        else { return Color(hex: "DC2626") }
    }

    private func profitFactorColor(_ value: Double?) -> Color {
        guard let value = value else { return .white.opacity(0.5) }
        if value >= 1.5 { return Color(hex: "22C55E") }
        else if value >= 1.0 { return Color(hex: "F97316") }
        else { return Color(hex: "DC2626") }
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.custom("Quicksand-SemiBold", size: 9))
                .foregroundColor(.white.opacity(0.35))
                .tracking(1.5)

            Text(value)
                .font(.custom("Rajdhani-Bold", size: 26))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}
