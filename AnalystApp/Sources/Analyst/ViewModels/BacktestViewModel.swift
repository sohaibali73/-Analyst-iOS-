import Foundation
import Observation

@Observable
final class BacktestViewModel {
    // MARK: - State
    var backtestResults: [BacktestResult] = []
    var selectedResult: BacktestResult?
    var isLoading: Bool = false
    var isUploading: Bool = false
    var uploadProgress: Double = 0
    var error: String?
    var uploadSuccess: Bool = false

    // MARK: - Dependencies
    private let apiClient: APIClient
    private let hapticManager: HapticManager

    init(apiClient: APIClient = .shared, hapticManager: HapticManager = .shared) {
        self.apiClient = apiClient
        self.hapticManager = hapticManager
    }

    // MARK: - Load All Backtests

    @MainActor
    func loadBacktests() async {
        isLoading = true
        error = nil

        do {
            backtestResults = try await apiClient.getBacktests()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Upload Backtest

    @MainActor
    func uploadBacktest(data: Data, filename: String, strategyId: String?) async {
        isUploading = true
        uploadProgress = 0
        uploadSuccess = false
        error = nil
        hapticManager.lightImpact()

        // Simulate incremental progress for UX
        Task {
            for i in 1...8 {
                try? await Task.sleep(nanoseconds: 200_000_000)
                uploadProgress = Double(i) / 10.0
            }
        }

        do {
            let result = try await apiClient.uploadBacktest(data: data, filename: filename, strategyId: strategyId)
            uploadProgress = 1.0
            uploadSuccess = true
            hapticManager.success()

            // Prepend the new result
            backtestResults.insert(result, at: 0)
            selectedResult = result

            try? await Task.sleep(nanoseconds: 500_000_000)
        } catch {
            self.error = error.localizedDescription
            hapticManager.error()
        }

        isUploading = false
    }

    // MARK: - Load Single Backtest

    @MainActor
    func loadBacktest(id: String) async {
        isLoading = true
        error = nil

        do {
            let result = try await apiClient.getBacktest(id: id)
            selectedResult = result

            // Update in the list if present
            if let idx = backtestResults.firstIndex(where: { $0.id == id }) {
                backtestResults[idx] = result
            }
            hapticManager.lightImpact()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Delete Backtest

    @MainActor
    func deleteBacktest(_ result: BacktestResult) async {
        do {
            try await apiClient.deleteBacktest(id: result.id)
            backtestResults.removeAll { $0.id == result.id }
            if selectedResult?.id == result.id {
                selectedResult = nil
            }
            hapticManager.lightImpact()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Backtest Models

struct BacktestResult: Codable, Identifiable, Hashable {
    let id: String
    let filename: String?
    let strategyId: String?
    let metrics: BacktestMetrics?
    let aiAnalysis: String?
    let recommendations: [BacktestRecommendation]?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, filename, metrics, recommendations
        case strategyId = "strategy_id"
        case aiAnalysis = "ai_analysis"
        case createdAt = "created_at"
    }
}

struct BacktestMetrics: Codable, Hashable {
    let cagr: Double?
    let sharpeRatio: Double?
    let maxDrawdown: Double?
    let winRate: Double?
    let profitFactor: Double?
    let totalTrades: Int?

    enum CodingKeys: String, CodingKey {
        case cagr
        case sharpeRatio = "sharpe_ratio"
        case maxDrawdown = "max_drawdown"
        case winRate = "win_rate"
        case profitFactor = "profit_factor"
        case totalTrades = "total_trades"
    }
}

struct BacktestRecommendation: Codable, Identifiable, Hashable {
    var id: String { title + (priority ?? "medium") }
    let title: String
    let description: String?
    let priority: String? // "high", "medium", "low"

    enum CodingKeys: String, CodingKey {
        case title, description, priority
    }
}

// MARK: - APIClient Backtest Extensions

extension APIClient {
    func getBacktests() async throws -> [BacktestResult] {
        let data = try await backtestRequest(.get, APIEndpoints.Backtest.upload)
        return try backtestDecoder.decode([BacktestResult].self, from: data)
    }

    func getBacktest(id: String) async throws -> BacktestResult {
        let data = try await backtestRequest(.get, APIEndpoints.Backtest.backtest(id))
        return try backtestDecoder.decode(BacktestResult.self, from: data)
    }

    func deleteBacktest(id: String) async throws {
        _ = try await backtestRequest(.delete, APIEndpoints.Backtest.backtest(id))
    }

    func uploadBacktest(data: Data, filename: String, strategyId: String?) async throws -> BacktestResult {
        let url = URL(string: APIEndpoints.baseURL)!.appendingPathComponent(APIEndpoints.Backtest.upload)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if let token = getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // File part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)

        // Strategy ID
        if let strategyId = strategyId {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"strategy_id\"\r\n\r\n".data(using: .utf8)!)
            body.append(strategyId.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError
        }

        return try backtestDecoder.decode(BacktestResult.self, from: responseData)
    }

    // Private helpers scoped to backtest
    private var backtestDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func backtestRequest(_ method: HTTPMethod, _ endpoint: String) async throws -> Data {
        let url = URL(string: APIEndpoints.baseURL)!.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            throw APIError.serverError
        }

        return data
    }
}
