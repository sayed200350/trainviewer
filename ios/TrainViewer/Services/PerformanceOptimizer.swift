import Foundation
import UIKit
import Combine

/// Main performance optimization service that coordinates caching, batching, and memory management
@MainActor
final class PerformanceOptimizer: ObservableObject {
    static let shared = PerformanceOptimizer()
    
    @Published var isOptimizationEnabled: Bool = true
    @Published var cacheHitRate: Double = 0.0
    @Published var averageResponseTime: TimeInterval = 0.0
    @Published var optimizationLevel: OptimizationLevel = .balanced
    
    // Optimization levels
    enum OptimizationLevel: String, CaseIterable {
        case minimal = "minimal"
        case balanced = "balanced"
        case aggressive = "aggressive"
        
        var description: String {
            switch self {
            case .minimal: return "Minimal (Battery Saver)"
            case .balanced: return "Balanced"
            case .aggressive: return "Aggressive (Performance)"
            }
        }
        
        var cacheSize: Int {
            switch self {
            case .minimal: return 50
            case .balanced: return 100
            case .aggressive: return 200
            }
        }
        
        var batchDelay: TimeInterval {
            switch self {
            case .minimal: return 2.0
            case .balanced: return 0.5
            case .aggressive: return 0.1
            }
        }
    }
    
    // Performance metrics
    private var requestTimes: [TimeInterval] = []
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    
    // Services
    private let memoryMonitor = MemoryMonitor.shared
    private let requestBatcher = APIRequestBatcher.shared
    private let cacheManager = IntelligentCacheManager.shared
    
    // Cache configuration
    private let maxCacheAge: TimeInterval = 300 // 5 minutes
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupCaches()
        setupMemoryMonitoring()
        setupPerformanceTracking()
    }
    
    // MARK: - Public Interface
    
    /// Configure optimization level
    func setOptimizationLevel(_ level: OptimizationLevel) {
        optimizationLevel = level
        configureCachesForLevel(level)
        print("⚡ [PerformanceOptimizer] Set optimization level to: \(level.description)")
    }

    /// Configure caches based on optimization level
    private func configureCachesForLevel(_ level: OptimizationLevel) {
        let cacheSize = level.cacheSize
        cacheManager.setCacheSize(cacheSize)
        print("⚡ [PerformanceOptimizer] Configured cache size to: \(cacheSize) for level: \(level.rawValue)")
    }
    
    /// Get journey options with performance optimizations
    func getOptimizedJourneyOptions(
        for route: Route,
        priority: APIRequestBatcher.RequestPriority = .normal,
        useCache: Bool = true
    ) async throws -> [JourneyOption] {
        let startTime = Date()
        
        // Check cache first if enabled
        if useCache, let cachedOptions = getCachedJourneyOptions(for: route) {
            recordCacheHit()
            recordResponseTime(Date().timeIntervalSince(startTime))
            print("📦 [PerformanceOptimizer] Cache hit for route: \(route.name)")
            return cachedOptions
        }
        
        recordCacheMiss()
        
        // Use request batcher for network requests
        return try await withCheckedThrowingContinuation { continuation in
            requestBatcher.addRequest(for: route, priority: priority) { result in
                let responseTime = Date().timeIntervalSince(startTime)
                self.recordResponseTime(responseTime)
                
                switch result {
                case .success(let options):
                    // Cache the result
                    if useCache {
                        self.cacheJourneyOptions(options, for: route)
                    }
                    continuation.resume(returning: options)
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Optimize image loading with caching
    func optimizeImageLoading(for url: URL) async -> UIImage? {
        // Check cache first
        if let cachedImage = cacheManager.getImage(for: url) {
            recordCacheHit()
            return cachedImage
        }
        
        recordCacheMiss()
        
        // Load image asynchronously
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return nil }
            
            // Cache the image with normal priority
            cacheManager.storeImage(image, for: url, priority: .normal)
            return image
            
        } catch {
            print("❌ [PerformanceOptimizer] Failed to load image: \(error)")
            return nil
        }
    }
    
    /// Handle memory pressure by clearing caches
    func handleMemoryPressure() {
        print("🧹 [PerformanceOptimizer] Handling memory pressure")
        
        // Clear intelligent cache
        cacheManager.clearAll()
        
        // Reset metrics
        requestTimes.removeAll()
        cacheHits = 0
        cacheMisses = 0
        
        // Notify other components
        NotificationCenter.default.post(name: .performanceOptimizationReset, object: nil)
    }
    
    /// Get performance statistics
    func getPerformanceStatistics() -> PerformanceStatistics {
        return PerformanceStatistics(
            cacheHitRate: cacheHitRate,
            averageResponseTime: averageResponseTime,
            memoryUsageMB: memoryMonitor.memoryUsageMB,
            optimizationLevel: optimizationLevel,
            totalRequests: cacheHits + cacheMisses,
            batchStatistics: requestBatcher.getBatchStatistics()
        )
    }
    
    /// Preload critical data for better performance
    func preloadCriticalData(routes: [Route]) async {
        guard isOptimizationEnabled else { return }
        
        print("🚀 [PerformanceOptimizer] Preloading critical data for \(routes.count) routes")
        
        // Preload favorite routes with low priority
        let favoriteRoutes = routes.filter { $0.isFavorite }
        for route in favoriteRoutes {
            requestBatcher.addBackgroundRequest(for: route) { result in
                switch result {
                case .success(let options):
                    self.cacheJourneyOptions(options, for: route)
                case .failure:
                    break // Ignore preload failures
                }
            }
        }
    }
    
    /// Clear all caches
    func clearAllCaches() {
        cacheManager.clearAll()
        cacheHits = 0
        cacheMisses = 0
        updateCacheHitRate()
        print("🧹 [PerformanceOptimizer] Cleared all caches")
    }
    
    // MARK: - Private Implementation
    
    private func setupCaches() {
        // Setup cache eviction on memory warnings
        NotificationCenter.default.publisher(for: .memoryPressureDetected)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleMemoryPressure()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupMemoryMonitoring() {
        memoryMonitor.$isMemoryPressureHigh
            .sink { [weak self] isHigh in
                if isHigh {
                    Task { @MainActor in
                        self?.handleMemoryPressure()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupPerformanceTracking() {
        // Update metrics every 5 seconds
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePerformanceMetrics()
            }
        }
    }
    
    private func updatePerformanceMetrics() {
        updateCacheHitRate()
        updateAverageResponseTime()
    }
    
    private func updateCacheHitRate() {
        let totalRequests = cacheHits + cacheMisses
        cacheHitRate = totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) : 0.0
    }
    
    private func updateAverageResponseTime() {
        guard !requestTimes.isEmpty else {
            averageResponseTime = 0.0
            return
        }
        
        averageResponseTime = requestTimes.reduce(0, +) / Double(requestTimes.count)
        
        // Keep only recent response times (last 50)
        if requestTimes.count > 50 {
            requestTimes = Array(requestTimes.suffix(50))
        }
    }
    
    private func recordCacheHit() {
        cacheHits += 1
    }
    
    private func recordCacheMiss() {
        cacheMisses += 1
    }
    
    private func recordResponseTime(_ time: TimeInterval) {
        requestTimes.append(time)
    }
    
    // MARK: - Journey Options Caching
    
    private func getCachedJourneyOptions(for route: Route) -> [JourneyOption]? {
        return cacheManager.getJourneyOptions(for: route)
    }
    
    private func cacheJourneyOptions(_ options: [JourneyOption], for route: Route) {
        cacheManager.storeJourneyOptions(options, for: route)
    }
}

// MARK: - Performance Statistics

struct PerformanceStatistics {
    let cacheHitRate: Double
    let averageResponseTime: TimeInterval
    let memoryUsageMB: Double
    let optimizationLevel: PerformanceOptimizer.OptimizationLevel
    let totalRequests: Int
    let batchStatistics: BatchStatistics
    
    var description: String {
        return """
        Performance Statistics:
        - Cache Hit Rate: \(String(format: "%.1f", cacheHitRate * 100))%
        - Avg Response Time: \(String(format: "%.2f", averageResponseTime))s
        - Memory Usage: \(String(format: "%.1f", memoryUsageMB))MB
        - Optimization Level: \(optimizationLevel.description)
        - Total Requests: \(totalRequests)
        - \(batchStatistics.description)
        """
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let performanceOptimizationReset = Notification.Name("performanceOptimizationReset")
}

// MARK: - Convenience Methods

extension PerformanceOptimizer {
    /// Enable or disable performance optimizations
    func setOptimizationEnabled(_ enabled: Bool) {
        isOptimizationEnabled = enabled
        if !enabled {
            clearAllCaches()
        }
        print("⚡ [PerformanceOptimizer] Optimization \(enabled ? "enabled" : "disabled")")
    }
    
    /// Get optimal cache size based on device capabilities
    func getOptimalCacheSize() -> Int {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let memoryGB = Double(totalMemory) / 1024.0 / 1024.0 / 1024.0
        
        // Scale cache size based on available memory
        if memoryGB >= 4.0 {
            return 200 // High-end devices
        } else if memoryGB >= 2.0 {
            return 100 // Mid-range devices
        } else {
            return 50  // Low-end devices
        }
    }
    
    /// Optimize background refresh intervals based on usage patterns
    func getOptimalRefreshInterval(for route: Route) -> TimeInterval {
        // More frequent updates for favorite routes
        if route.isFavorite {
            return optimizationLevel == .aggressive ? 60.0 : 120.0
        }
        
        // Less frequent updates for rarely used routes
        let daysSinceLastUsed = Date().timeIntervalSince(route.lastUsed) / 86400
        if daysSinceLastUsed > 7 {
            return 600.0 // 10 minutes for old routes
        }
        
        return optimizationLevel == .aggressive ? 180.0 : 300.0 // 3-5 minutes
    }
}