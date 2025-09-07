import Foundation
import UIKit

/// Intelligent caching strategy with TTL and priority-based cache management
final class IntelligentCacheManager {
    static let shared = IntelligentCacheManager()
    
    // Cache priority levels
    enum CachePriority: Int, Comparable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3
        
        static func < (lhs: CachePriority, rhs: CachePriority) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
        
        var ttl: TimeInterval {
            switch self {
            case .low: return 60 // 1 minute
            case .normal: return 300 // 5 minutes
            case .high: return 600 // 10 minutes
            case .critical: return 1800 // 30 minutes
            }
        }
    }
    
    // Cache entry wrapper
    private class CacheEntry {
        let key: String
        let data: Any
        let priority: CachePriority
        let createdAt: Date
        let ttl: TimeInterval
        let accessCount: Int
        let lastAccessed: Date
        let size: Int
        
        init(key: String, data: Any, priority: CachePriority, size: Int = 0) {
            self.key = key
            self.data = data
            self.priority = priority
            self.createdAt = Date()
            self.ttl = priority.ttl
            self.accessCount = 1
            self.lastAccessed = Date()
            self.size = size
        }
        
        var isExpired: Bool {
            return Date().timeIntervalSince(createdAt) > ttl
        }
        
        var age: TimeInterval {
            return Date().timeIntervalSince(createdAt)
        }
        
        var timeSinceLastAccess: TimeInterval {
            return Date().timeIntervalSince(lastAccessed)
        }
        
        func accessed() -> CacheEntry {
            return CacheEntry(
                key: key,
                data: data,
                priority: priority,
                size: size
            )
        }
    }
    
    // Cache configuration
    private struct CacheConfiguration {
        let maxEntries: Int
        let maxSizeBytes: Int
        let cleanupThreshold: Double // Percentage of max entries to trigger cleanup
        let maxAge: TimeInterval // Maximum age before forced eviction

        static let `default` = CacheConfiguration(
            maxEntries: 1000,
            maxSizeBytes: 50 * 1024 * 1024, // 50MB
            cleanupThreshold: 0.8, // Cleanup when 80% full
            maxAge: 3600 // 1 hour max age
        )
    }

    private var cache: [String: CacheEntry] = [:]
    private var configuration: CacheConfiguration = .default
    private let queue = DispatchQueue(label: "IntelligentCacheManager", attributes: .concurrent)
    private var currentSizeBytes: Int = 0
    
    // Statistics
    private var hitCount: Int = 0
    private var missCount: Int = 0
    private var evictionCount: Int = 0
    
    private init(configuration: CacheConfiguration = .default) {
        self.configuration = configuration
        setupMemoryWarningObserver()
        setupPeriodicCleanup()
    }
    
    // MARK: - Public Interface
    
    /// Store data in cache with specified priority
    func store<T>(_ data: T, forKey key: String, priority: CachePriority = .normal) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let size = self.calculateSize(data)
            let entry = CacheEntry(key: key, data: data, priority: priority, size: size)
            
            // Remove existing entry if present
            if let existingEntry = self.cache[key] {
                self.currentSizeBytes -= existingEntry.size
            }
            
            self.cache[key] = entry
            self.currentSizeBytes += size
            
            // Check if cleanup is needed
            if self.shouldPerformCleanup() {
                self.performIntelligentCleanup()
            }
            
            print("💾 [CacheManager] Stored \(key) with priority \(priority) (size: \(size) bytes)")
        }
    }
    
    /// Retrieve data from cache
    func retrieve<T>(forKey key: String, as type: T.Type) -> T? {
        return queue.sync { [weak self] in
            guard let self = self,
                  let entry = self.cache[key] else {
                self?.recordMiss()
                return nil
            }
            
            // Check if entry is expired
            if entry.isExpired {
                self.cache.removeValue(forKey: key)
                self.currentSizeBytes -= entry.size
                self.recordMiss()
                print("⏰ [CacheManager] Cache entry expired: \(key)")
                return nil
            }
            
            // Update access information
            let updatedEntry = entry.accessed()
            self.cache[key] = updatedEntry
            
            self.recordHit()
            print("✅ [CacheManager] Cache hit: \(key)")
            
            return entry.data as? T
        }
    }
    
    /// Remove specific entry from cache
    func remove(forKey key: String) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self,
                  let entry = self.cache.removeValue(forKey: key) else { return }
            
            self.currentSizeBytes -= entry.size
            print("🗑️ [CacheManager] Removed cache entry: \(key)")
        }
    }
    
    /// Clear all cache entries
    func clearAll() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let entryCount = self.cache.count
            self.cache.removeAll()
            self.currentSizeBytes = 0
            self.resetStatistics()
            
            print("🧹 [CacheManager] Cleared all cache entries (\(entryCount) entries)")
        }
    }
    
    /// Get cache statistics
    func getStatistics() -> CacheStatistics {
        return queue.sync {
            let totalRequests = hitCount + missCount
            let hitRate = totalRequests > 0 ? Double(hitCount) / Double(totalRequests) : 0.0
            
            return CacheStatistics(
                entryCount: cache.count,
                totalSizeBytes: currentSizeBytes,
                hitCount: hitCount,
                missCount: missCount,
                evictionCount: evictionCount,
                hitRate: hitRate,
                averageEntrySize: cache.isEmpty ? 0 : currentSizeBytes / cache.count
            )
        }
    }
    
    /// Perform manual cleanup
    func performCleanup() {
        queue.async(flags: .barrier) { [weak self] in
            self?.performIntelligentCleanup()
        }
    }

    /// Set maximum cache size in bytes
    func setCacheSize(_ sizeInBytes: Int) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            self.configuration = CacheConfiguration(
                maxEntries: self.configuration.maxEntries,
                maxSizeBytes: max(sizeInBytes, 1024 * 1024), // Minimum 1MB
                cleanupThreshold: self.configuration.cleanupThreshold,
                maxAge: self.configuration.maxAge
            )

            // Trigger cleanup if we're over the new limit
            if self.currentSizeBytes > sizeInBytes {
                self.performIntelligentCleanup()
            }

            print("⚙️ [CacheManager] Cache size set to \(sizeInBytes) bytes")
        }
    }
    
    // MARK: - Private Implementation
    
    private func shouldPerformCleanup() -> Bool {
        let entryThreshold = Double(configuration.maxEntries) * configuration.cleanupThreshold
        let sizeThreshold = Double(configuration.maxSizeBytes) * configuration.cleanupThreshold
        
        return cache.count > Int(entryThreshold) || currentSizeBytes > Int(sizeThreshold)
    }
    
    private func performIntelligentCleanup() {
        let initialCount = cache.count
        let initialSize = currentSizeBytes
        
        // Remove expired entries first
        removeExpiredEntries()
        
        // If still over threshold, perform priority-based eviction
        if shouldPerformCleanup() {
            performPriorityBasedEviction()
        }
        
        let removedCount = initialCount - cache.count
        let freedBytes = initialSize - currentSizeBytes
        
        if removedCount > 0 {
            evictionCount += removedCount
            print("🧹 [CacheManager] Cleanup completed: removed \(removedCount) entries, freed \(freedBytes) bytes")
        }
    }
    
    private func removeExpiredEntries() {
        let expiredKeys = cache.compactMap { key, entry in
            entry.isExpired || entry.age > configuration.maxAge ? key : nil
        }
        
        for key in expiredKeys {
            if let entry = cache.removeValue(forKey: key) {
                currentSizeBytes -= entry.size
            }
        }
    }
    
    private func performPriorityBasedEviction() {
        // Calculate eviction scores for each entry
        let scoredEntries = cache.map { key, entry in
            (key: key, entry: entry, score: calculateEvictionScore(entry))
        }
        
        // Sort by eviction score (higher score = more likely to be evicted)
        let sortedEntries = scoredEntries.sorted { $0.score > $1.score }
        
        // Remove entries until we're under threshold
        let targetCount = Int(Double(configuration.maxEntries) * 0.7) // Target 70% capacity
        let targetSize = Int(Double(configuration.maxSizeBytes) * 0.7)
        
        for (key, entry, _) in sortedEntries {
            if cache.count <= targetCount && currentSizeBytes <= targetSize {
                break
            }
            
            cache.removeValue(forKey: key)
            currentSizeBytes -= entry.size
        }
    }
    
    private func calculateEvictionScore(_ entry: CacheEntry) -> Double {
        // Lower priority = higher eviction score
        let priorityScore = Double(CachePriority.critical.rawValue - entry.priority.rawValue) * 10.0
        
        // Older entries = higher eviction score
        let ageScore = entry.age / 3600.0 // Normalize to hours
        
        // Less frequently accessed = higher eviction score
        let accessScore = max(0, 10.0 - Double(entry.accessCount))
        
        // Longer time since last access = higher eviction score
        let recencyScore = entry.timeSinceLastAccess / 3600.0 // Normalize to hours
        
        return priorityScore + ageScore + accessScore + recencyScore
    }
    
    private func calculateSize<T>(_ data: T) -> Int {
        // Rough size estimation
        if let data = data as? Data {
            return data.count
        } else if let string = data as? String {
            return string.utf8.count
        } else if let array = data as? [Any] {
            return array.count * 100 // Rough estimate
        } else {
            return 100 // Default estimate
        }
    }
    
    private func recordHit() {
        hitCount += 1
    }
    
    private func recordMiss() {
        missCount += 1
    }
    
    private func resetStatistics() {
        hitCount = 0
        missCount = 0
        evictionCount = 0
    }
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    private func handleMemoryWarning() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Aggressive cleanup on memory warning
            let initialCount = self.cache.count
            
            // Remove all low priority entries
            let lowPriorityKeys = self.cache.compactMap { key, entry in
                entry.priority == .low ? key : nil
            }
            
            for key in lowPriorityKeys {
                if let entry = self.cache.removeValue(forKey: key) {
                    self.currentSizeBytes -= entry.size
                }
            }
            
            // Remove expired entries
            self.removeExpiredEntries()
            
            let removedCount = initialCount - self.cache.count
            self.evictionCount += removedCount
            
            print("🚨 [CacheManager] Memory warning cleanup: removed \(removedCount) entries")
        }
    }
    
    private func setupPeriodicCleanup() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.performCleanup()
        }
    }
}

// MARK: - Cache Statistics

struct CacheStatistics {
    let entryCount: Int
    let totalSizeBytes: Int
    let hitCount: Int
    let missCount: Int
    let evictionCount: Int
    let hitRate: Double
    let averageEntrySize: Int
    
    var totalSizeMB: Double {
        return Double(totalSizeBytes) / 1024.0 / 1024.0
    }
    
    var description: String {
        return """
        Cache Statistics:
        - Entries: \(entryCount)
        - Size: \(String(format: "%.2f", totalSizeMB))MB
        - Hit Rate: \(String(format: "%.1f", hitRate * 100))%
        - Hits: \(hitCount), Misses: \(missCount)
        - Evictions: \(evictionCount)
        - Avg Entry Size: \(averageEntrySize) bytes
        """
    }
}

// MARK: - Convenience Extensions

extension IntelligentCacheManager {
    /// Store journey options with appropriate priority
    func storeJourneyOptions(_ options: [JourneyOption], for route: Route) {
        let priority: CachePriority = route.isFavorite ? .high : .normal
        store(options, forKey: "journey_\(route.id.uuidString)", priority: priority)
    }
    
    /// Retrieve journey options for route
    func getJourneyOptions(for route: Route) -> [JourneyOption]? {
        return retrieve(forKey: "journey_\(route.id.uuidString)", as: [JourneyOption].self)
    }
    
    /// Store image with appropriate priority
    func storeImage(_ image: UIImage, for url: URL, priority: CachePriority = .normal) {
        store(image, forKey: "image_\(url.absoluteString)", priority: priority)
    }
    
    /// Retrieve image for URL
    func getImage(for url: URL) -> UIImage? {
        return retrieve(forKey: "image_\(url.absoluteString)", as: UIImage.self)
    }
}