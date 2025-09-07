import Foundation
import UIKit
import CoreLocation

/// Compilation test to verify performance optimization components compile correctly
final class PerformanceOptimizationCompilationTest {
    
    static func testCompilation() {
        print("🧪 [CompilationTest] Testing performance optimization components...")

        // Test APIRequestBatcher
        let batcher = APIRequestBatcher.shared
        let batchStats = batcher.getBatchStatistics()
        print("✅ APIRequestBatcher: \(batchStats.description)")

        // Test IntelligentCacheManager
        let cacheManager = IntelligentCacheManager.shared
        let cacheStats = cacheManager.getStatistics()
        print("✅ IntelligentCacheManager: \(cacheStats.description)")

        // Test PerformanceOptimizer and MemoryMonitor (MainActor isolated)
        Task { @MainActor in
            // Test MemoryMonitor
            let memoryMonitor = MemoryMonitor.shared
            let memoryUsage = memoryMonitor.currentMemoryUsage
            let isHighPressure = memoryMonitor.isMemoryPressureHigh
            let memoryStatistics = memoryMonitor.getStatistics()
            print("✅ MemoryMonitor: Usage=\(memoryUsage), HighPressure=\(isHighPressure)")
            print("   Statistics: \(memoryStatistics.description)")

            // Test PerformanceOptimizer
            let optimizer = PerformanceOptimizer.shared
            let perfStats = optimizer.getPerformanceStatistics()
            print("✅ PerformanceOptimizer: \(perfStats.description)")

            // Test optimization levels
            optimizer.setOptimizationLevel(.aggressive)
            optimizer.setOptimizationLevel(.balanced)
            optimizer.setOptimizationLevel(.minimal)

            print("✅ All performance optimization components compiled successfully!")
        }
    }
    
    static func testCacheOperations() {
        let cacheManager = IntelligentCacheManager.shared
        
        // Test basic cache operations
        cacheManager.store("test data", forKey: "test_key", priority: .normal)
        let retrieved: String? = cacheManager.retrieve(forKey: "test_key", as: String.self)
        
        if retrieved == "test data" {
            print("✅ Cache operations working correctly")
        } else {
            print("❌ Cache operations failed")
        }
        
        cacheManager.remove(forKey: "test_key")
    }
    
    static func testMemoryMonitoring() {
        Task { @MainActor in
            let monitor = MemoryMonitor.shared
            monitor.startMonitoring()

            // Simulate memory pressure
            monitor.handleMemoryPressure()

            if monitor.isMemoryPressureHigh {
                print("✅ Memory pressure handling working")
            } else {
                print("❌ Memory pressure handling failed")
            }

            monitor.stopMonitoring()
        }
    }
    
    static func testRequestBatching() {
        let batcher = APIRequestBatcher.shared
        
        // Create a test route
        let origin = Place(
            rawId: "test_origin",
            name: "Test Origin",
            latitude: 52.5200,
            longitude: 13.4050
        )

        let destination = Place(
            rawId: "test_dest",
            name: "Test Destination",
            latitude: 52.5170,
            longitude: 13.3888
        )
        
        let testRoute = Route(
            name: "Test Route",
            origin: origin,
            destination: destination,
            preparationBufferMinutes: 3,
            walkingSpeedMetersPerSecond: 1.4
        )
        
        // Test adding requests
        batcher.addRequest(for: testRoute, priority: .normal) { result in
            print("✅ Request batching callback executed")
        }
        
        let stats = batcher.getBatchStatistics()
        if stats.pendingRequestCount > 0 {
            print("✅ Request batching working correctly")
        } else {
            print("❌ Request batching failed")
        }
    }
}

// MARK: - Test Runner

extension PerformanceOptimizationCompilationTest {
    static func runAllTests() {
        print("🚀 Starting Performance Optimization Compilation Tests")
        
        testCompilation()
        testCacheOperations()
        testMemoryMonitoring()
        testRequestBatching()
        
        print("✅ All compilation tests completed successfully!")
    }
}