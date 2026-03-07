import Foundation

// MARK: - Cache Manager

/// Simple in-memory cache with TTL support
actor CacheManager {
    static let shared = CacheManager()
    
    // MARK: - Cache Entry
    
    private final class CacheEntry {
        let value: Any
        let timestamp: Date
        let ttl: TimeInterval?
        
        init(value: Any, timestamp: Date, ttl: TimeInterval?) {
            self.value = value
            self.timestamp = timestamp
            self.ttl = ttl
        }
        
        var isExpired: Bool {
            guard let ttl = ttl else { return false }
            return Date().timeIntervalSince(timestamp) > ttl
        }
    }
    
    // MARK: - Properties
    
    private var cache: [String: CacheEntry] = [:]
    private var fileManager = FileManager.default
    private let cacheURL: URL
    
    // MARK: - Init
    
    private init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheURL = paths[0].appendingPathComponent("AnalystCache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
    }
    
    // MARK: - Cache Operations
    
    func set<T: Sendable>(_ value: T, forKey key: String, ttl: TimeInterval? = nil) {
        cache[key] = CacheEntry(value: value, timestamp: Date(), ttl: ttl)
    }
    
    func get<T: Sendable>(_ key: String) -> T? {
        guard let entry = cache[key] else { return nil }
        
        if entry.isExpired {
            cache.removeValue(forKey: key)
            return nil
        }
        
        return entry.value as? T
    }
    
    func remove(_ key: String) {
        cache.removeValue(forKey: key)
    }
    
    func clear() {
        cache.removeAll()
    }
    
    func clearExpired() {
        cache = cache.filter { !$0.value.isExpired }
    }
    
    /// Clear all cache including persisted files
    func clearAll() {
        cache.removeAll()
        // Clear persisted cache files
        if let contents = try? fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil) {
            for fileURL in contents {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
    
    // MARK: - Statistics
    
    func stats() -> CacheStats {
        return CacheStats(
            itemCount: cache.count,
            totalSize: cache.count * 100, // Approximate
            memoryLimit: 50 * 1024 * 1024
        )
    }
}

// MARK: - Cache Stats

struct CacheStats {
    let itemCount: Int
    let totalSize: Int
    let memoryLimit: Int
    
    var formattedSize: String {
        let mb = Double(totalSize) / (1024 * 1024)
        return String(format: "%.1f MB", mb)
    }
}

// MARK: - TTL Presets

enum CacheTTL {
    static let short: TimeInterval = 60
    static let medium: TimeInterval = 300
    static let long: TimeInterval = 3600
    static let day: TimeInterval = 86400
    static let week: TimeInterval = 604800
}

// MARK: - Cache Keys

enum CacheKey {
    case conversations
    case conversation(id: String)
    case documents
    case user
    case stock(symbol: String, type: String)
    case aflHistory
    case backtest(id: String)
    
    var key: String {
        switch self {
        case .conversations: return "conversations_list"
        case .conversation(let id): return "conversation_\(id)"
        case .documents: return "documents_list"
        case .user: return "user_profile"
        case .stock(let symbol, let type): return "stock_\(symbol)_\(type)"
        case .aflHistory: return "afl_history"
        case .backtest(let id): return "backtest_\(id)"
        }
    }
}