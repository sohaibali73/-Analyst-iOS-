import SwiftUI

struct ResearcherView: View {
    @State private var viewModel = ResearcherViewModel()
    @FocusState private var tickerFocused: Bool

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                Divider().background(Color.white.opacity(0.07))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Error banner
                        if let error = viewModel.error {
                            errorBanner(error)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                        }

                        // Search section
                        searchSection
                            .padding(.horizontal, 20)
                            .padding(.top, viewModel.error == nil ? 20 : 0)

                        // Toggle options
                        optionsSection
                            .padding(.horizontal, 20)

                        // Research button
                        researchButton
                            .padding(.horizontal, 20)

                        // Results or empty state
                        if viewModel.isLoading {
                            loadingSection
                                .padding(.horizontal, 20)
                        } else if let results = viewModel.results {
                            resultsSection(results)
                                .padding(.horizontal, 20)
                        } else {
                            emptyState
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                        }

                        // Recent searches
                        if !viewModel.recentSearches.isEmpty && viewModel.results == nil && !viewModel.isLoading {
                            recentSearchesSection
                                .padding(.horizontal, 20)
                        }

                        Spacer().frame(height: 120)
                    }
                }
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .onTapGesture { tickerFocused = false }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Spacer()
            Text("RESEARCHER")
                .font(.custom("Rajdhani-Bold", size: 16))
                .foregroundColor(.white)
                .tracking(3)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Search Section

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("COMPANY TICKER")
                .font(.custom("Quicksand-SemiBold", size: 10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)

            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.3))

                TextField("e.g. AAPL", text: $viewModel.ticker)
                    .focused($tickerFocused)
                    .font(.custom("Quicksand-Regular", size: 15))
                    .foregroundColor(.white)
                    #if os(iOS)
                    .autocapitalization(.allCharacters)
                    .keyboardType(.asciiCapable)
                    #endif
                    .autocorrectionDisabled()
                    .onSubmit {
                        Task { await viewModel.research() }
                    }

                if !viewModel.ticker.isEmpty {
                    Button {
                        viewModel.ticker = ""
                        viewModel.results = nil
                        viewModel.error = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        tickerFocused ? Color.potomacYellow.opacity(0.8) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
        }
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(spacing: 10) {
            toggleRow(
                icon: "newspaper",
                title: "Include News",
                subtitle: "Latest headlines & sentiment",
                isOn: Binding(
                    get: { viewModel.includeNews },
                    set: { viewModel.includeNews = $0 }
                )
            )

            toggleRow(
                icon: "doc.text",
                title: "Include Filings",
                subtitle: "SEC filings & reports",
                isOn: Binding(
                    get: { viewModel.includeFilings },
                    set: { viewModel.includeFilings = $0 }
                )
            )

            toggleRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "Include Technicals",
                subtitle: "Support, resistance & indicators",
                isOn: Binding(
                    get: { viewModel.includeTechnicals },
                    set: { viewModel.includeTechnicals = $0 }
                )
            )
        }
    }

    @ViewBuilder
    private func toggleRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.potomacYellow.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.potomacYellow)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Quicksand-SemiBold", size: 13))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.custom("Quicksand-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.35))
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.potomacYellow)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Research Button

    private var researchButton: some View {
        Button {
            tickerFocused = false
            Task { await viewModel.research() }
        } label: {
            HStack(spacing: 10) {
                if viewModel.isLoading {
                    ProgressView().tint(.black).scaleEffect(0.85)
                } else {
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(viewModel.isLoading ? "RESEARCHING..." : "RESEARCH")
                    .font(.custom("Rajdhani-Bold", size: 17))
                    .tracking(2)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                viewModel.ticker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading
                    ? Color.potomacYellow.opacity(0.5)
                    : Color.potomacYellow
            )
            .cornerRadius(12)
        }
        .disabled(viewModel.ticker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
    }

    // MARK: - Loading Section

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color.potomacYellow)
                .scaleEffect(1.2)

            Text("Analyzing \(viewModel.ticker.uppercased())...")
                .font(.custom("Quicksand-Regular", size: 14))
                .foregroundColor(.white.opacity(0.4))

            Text("Gathering news, filings & technicals")
                .font(.custom("Quicksand-Regular", size: 12))
                .foregroundColor(.white.opacity(0.25))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.potomacYellow.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "building.2.crop.circle")
                    .font(.system(size: 36))
                    .foregroundColor(Color.potomacYellow.opacity(0.5))
            }

            VStack(spacing: 6) {
                Text("Company Research")
                    .font(.custom("Rajdhani-Bold", size: 20))
                    .foregroundColor(.white)
                    .tracking(1)

                Text("Enter a ticker symbol to get AI-powered\nresearch including news, filings & technicals")
                    .font(.custom("Quicksand-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            // Quick tickers
            HStack(spacing: 8) {
                ForEach(["AAPL", "TSLA", "MSFT", "NVDA"], id: \.self) { t in
                    Button {
                        viewModel.ticker = t
                    } label: {
                        Text(t)
                            .font(.custom("Quicksand-SemiBold", size: 12))
                            .foregroundColor(Color.potomacYellow)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color.potomacYellow.opacity(0.1))
                            .cornerRadius(20)
                            .overlay(
                                Capsule().stroke(Color.potomacYellow.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 32)
    }

    // MARK: - Recent Searches

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("RECENT SEARCHES")
                    .font(.custom("Quicksand-SemiBold", size: 10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)
                Spacer()
                Button {
                    viewModel.clearRecentSearches()
                } label: {
                    Text("Clear")
                        .font(.custom("Quicksand-SemiBold", size: 11))
                        .foregroundColor(Color.potomacYellow.opacity(0.6))
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.recentSearches, id: \.self) { search in
                        Button {
                            viewModel.selectRecentSearch(search)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 10))
                                Text(search)
                                    .font(.custom("Quicksand-SemiBold", size: 12))
                            }
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(20)
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Results Section

    @ViewBuilder
    private func resultsSection(_ results: ResearchResults) -> some View {
        VStack(spacing: 16) {
            // Company header
            if let name = results.companyName ?? results.ticker {
                VStack(spacing: 4) {
                    Text(name.uppercased())
                        .font(.custom("Rajdhani-Bold", size: 22))
                        .foregroundColor(.white)
                        .tracking(2)

                    if let ticker = results.ticker, results.companyName != nil {
                        Text(ticker)
                            .font(.custom("Quicksand-SemiBold", size: 13))
                            .foregroundColor(Color.potomacYellow)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.04))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.potomacYellow.opacity(0.15), lineWidth: 1)
                )
            }

            // Summary
            if let summary = results.summary, !summary.isEmpty {
                resultCard(title: "SUMMARY", icon: "text.alignleft") {
                    Text(summary)
                        .font(.custom("Quicksand-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .lineSpacing(3)
                }
            }

            // Technicals
            if let technicals = results.technicals {
                technicalsCard(technicals)
            }

            // News
            if let news = results.news, !news.isEmpty {
                resultCard(title: "NEWS", icon: "newspaper") {
                    VStack(spacing: 10) {
                        ForEach(news) { item in
                            newsRow(item)
                        }
                    }
                }
            }

            // Filings
            if let filings = results.filings, !filings.isEmpty {
                resultCard(title: "FILINGS", icon: "doc.text") {
                    VStack(spacing: 10) {
                        ForEach(filings) { filing in
                            filingRow(filing)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Result Card

    @ViewBuilder
    private func resultCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(Color.potomacYellow)
                Text(title)
                    .font(.custom("Quicksand-SemiBold", size: 10))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1.5)
            }

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Technicals Card

    @ViewBuilder
    private func technicalsCard(_ technicals: ResearchTechnicals) -> some View {
        resultCard(title: "TECHNICAL ANALYSIS", icon: "chart.line.uptrend.xyaxis") {
            VStack(spacing: 12) {
                // Trend & RSI
                HStack(spacing: 12) {
                    if let trend = technicals.trend {
                        StatPill(
                            label: "Trend",
                            value: trend.capitalized,
                            color: trend.lowercased().contains("bull") ? .green : (trend.lowercased().contains("bear") ? .red : Color.potomacYellow)
                        )
                    }
                    if let rsi = technicals.rsi {
                        StatPill(
                            label: "RSI",
                            value: String(format: "%.1f", rsi),
                            color: rsi > 70 ? .red : (rsi < 30 ? .green : Color.potomacTurquoise)
                        )
                    }
                    if let signal = technicals.macdSignal {
                        StatPill(label: "MACD", value: signal.capitalized, color: Color(hex: "A78BFA"))
                    }
                }

                // Support & Resistance
                HStack(spacing: 12) {
                    if let support = technicals.support {
                        techLevel(label: "Support", value: support, color: .green)
                    }
                    if let resistance = technicals.resistance {
                        techLevel(label: "Resistance", value: resistance, color: .red)
                    }
                }

                // Moving Averages
                if let ma = technicals.movingAverages {
                    HStack(spacing: 12) {
                        if let sma20 = ma.sma20 {
                            techLevel(label: "SMA 20", value: sma20, color: Color.potomacTurquoise)
                        }
                        if let sma50 = ma.sma50 {
                            techLevel(label: "SMA 50", value: sma50, color: Color.potomacYellow)
                        }
                        if let sma200 = ma.sma200 {
                            techLevel(label: "SMA 200", value: sma200, color: Color(hex: "A78BFA"))
                        }
                    }
                }

                // Summary
                if let summary = technicals.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.custom("Quicksand-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .lineSpacing(2)
                }
            }
        }
    }

    @ViewBuilder
    private func techLevel(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.custom("Quicksand-Regular", size: 10))
                .foregroundColor(.white.opacity(0.35))
            Text(String(format: "$%.2f", value))
                .font(.custom("Quicksand-SemiBold", size: 13))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .cornerRadius(8)
    }

    // MARK: - News Row

    @ViewBuilder
    private func newsRow(_ item: ResearchNewsItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = item.title {
                Text(title)
                    .font(.custom("Quicksand-SemiBold", size: 13))
                    .foregroundColor(.white)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                if let source = item.source {
                    Text(source)
                        .font(.custom("Quicksand-Regular", size: 11))
                        .foregroundColor(Color.potomacYellow.opacity(0.7))
                }
                if let date = item.date {
                    Text(date)
                        .font(.custom("Quicksand-Regular", size: 11))
                        .foregroundColor(.white.opacity(0.3))
                }
                if let sentiment = item.sentiment {
                    Text(sentiment.capitalized)
                        .font(.custom("Quicksand-SemiBold", size: 10))
                        .foregroundColor(sentimentColor(sentiment))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(sentimentColor(sentiment).opacity(0.15))
                        .cornerRadius(4)
                }
            }

            if let summary = item.summary {
                Text(summary)
                    .font(.custom("Quicksand-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.45))
                    .lineLimit(3)
                    .lineSpacing(2)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }

    private func sentimentColor(_ sentiment: String) -> Color {
        switch sentiment.lowercased() {
        case "positive", "bullish": return .green
        case "negative", "bearish": return .red
        default: return .white.opacity(0.5)
        }
    }

    // MARK: - Filing Row

    @ViewBuilder
    private func filingRow(_ filing: ResearchFiling) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.potomacTurquoise.opacity(0.12))
                    .frame(width: 36, height: 36)
                Text(filing.type ?? "DOC")
                    .font(.custom("Quicksand-SemiBold", size: 9))
                    .foregroundColor(Color.potomacTurquoise)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(filing.title ?? "Filing")
                    .font(.custom("Quicksand-SemiBold", size: 13))
                    .foregroundColor(.white)
                    .lineLimit(1)
                if let date = filing.date {
                    Text(date)
                        .font(.custom("Quicksand-Regular", size: 11))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            Spacer()

            if filing.url != nil {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.25))
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }

    // MARK: - Error Banner

    @ViewBuilder
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.custom("Quicksand-Regular", size: 13))
                .foregroundColor(.red.opacity(0.9))
                .lineLimit(2)
            Spacer()
            Button { viewModel.error = nil } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.6))
            }
        }
        .padding(12)
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ResearcherView()
    }
    .preferredColorScheme(.dark)
}
