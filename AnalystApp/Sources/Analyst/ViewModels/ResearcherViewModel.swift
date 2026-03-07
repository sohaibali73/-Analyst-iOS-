import Foundation
import Observation

@Observable
final class ResearcherViewModel {
    // MARK: - State
    var ticker: String = ""
    var includeNews: Bool = true
    var includeFilings: Bool = true
    var includeTechnicals: Bool = true
    var results: ResearchResults?
    var isLoading: Bool = false
    var error: String?
    var recentSearches: [String] = []

    // MARK: - Dependencies
    private let apiClient: APIClient
    private let hapticManager: HapticManager

    init(apiClient: APIClient = .shared, hapticManager: HapticManager = .shared) {
        self.apiClient = apiClient
        self.hapticManager = hapticManager
        loadRecentSearches()
    }

    // MARK: - Research

    @MainActor
    func research() async {
        let trimmed = ticker.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else { return }

        isLoading = true
        error = nil
        results = nil
        hapticManager.lightImpact()

        do {
            let data = try await apiClient.researchCompany(
                ticker: trimmed,
                includeNews: includeNews,
                includeFilings: includeFilings,
                includeTechnicals: includeTechnicals
            )
            results = data
            addRecentSearch(trimmed)
            hapticManager.success()
        } catch {
            self.error = error.localizedDescription
            hapticManager.error()
        }

        isLoading = false
    }

    // MARK: - Recent Searches

    func selectRecentSearch(_ search: String) {
        ticker = search
    }

    func clearRecentSearches() {
        recentSearches = []
        saveRecentSearches()
    }

    private func addRecentSearch(_ ticker: String) {
        recentSearches.removeAll { $0 == ticker }
        recentSearches.insert(ticker, at: 0)
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }
        saveRecentSearches()
    }

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "recentResearchSearches") ?? []
    }

    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: "recentResearchSearches")
    }
}

// MARK: - Research Models

struct ResearchResults: Codable {
    let ticker: String?
    let companyName: String?
    let summary: String?
    let news: [ResearchNewsItem]?
    let filings: [ResearchFiling]?
    let technicals: ResearchTechnicals?

    enum CodingKeys: String, CodingKey {
        case ticker
        case companyName = "company_name"
        case summary, news, filings, technicals
    }
}

struct ResearchNewsItem: Codable, Identifiable {
    var id: String { title ?? UUID().uuidString }
    let title: String?
    let source: String?
    let date: String?
    let summary: String?
    let url: String?
    let sentiment: String?
}

struct ResearchFiling: Codable, Identifiable {
    var id: String { title ?? UUID().uuidString }
    let title: String?
    let type: String?
    let date: String?
    let url: String?
}

struct ResearchTechnicals: Codable {
    let trend: String?
    let support: Double?
    let resistance: Double?
    let rsi: Double?
    let macdSignal: String?
    let movingAverages: MovingAverages?
    let summary: String?

    enum CodingKeys: String, CodingKey {
        case trend, support, resistance, rsi
        case macdSignal = "macd_signal"
        case movingAverages = "moving_averages"
        case summary
    }
}

struct MovingAverages: Codable {
    let sma20: Double?
    let sma50: Double?
    let sma200: Double?

    enum CodingKeys: String, CodingKey {
        case sma20 = "sma_20"
        case sma50 = "sma_50"
        case sma200 = "sma_200"
    }
}

// MARK: - APIClient Extension

extension APIClient {
    func researchCompany(
        ticker: String,
        includeNews: Bool,
        includeFilings: Bool,
        includeTechnicals: Bool
    ) async throws -> ResearchResults {
        let data = try await performRequest(.get, APIEndpoints.Researcher.company(ticker))
        return try decoder.decode(ResearchResults.self, from: data)
    }
}
