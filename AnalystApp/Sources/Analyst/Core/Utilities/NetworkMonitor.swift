import Foundation
import Network
import Combine

// MARK: - Network Monitor

/// Monitors network connectivity status
@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    // MARK: - Properties
    
    private(set) var isConnected: Bool = true
    private(set) var connectionType: ConnectionType = .unknown
    private(set) var isExpensive: Bool = false
    private(set) var isConstrained: Bool = false
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.analyst.networkMonitor")
    
    // MARK: - Connection Type
    
    enum ConnectionType: String {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case wired = "Wired"
        case unknown = "Unknown"
    }
    
    // MARK: - Init
    
    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }
    
    // MARK: - Methods
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
                self?.isConstrained = path.isConstrained
                
                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .wired
                } else {
                    self?.connectionType = .unknown
            }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
}

// MARK: - Retry Handler

/// Handles retry logic with exponential backoff
actor RetryHandler {
    static let shared = RetryHandler()
    
    private init() {}
    
    // MARK: - Configuration
    
    struct Configuration {
        let maxRetries: Int
        let initialDelay: TimeInterval
        let maxDelay: TimeInterval
        let multiplier: Double
        let jitter: Bool
        
        static let `default` = Configuration(
            maxRetries: 3,
            initialDelay: 1.0,
            maxDelay: 30.0,
            multiplier: 2.0,
            jitter: true
        )
        
        static let aggressive = Configuration(
            maxRetries: 5,
            initialDelay: 0.5,
            maxDelay: 60.0,
            multiplier: 1.5,
            jitter: true
        )
        
        static let conservative = Configuration(
            maxRetries: 2,
            initialDelay: 2.0,
            maxDelay: 10.0,
            multiplier: 2.0,
            jitter: false
        )
    }
    
    // MARK: - Retry Result
    
    enum RetryResult<T> {
        case success(T)
        case failure(Error)
        case retriesExhausted(lastError: Error)
    }
    
    // MARK: - Retry with Exponential Backoff
    
    func retry<T>(
        config: Configuration = .default,
        operation: @escaping () async throws -> T
    ) async -> RetryResult<T> {
        var lastError: Error?
        var delay = config.initialDelay
        
        for attempt in 0..<config.maxRetries {
            do {
                let result = try await operation()
                return .success(result)
            } catch {
                lastError = error
                
                // Check if error is retryable
                if !isRetryable(error) {
                    return .failure(error)
                }
                
                // Wait before next retry
                if attempt < config.maxRetries - 1 {
                    let actualDelay = config.jitter ? addJitter(to: delay) : delay
                    try? await Task.sleep(nanoseconds: UInt64(actualDelay * 1_000_000_000))
                    delay = min(delay * config.multiplier, config.maxDelay)
                }
            }
        }
        
        return .retriesExhausted(lastError: lastError!)
    }
    
    // MARK: - Helpers
    
    private func isRetryable(_ error: Error) -> Bool {
        // Network errors are usually retryable
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        }
        
        // API errors - only retry server errors
        if let apiError = error as? APIError {
            switch apiError {
            case .serverError:
                return true
            default:
                return false
            }
        }
        
        return false
    }
    
    private func addJitter(to delay: TimeInterval) -> TimeInterval {
        let jitter = Double.random(in: 0.8...1.2)
        return delay * jitter
    }
}