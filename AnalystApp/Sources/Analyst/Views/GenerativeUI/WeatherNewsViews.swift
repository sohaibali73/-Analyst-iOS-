import SwiftUI

// MARK: - Weather Card View

struct WeatherCardResult {
    let city: String
    let country: String?
    let temperature: Double
    let feelsLike: Double?
    let condition: String
    let description: String?
    let humidity: Int?
    let windSpeed: Double?
    let windDirection: String?
    let visibility: Double?
    let pressure: Double?
    let uvIndex: Int?
    let sunrise: String?
    let sunset: String?
    let forecast: [ForecastDay]
    let unit: String
    let success: Bool
    let error: String?
    
    static func from(toolCall: ToolCall) -> WeatherCardResult {
        let args = toolCall.argumentsDict
        let result = toolCall.resultDict
        
        var forecastDays: [ForecastDay] = []
        if let forecastArray = result["forecast"] as? [[String: Any]] {
            forecastDays = forecastArray.compactMap { ForecastDay.from(dict: $0) }
        }
        
        return WeatherCardResult(
            city: args["city"] as? String ?? result["city"] as? String ?? result["location"] as? String ?? "Unknown",
            country: result["country"] as? String,
            temperature: ToolCall.num("temperature", from: result) ?? 0,
            feelsLike: ToolCall.num("feels_like", from: result),
            condition: result["condition"] as? String ?? result["condition_text"] as? String ?? "Unknown",
            description: result["description"] as? String ?? result["condition_text"] as? String,
            humidity: ToolCall.int("humidity", from: result),
            windSpeed: ToolCall.num("wind_speed", from: result),
            windDirection: result["wind_direction"] as? String,
            visibility: ToolCall.num("visibility", from: result),
            pressure: ToolCall.num("pressure", from: result),
            uvIndex: ToolCall.int("uv_index", from: result),
            sunrise: result["sunrise"] as? String,
            sunset: result["sunset"] as? String,
            forecast: forecastDays,
            unit: result["unit"] as? String ?? ((result["temp_unit"] as? String)?.contains("C") == true ? "C" : "F"),
            success: result["success"] as? Bool ?? true,
            error: result["error"] as? String
        )
    }
}

struct ForecastDay {
    let date: String
    let day: String
    let high: Double
    let low: Double
    let condition: String
    let precipitationChance: Int?
    
    static func from(dict: [String: Any]) -> ForecastDay? {
        guard let date = dict["date"] as? String else { return nil }
        
        return ForecastDay(
            date: date,
            day: dict["day"] as? String ?? "",
            high: ToolCall.num("high", from: dict) ?? 0,
            low: ToolCall.num("low", from: dict) ?? 0,
            condition: dict["condition"] as? String ?? "Unknown",
            precipitationChance: ToolCall.int("precipitation_chance", from: dict)
        )
    }
}

struct WeatherCardView: View {
    let result: WeatherCardResult
    
    private var conditionConfig: (icon: String, gradient: [Color], accent: Color) {
        switch result.condition.lowercased().replacingOccurrences(of: " ", with: "_") {
        case "sunny", "clear":
            return ("sun.fill", [Color(hex: "F59E0B"), Color(hex: "D97706"), Color(hex: "B45309")], Color(hex: "FCD34D"))
        case "cloudy", "overcast":
            return ("cloud.fill", [Color(hex: "374151"), Color(hex: "1F2937"), Color(hex: "111827")], Color(hex: "9CA3AF"))
        case "partly_cloudy", "partly cloudy":
            return ("cloud.sun.fill", [Color(hex: "1E3A5F"), Color(hex: "374151"), Color(hex: "1F2937")], Color(hex: "60A5FA"))
        case "rainy", "rain", "light_rain":
            return ("cloud.rain.fill", [Color(hex: "1E3A5F"), Color(hex: "1e293b"), Color(hex: "0f172a")], Color(hex: "60A5FA"))
        case "snow", "snowy":
            return ("cloud.snow.fill", [Color(hex: "e2e8f0"), Color(hex: "94a3b8"), Color(hex: "64748b")], Color(hex: "E2E8F0"))
        case "thunderstorm", "thunder":
            return ("cloud.bolt.rain.fill", [Color(hex: "1e1b4b"), Color(hex: "312e81"), Color(hex: "1e1b4b")], Color(hex: "A78BFA"))
        case "windy", "wind":
            return ("wind", [Color(hex: "134e4a"), Color(hex: "115e59"), Color(hex: "0f766e")], Color(hex: "5EEAD4"))
        default:
            return ("cloud.fill", [Color(hex: "374151"), Color(hex: "1F2937"), Color(hex: "111827")], Color(hex: "9CA3AF"))
        }
    }
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "Weather Error", error: error)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Main weather section
                ZStack {
                    LinearGradient(
                        colors: conditionConfig.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Background icon
                    Image(systemName: conditionConfig.icon)
                        .font(.system(size: 140))
                        .foregroundColor(.white.opacity(0.08))
                        .offset(x: 80, y: -40)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.city)
                                    .font(.quicksandBold(20))
                                    .foregroundColor(.white)
                                
                                if let country = result.country {
                                    Text(country)
                                        .font(.quicksandRegular(12))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: conditionConfig.icon)
                                .font(.system(size: 40))
                                .foregroundColor(conditionConfig.accent)
                        }
                        .padding(24)
                        
                        // Temperature
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(String(format: "%.0f", result.temperature))
                                .font(.system(size: 56, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                            
                            Text("°\(result.unit)")
                                .font(.system(size: 24, weight: .regular))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 24)
                        
                        Text(result.condition.capitalized)
                            .font(.quicksandSemiBold(14))
                            .foregroundColor(conditionConfig.accent)
                            .padding(.horizontal, 24)
                        
                        if let feelsLike = result.feelsLike {
                            Text("Feels like \(String(format: "%.0f", feelsLike))°\(result.unit)")
                                .font(.quicksandRegular(12))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 24)
                                .padding(.bottom, 16)
                        }
                    }
                }
                .frame(height: 200)
                
                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 1) {
                    if let humidity = result.humidity {
                        WeatherStatItem(icon: "drop.fill", label: "Humidity", value: "\(humidity)%", color: conditionConfig.accent)
                    }
                    if let windSpeed = result.windSpeed {
                        WeatherStatItem(icon: "wind", label: "Wind", value: "\(Int(windSpeed)) mph", color: conditionConfig.accent)
                    }
                    if let visibility = result.visibility {
                        WeatherStatItem(icon: "eye.fill", label: "Visibility", value: "\(Int(visibility)) mi", color: conditionConfig.accent)
                    }
                    if let uvIndex = result.uvIndex {
                        WeatherStatItem(icon: "sun.max.fill", label: "UV Index", value: "\(uvIndex)", color: conditionConfig.accent)
                    }
                    if let sunrise = result.sunrise {
                        WeatherStatItem(icon: "sunrise.fill", label: "Sunrise", value: sunrise, color: Color(hex: "FCD34D"))
                    }
                    if let sunset = result.sunset {
                        WeatherStatItem(icon: "sunset.fill", label: "Sunset", value: sunset, color: Color(hex: "FB923C"))
                    }
                }
                .background(Color.black.opacity(0.2))
                
                // Forecast
                if !result.forecast.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(result.forecast.count)-DAY FORECAST")
                            .font(.quicksandSemiBold(11))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1)
                        
                        HStack(spacing: 4) {
                            ForEach(Array(result.forecast.enumerated()), id: \.element.date) { index, day in
                                ForecastDayView(day: day, isToday: index == 0, accent: conditionConfig.accent)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
        }
    }
}

struct WeatherStatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            
            Text(value)
                .font(.quicksandSemiBold(14))
                .foregroundColor(.white)
            
            Text(label.uppercased())
                .font(.quicksandRegular(10))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.2))
    }
}

struct ForecastDayView: View {
    let day: ForecastDay
    let isToday: Bool
    let accent: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(day.day.isEmpty ? day.date : day.day)
                .font(.quicksandSemiBold(11))
                .foregroundColor(isToday ? .white : .white.opacity(0.6))
            
            Image(systemName: weatherIcon(for: day.condition))
                .font(.system(size: 16))
                .foregroundColor(accent)
            
            Text(String(format: "%.0f°", day.high))
                .font(.quicksandSemiBold(13))
                .foregroundColor(.white)
            
            Text(String(format: "%.0f°", day.low))
                .font(.quicksandRegular(11))
                .foregroundColor(.white.opacity(0.4))
            
            if let precip = day.precipitationChance, precip > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 8))
                    Text("\(precip)%")
                        .font(.quicksandRegular(10))
                }
                .foregroundColor(Color(hex: "60A5FA"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(isToday ? Color.white.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func weatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case "sunny", "clear": return "sun.fill"
        case "cloudy", "overcast": return "cloud.fill"
        case "partly_cloudy", "partly cloudy": return "cloud.sun.fill"
        case "rainy", "rain": return "cloud.rain.fill"
        case "snow", "snowy": return "cloud.snow.fill"
        case "thunderstorm", "thunder": return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }
}

// MARK: - News Headlines View

struct NewsHeadlinesResult {
    let headlines: [NewsArticle]
    let query: String?
    let category: String?
    let totalResults: Int?
    let marketSentiment: String?
    let lastUpdated: String?
    let success: Bool
    let error: String?
    
    static func from(toolCall: ToolCall) -> NewsHeadlinesResult {
        let args = toolCall.argumentsDict
        let result = toolCall.resultDict
        
        var articles: [NewsArticle] = []
        if let headlinesArray = result["headlines"] as? [[String: Any]] {
            articles = headlinesArray.compactMap { NewsArticle.from(dict: $0) }
        } else if let articlesArray = result["articles"] as? [[String: Any]] {
            articles = articlesArray.compactMap { NewsArticle.from(dict: $0) }
        }
        
        return NewsHeadlinesResult(
            headlines: articles,
            query: args["query"] as? String ?? result["query"] as? String,
            category: result["category"] as? String,
            totalResults: result["total_results"] as? Int ?? articles.count,
            marketSentiment: result["market_sentiment"] as? String,
            lastUpdated: result["last_updated"] as? String,
            success: result["success"] as? Bool ?? true,
            error: result["error"] as? String
        )
    }
}

struct NewsArticle {
    let title: String
    let source: String
    let url: String?
    let publishedAt: String?
    let summary: String?
    let sentiment: String
    let category: String?
    
    static func from(dict: [String: Any]) -> NewsArticle? {
        guard let title = dict["title"] as? String else { return nil }
        
        return NewsArticle(
            title: title,
            source: dict["source"] as? String ?? dict["source_name"] as? String ?? "",
            url: dict["url"] as? String ?? dict["link"] as? String,
            publishedAt: dict["published_at"] as? String ?? dict["published"] as? String ?? dict["date"] as? String,
            summary: dict["summary"] as? String ?? dict["description"] as? String,
            sentiment: dict["sentiment"] as? String ?? "neutral",
            category: dict["category"] as? String
        )
    }
}

struct NewsHeadlinesView: View {
    let result: NewsHeadlinesResult
    
    @State private var expandedArticle: Int?
    @State private var showAll = false
    
    private var visibleArticles: [NewsArticle] {
        showAll ? result.headlines : Array(result.headlines.prefix(5))
    }
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "News Error", error: error)
        } else if result.headlines.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "newspaper")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.3))
                Text("No news articles found\(result.query != nil ? " for \"\(result.query!)\"" : "")")
                    .font(.quicksandRegular(13))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "newspaper")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.potomacYellow)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.query != nil ? "News: \(result.query!)" : result.category != nil ? "\(result.category!) News" : "Market News")
                            .font(.quicksandSemiBold(16))
                            .foregroundColor(.white)
                        
                        Text("\(result.totalResults ?? result.headlines.count) articles")
                            .font(.quicksandRegular(11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    Spacer()
                    
                    if let sentiment = result.marketSentiment {
                        HStack(spacing: 4) {
                            Image(systemName: sentiment.lowercased() == "bullish" ? "arrow.up" : sentiment.lowercased() == "bearish" ? "arrow.down" : "minus")
                                .font(.system(size: 12, weight: .semibold))
                            Text(sentiment.capitalized)
                                .font(.quicksandSemiBold(12))
                        }
                        .foregroundColor(sentimentColor(sentiment))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(sentimentColor(sentiment).opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
                .padding(20)
                
                Divider().overlay(Color.white.opacity(0.06))
                
                // Articles
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(visibleArticles.enumerated()), id: \.element.title) { index, article in
                            ArticleRow(
                                article: article,
                                isExpanded: expandedArticle == index,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        expandedArticle = expandedArticle == index ? nil : index
                                    }
                                }
                            )
                            
                            if index < visibleArticles.count - 1 {
                                Divider().overlay(Color.white.opacity(0.04))
                            }
                        }
                    }
                }
                .frame(maxHeight: 400)
                
                // Show more button
                if result.headlines.count > 5 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAll.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: showAll ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12))
                            Text(showAll ? "Show Less" : "Show All \(result.headlines.count) Articles")
                                .font(.quicksandSemiBold(12))
                        }
                        .foregroundColor(.potomacYellow)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .background(Color.white.opacity(0.03))
                }
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "0f0f1a"), Color(hex: "1a1a2e")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
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

struct ArticleRow: View {
    let article: NewsArticle
    let isExpanded: Bool
    let onTap: () -> Void
    
    private var sentimentStyle: (color: Color, bg: Color) {
        switch article.sentiment.lowercased() {
        case "positive": return (.chartGreen, Color.chartGreen.opacity(0.1))
        case "negative": return (.chartRed, Color.chartRed.opacity(0.1))
        default: return (.gray, Color.gray.opacity(0.1))
        }
    }
    
    private var categoryColor: Color {
        switch (article.category ?? "").lowercased() {
        case "earnings": return .potomacYellow
        case "markets": return .chartBlue
        case "crypto": return .chartPurple
        case "economy": return .chartGreen
        case "tech": return Color(hex: "818CF8")
        case "politics": return .chartRed
        default: return .gray
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 10) {
                // Sentiment dot
                Circle()
                    .fill(sentimentStyle.color)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(article.title)
                        .font(.quicksandSemiBold(14))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 10) {
                        Text(article.source)
                            .font(.quicksandSemiBold(11))
                            .foregroundColor(.potomacYellow)
                        
                        if let date = article.publishedAt {
                            HStack(spacing: 3) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(timeAgo(date))
                                    .font(.quicksandRegular(11))
                            }
                            .foregroundColor(.white.opacity(0.4))
                        }
                        
                        if let category = article.category {
                            Text(category)
                                .font(.quicksandSemiBold(10))
                                .foregroundColor(categoryColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(categoryColor.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        
                        Text(article.sentiment.capitalized)
                            .font(.quicksandSemiBold(10))
                            .foregroundColor(sentimentStyle.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(sentimentStyle.bg)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    
                    if isExpanded {
                        if let summary = article.summary {
                            Text(summary)
                                .font(.quicksandRegular(13))
                                .foregroundColor(.white.opacity(0.6))
                                .lineSpacing(4)
                                .padding(.top, 4)
                        }
                        
                        if let url = article.url {
                            Link(destination: URL(string: url) ?? URL(string: "https://example.com")!) {
                                HStack(spacing: 4) {
                                    Text("Read full article")
                                        .font(.quicksandSemiBold(12))
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(.chartBlue)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(isExpanded ? Color.white.opacity(0.03) : Color.clear)
        }
        .buttonStyle(.plain)
    }
    
    private func timeAgo(_ dateStr: String) -> String {
        let formatters: [ISO8601DateFormatter] = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let f2 = ISO8601DateFormatter()
            f2.formatOptions = [.withInternetDateTime]
            return [f, f2]
        }()
        
        for formatter in formatters {
            if let date = formatter.date(from: dateStr) {
                let diff = Date().timeIntervalSince(date)
                let mins = Int(diff / 60)
                if mins < 60 { return "\(mins)m ago" }
                let hours = mins / 60
                if hours < 24 { return "\(hours)h ago" }
                let days = hours / 24
                return "\(days)d ago"
            }
        }
        return dateStr
    }
}

// MARK: - Web Search Results View

struct WebSearchResult {
    let results: [WebSearchItem]
    let query: String?
    let content: String?
    
    static func from(toolCall: ToolCall) -> WebSearchResult {
        let args = toolCall.argumentsDict
        let result = toolCall.resultDict
        
        var items: [WebSearchItem] = []
        if let resultsArray = result["results"] as? [[String: Any]] {
            items = resultsArray.compactMap { WebSearchItem.from(dict: $0) }
        }
        
        return WebSearchResult(
            results: items,
            query: args["query"] as? String ?? result["query"] as? String,
            content: result["content"] as? String
        )
    }
}

struct WebSearchItem {
    let title: String
    let url: String?
    let snippet: String?
    
    static func from(dict: [String: Any]) -> WebSearchItem? {
        guard let title = dict["title"] as? String else { return nil }
        
        return WebSearchItem(
            title: title,
            url: dict["url"] as? String ?? dict["link"] as? String,
            snippet: dict["snippet"] as? String ?? dict["content"] as? String
        )
    }
}

struct WebSearchResultsView: View {
    let result: WebSearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.chartPurple)
                
                Text("Web Search Results")
                    .font(.quicksandSemiBold(13))
                    .foregroundColor(.chartPurple)
                
                if !result.results.isEmpty {
                    Text("\(result.results.count) results")
                        .font(.quicksandSemiBold(11))
                        .foregroundColor(.chartPurple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.chartPurple.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            
            if let query = result.query {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10))
                    Text("\"\(query)\"")
                }
                .font(.quicksandRegular(12))
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            
            if let content = result.content {
                Text(content)
                    .font(.quicksandRegular(13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else if !result.results.isEmpty {
                ForEach(Array(result.results.enumerated()), id: \.element.title) { index, item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text(item.title)
                                .font(.quicksandSemiBold(14))
                                .foregroundColor(Color(hex: "A78BFA"))
                            
                            if let url = item.url, let urlObj = URL(string: url) {
                                Link(destination: urlObj) {
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                            }
                        }
                        
                        if let url = item.url {
                            Text(url)
                                .font(.quicksandRegular(11))
                                .foregroundColor(Color.chartPurple.opacity(0.6))
                                .lineLimit(1)
                        }
                        
                        if let snippet = item.snippet {
                            Text(snippet)
                                .font(.quicksandRegular(12))
                                .foregroundColor(.white.opacity(0.6))
                                .lineSpacing(2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    if index < result.results.count - 1 {
                        Divider().overlay(Color.white.opacity(0.05))
                    }
                }
            } else {
                Text("Search completed. Results integrated into the response.")
                    .font(.quicksandRegular(13))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(16)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "0d1117"), Color(hex: "161b22")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.chartPurple.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Knowledge Base Results View

struct KnowledgeBaseResult {
    let success: Bool
    let error: String?
    let query: String?
    let categoryFilter: String?
    let resultsCount: Int?
    let searchTimeMs: Int?
    let results: [KBDocument]
    
    static func from(toolCall: ToolCall) -> KnowledgeBaseResult {
        let args = toolCall.argumentsDict
        let result = toolCall.resultDict
        
        var docs: [KBDocument] = []
        if let resultsArray = result["results"] as? [[String: Any]] {
            docs = resultsArray.compactMap { KBDocument.from(dict: $0) }
        }
        
        return KnowledgeBaseResult(
            success: result["success"] as? Bool ?? true,
            error: result["error"] as? String,
            query: args["query"] as? String ?? result["query"] as? String,
            categoryFilter: result["category_filter"] as? String,
            resultsCount: result["results_count"] as? Int ?? docs.count,
            searchTimeMs: result["search_time_ms"] as? Int,
            results: docs
        )
    }
}

struct KBDocument {
    let id: String
    let title: String
    let category: String?
    let summary: String?
    let tags: [String]
    let contentSnippet: String?
    
    static func from(dict: [String: Any]) -> KBDocument? {
        guard let id = dict["id"] as? String ?? dict["title"] as? String else { return nil }
        
        return KBDocument(
            id: id,
            title: dict["title"] as? String ?? "",
            category: dict["category"] as? String,
            summary: dict["summary"] as? String,
            tags: dict["tags"] as? [String] ?? [],
            contentSnippet: dict["content_snippet"] as? String
        )
    }
}

struct KnowledgeBaseResultsView: View {
    let result: KnowledgeBaseResult
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "Knowledge Base Error", error: error)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.potomacYellow)
                    
                    Text("KNOWLEDGE BASE")
                        .font(.rajdhaniBold(13))
                        .foregroundColor(.potomacYellow)
                        .tracking(0.5)
                    
                    Text("\(result.resultsCount ?? result.results.count) found")
                        .font(.quicksandSemiBold(11))
                        .foregroundColor(.potomacYellow)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color.potomacYellow.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Spacer()
                    
                    if let time = result.searchTimeMs {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text("\(time)ms")
                        }
                        .font(.quicksandRegular(11))
                        .foregroundColor(.white.opacity(0.35))
                    }
                }
                .padding(18)
                
                // Query
                if let query = result.query {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 10))
                        Text("\"\(query)\"")
                        
                        if let category = result.categoryFilter {
                            Text(category.uppercased())
                                .font(.quicksandSemiBold(11))
                                .foregroundColor(categoryColor(category))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 2)
                                .background(categoryColor(category).opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .font(.quicksandRegular(12))
                    .foregroundColor(.white.opacity(0.45))
                    .padding(.horizontal, 18)
                    .padding(.bottom, 10)
                }
                
                Divider().overlay(Color.white.opacity(0.05))
                
                // Results
                if result.results.isEmpty {
                    Text("No documents found matching your query.")
                        .font(.quicksandRegular(13))
                        .foregroundColor(.white.opacity(0.35))
                        .frame(maxWidth: .infinity)
                        .padding(32)
                } else {
                    ForEach(Array(result.results.enumerated()), id: \.element.id) { index, doc in
                        GenerativeKBDocumentRow(document: doc)
                        
                        if index < result.results.count - 1 {
                            Divider().overlay(Color.white.opacity(0.05))
                        }
                    }
                }
            }
            .background(Color(hex: "0d1117"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.potomacYellow.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private func categoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "afl": return .potomacYellow
        case "strategy": return .chartGreen
        case "indicator": return .chartPurple
        case "documentation": return .chartBlue
        default: return .gray
        }
    }
}

struct GenerativeKBDocumentRow: View {
    let document: KBDocument
    
    private var categoryColor: Color {
        switch (document.category ?? "").lowercased() {
        case "afl": return .potomacYellow
        case "strategy": return .chartGreen
        case "indicator": return .chartPurple
        case "documentation": return .chartBlue
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.45))
                
                Text(document.title)
                    .font(.quicksandSemiBold(14))
                    .foregroundColor(.white)
                
                if let category = document.category {
                    Text(category.uppercased())
                        .font(.quicksandSemiBold(11))
                        .foregroundColor(categoryColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 2)
                        .background(categoryColor.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            
            if let summary = document.summary {
                Text(summary)
                    .font(.quicksandRegular(12))
                    .foregroundColor(.white.opacity(0.55))
                    .lineSpacing(3)
                    .padding(.leading, 22)
            }
            
            if let snippet = document.contentSnippet {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.potomacYellow.opacity(0.25))
                        .frame(width: 2)
                    
                    Text(snippet)
                        .font(.quicksandRegular(12))
                        .foregroundColor(.white.opacity(0.4))
                        .italic()
                        .padding(.leading, 10)
                }
                .padding(.leading, 22)
            }
            
            if !document.tags.isEmpty {
                HStack(spacing: 5) {
                    ForEach(document.tags, id: \.self) { tag in
                        HStack(spacing: 3) {
                            Image(systemName: "tag")
                                .font(.system(size: 8))
                            Text(tag)
                                .font(.quicksandRegular(10))
                        }
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                }
                .padding(.leading, 22)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}