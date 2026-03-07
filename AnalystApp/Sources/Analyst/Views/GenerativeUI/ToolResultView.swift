import SwiftUI

// MARK: - Tool Result View Router

/// Routes tool results to the appropriate SwiftUI view based on tool name
struct ToolResultView: View {
    let toolCall: ToolCall
    
    var body: some View {
        switch toolCall.name {
        // Stock & Market Tools
        case "get_stock_data", "stock_analysis":
            StockCardView(result: StockCardResult.from(toolCall: toolCall))
        case "get_stock_chart":
            LiveStockChartView(result: LiveStockChartResult.from(toolCall: toolCall))
        case "technical_analysis":
            TechnicalAnalysisView(result: TechnicalAnalysisResult.from(toolCall: toolCall))
        case "get_market_overview":
            MarketOverviewView(result: MarketOverviewResult.from(toolCall: toolCall))
        case "screen_stocks":
            StockScreenerView(result: StockScreenerResult.from(toolCall: toolCall))
        case "compare_stocks":
            StockComparisonView(result: StockComparisonResult.from(toolCall: toolCall))
        case "get_sector_performance":
            SectorPerformanceView(result: SectorPerformanceResult.from(toolCall: toolCall))
        case "get_correlation_matrix":
            CorrelationMatrixView(result: CorrelationMatrixResult.from(toolCall: toolCall))
        case "get_dividend_info":
            DividendCardView(result: DividendCardResult.from(toolCall: toolCall))
        case "get_options_snapshot":
            OptionsSnapshotView(result: OptionsSnapshotResult.from(toolCall: toolCall))
        case "calculate_position_size":
            PositionSizerView(result: PositionSizerResult.from(toolCall: toolCall))
        case "calculate_risk_metrics":
            RiskMetricsView(result: RiskMetricsResult.from(toolCall: toolCall))
        case "backtest_quick":
            BacktestResultsView(result: BacktestResultsResult.from(toolCall: toolCall))
            
        // Weather & News
        case "get_weather":
            WeatherCardView(result: WeatherCardResult.from(toolCall: toolCall))
        case "get_news":
            NewsHeadlinesView(result: NewsHeadlinesResult.from(toolCall: toolCall))
            
        // Code Tools
        case "execute_python":
            CodeExecutionView(result: CodeExecutionResult.from(toolCall: toolCall))
        case "code_sandbox":
            CodeSandboxView(result: CodeSandboxResult.from(toolCall: toolCall))
        case "create_chart":
            DataChartView(result: DataChartResult.from(toolCall: toolCall))
            
        // AFL Tools
        case "generate_afl_code":
            AFLGenerateCardView(result: AFLGenerateResult.from(toolCall: toolCall))
        case "validate_afl":
            AFLValidateCardView(result: AFLValidateResult.from(toolCall: toolCall))
        case "debug_afl_code":
            AFLDebugCardView(result: AFLDebugResult.from(toolCall: toolCall))
        case "explain_afl_code":
            AFLExplainCardView(result: AFLExplainResult.from(toolCall: toolCall))
        case "sanity_check_afl":
            AFLSanityCheckCardView(result: AFLSanityCheckResult.from(toolCall: toolCall))
            
        // Knowledge & Search
        case "search_knowledge_base":
            KnowledgeBaseResultsView(result: KnowledgeBaseResult.from(toolCall: toolCall))
        case "web_search":
            WebSearchResultsView(result: WebSearchResult.from(toolCall: toolCall))
            
        // Sports & Misc
        case "get_live_scores":
            LiveSportsScoresView(result: LiveSportsScoresResult.from(toolCall: toolCall))
        case "create_presentation":
            PresentationCardView(result: PresentationCardResult.from(toolCall: toolCall))
            
        // Default fallback
        default:
            RawToolCard(toolCall: toolCall)
        }
    }
}

// MARK: - Raw Tool Card (Fallback)

struct RawToolCard: View {
    let toolCall: ToolCall
    @State private var expanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: toolCall.iconName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(toolCall.iconColor)
                    
                    Text(toolCall.displayTitle)
                        .font(.quicksandSemiBold(12))
                        .foregroundColor(toolCall.iconColor)
                    
                    Spacer()
                    
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.25))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            
            if expanded, let result = toolCall.result {
                Divider().overlay(Color.white.opacity(0.05))
                Text(String(describing: result.value).prefix(300))
                    .font(.firaCode(11))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.black.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

// MARK: - Tool Loading View

struct ToolLoadingView: View {
    let toolName: String
    let input: [String: AnyCodable]?
    
    @State private var isAnimating = false
    
    private var meta: (icon: String, label: String, color: Color) {
        switch toolName {
        case "execute_python": return ("terminal", "Executing Python code...", .chartGreen)
        case "search_knowledge_base": return ("doc.text.magnifyingglass", "Searching knowledge base...", .chartBlue)
        case "get_stock_data", "stock_analysis": return ("chart.line.uptrend.xyaxis", "Fetching stock data...", .potomacYellow)
        case "get_stock_chart": return ("chart.line.uptrend.xyaxis", "Loading stock chart...", .potomacYellow)
        case "technical_analysis": return ("waveform", "Running technical analysis...", .chartPurple)
        case "get_weather": return ("cloud.sun", "Getting weather data...", .chartTurquoise)
        case "get_news": return ("newspaper", "Fetching news headlines...", .chartOrange)
        case "create_chart": return ("chart.bar.fill", "Creating data chart...", .chartPurple)
        case "code_sandbox": return ("chevron.left.forwardslash.chevron.right", "Running code sandbox...", .chartGreen)
        case "web_search": return ("globe", "Searching the web...", .chartPurple)
        case "validate_afl": return ("checkmark.shield", "Validating AFL code...", .chartGreen)
        case "generate_afl_code": return ("wand.and.stars", "Generating AFL code...", .potomacYellow)
        case "debug_afl_code": return ("ladybug", "Debugging AFL code...", .chartPurple)
        case "explain_afl_code": return ("book", "Explaining AFL code...", .chartBlue)
        case "sanity_check_afl": return ("checkmark.shield", "Running AFL sanity check...", .chartGreen)
        case "get_live_scores": return ("sportscourt", "Fetching live scores...", .chartOrange)
        case "get_sector_performance": return ("chart.pie", "Loading sector performance...", .potomacYellow)
        case "compare_stocks": return ("square.on.square", "Comparing stocks...", .potomacYellow)
        case "calculate_position_size": return ("scalemass", "Calculating position size...", .chartGreen)
        case "calculate_risk_metrics": return ("gauge", "Calculating risk metrics...", .chartOrange)
        case "backtest_quick": return ("arrow.triangle.2.circlepath", "Running backtest...", .chartGreen)
        default: return ("wrench.and.screwdriver", "Running \(toolName)...", .potomacYellow)
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(meta.color.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Image(systemName: meta.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(meta.color)
            }
            
            Text(meta.label)
                .font(.quicksandSemiBold(13))
                .foregroundColor(meta.color)
            
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: meta.color))
                .scaleEffect(0.7)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(meta.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(meta.color.opacity(0.2), lineWidth: 1)
        )
    }
}

