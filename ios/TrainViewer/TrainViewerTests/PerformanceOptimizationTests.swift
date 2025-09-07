import XCTest
import Combine
@testable import TrainViewer

@MainActor
final class PerformanceOptimizationTests: XCTestCase {
    
    var performanceOptimizer: PerformanceOptimizer!
    var memoryMonitor: MemoryMonitor!
    var requestBatcher: APIRequestBatcher!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        try await super.setUp()
        performanceOptimizer = PerformanceOptimizer.shared
        memoryMonitor = MemoryMonitor.shared
        requestBatcher = APIRequestBatcher.shared
        cancellables = Set<AnyCancellable>()
        
        // Reset state
        performanceOptimizer.clearAllCaches()
        performanceOptimizer.setOptimizationEnabled(true)
    }
    
    override func tearDown() async throws {
        cancellables.removeAll()
        performanceOptimizer.clearAllCaches()
        try await super.tearDown()
    }
    
    // MARK: - Memory Monitor Tests
    
    func testMemoryMonitorInitialization() {
        XCTAssertNotNil(memoryMonitor)
        XCTAssertFalse(memoryMonitor.isMemoryPressureHigh)
        XCTAssertEqual(memoryMonitor.memoryWarningCount, 0)
        XCTAssertEqual(memoryMonitor.currentPressureLevel, .normal)
    }
    
    func testMemoryUsageTracking() {
        let initialUsage = memoryMonitor.currentMemoryUsage
        XCTAssertGreaterThan(initialUsage, 0, "Memory usage should be greater than 0")
        
        let usageMB = memoryMonitor.memoryUsageMB
        XCTAssertGreaterThan(usageMB, 0, "Memory usage in MB should be greater than 0")
        
        let usagePercentage = memoryMonitor.memoryUsagePercentage
        XCTAssertGreaterThan(usagePercentage, 0, "Memory usage percentage should be greater than 0")
        XCTAssertLessThan(usagePercentage, 100, "Memory usage percentage should be less than 100")
    }
    
    func testMemoryPressureHandling() {
        let expectation = XCTestExpectation(description: "Memory pressure handled")
        
        memoryMonitor.$isMemoryPressureHigh
            .dropFirst() // Skip initial value
            .sink { isHigh in
                if isHigh {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        memoryMonitor.handleMemoryPressure()
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(memoryMonitor.isMemoryPressureHigh)
        XCTAssertEqual(memoryMonitor.currentPressureLevel, .critical)
    }
    
    func testMemoryStatistics() {
        let statistics = memoryMonitor.getStatistics()
        
        XCTAssertGreaterThan(statistics.currentUsageMB, 0)
        XCTAssertEqual(statistics.memoryWarningCount, memoryMonitor.memoryWarningCount)
        XCTAssertEqual(statistics.pressureLevel, memoryMonitor.currentPressureLevel)
    }
    
    // MARK: - API Request Batcher Tests
    
    func testBatcherInitialization() {
        let statistics = requestBatcher.getBatchStatistics()
        XCTAssertEqual(statistics.pendingRequestCount, 0)
        XCTAssertEqual(statistics.highPriorityCount, 0)
        XCTAssertEqual(statistics.expiredRequestCount, 0)
    }
    
    func testRequestBatching() {
        let expectation = XCTestExpectation(description: "Request batched")
        expectation.expectedFulfillmentCount = 2
        
        let route1 = createTestRoute(name: "Route 1")
        let route2 = createTestRoute(name: "Route 2")
        
        requestBatcher.addRequest(for: route1, priority: .normal) { result in
            expectation.fulfill()
        }
        
        requestBatcher.addRequest(for: route2, priority: .high) { result in
            expectation.fulfill()
        }
        
        let statistics = requestBatcher.getBatchStatistics()
        XCTAssertEqual(statistics.pendingRequestCount, 2)
        XCTAssertEqual(statistics.highPriorityCount, 1)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testRequestPrioritization() {
        let expectation = XCTestExpectation(description: "High priority request processed")
        
        let route = createTestRoute(name: "Priority Route")
        
        requestBatcher.addCriticalRequest(for: route) { result in
            expectation.fulfill()
        }
        
        let statistics = requestBatcher.getBatchStatistics()
        XCTAssertGreaterThan(statistics.highPriorityCount, 0)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testRequestCoalescing() {
        let expectation = XCTestExpectation(description: "Request coalesced")
        
        let route = createTestRoute(name: "Coalesced Route")
        
        // Add first request
        requestBatcher.addRequest(for: route, priority: .normal) { result in
            // This should succeed
        }
        
        // Add second request for same route
        requestBatcher.addRequest(for: route, priority: .normal) { result in
            switch result {
            case .failure(let error):
                if case APIError.requestCoalesced = error {
                    expectation.fulfill()
                }
            case .success:
                XCTFail("Second request should have been coalesced")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Performance Optimizer Tests
    
    func testPerformanceOptimizerInitialization() {
        XCTAssertTrue(performanceOptimizer.isOptimizationEnabled)
        XCTAssertEqual(performanceOptimizer.optimizationLevel, .balanced)
        XCTAssertEqual(performanceOptimizer.cacheHitRate, 0.0)
        XCTAssertEqual(performanceOptimizer.averageResponseTime, 0.0)
    }
    
    func testOptimizationLevelConfiguration() {
        performanceOptimizer.setOptimizationLevel(.aggressive)
        XCTAssertEqual(performanceOptimizer.optimizationLevel, .aggressive)
        
        performanceOptimizer.setOptimizationLevel(.minimal)
        XCTAssertEqual(performanceOptimizer.optimizationLevel, .minimal)
        
        performanceOptimizer.setOptimizationLevel(.balanced)
        XCTAssertEqual(performanceOptimizer.optimizationLevel, .balanced)
    }
    
    func testCacheManagement() {
        // Test cache clearing
        performanceOptimizer.clearAllCaches()
        XCTAssertEqual(performanceOptimizer.cacheHitRate, 0.0)
        
        // Test optimization enable/disable
        performanceOptimizer.setOptimizationEnabled(false)
        XCTAssertFalse(performanceOptimizer.isOptimizationEnabled)
        
        performanceOptimizer.setOptimizationEnabled(true)
        XCTAssertTrue(performanceOptimizer.isOptimizationEnabled)
    }
    
    func testPerformanceStatistics() {
        let statistics = performanceOptimizer.getPerformanceStatistics()
        
        XCTAssertGreaterThanOrEqual(statistics.cacheHitRate, 0.0)
        XCTAssertLessThanOrEqual(statistics.cacheHitRate, 1.0)
        XCTAssertGreaterThanOrEqual(statistics.averageResponseTime, 0.0)
        XCTAssertGreaterThan(statistics.memoryUsageMB, 0.0)
        XCTAssertEqual(statistics.optimizationLevel, performanceOptimizer.optimizationLevel)
    }
    
    func testOptimalCacheSize() {
        let cacheSize = performanceOptimizer.getOptimalCacheSize()
        XCTAssertGreaterThan(cacheSize, 0)
        XCTAssertLessThanOrEqual(cacheSize, 200)
    }
    
    func testOptimalRefreshInterval() {
        let favoriteRoute = createTestRoute(name: "Favorite", isFavorite: true)
        let regularRoute = createTestRoute(name: "Regular", isFavorite: false)
        
        let favoriteInterval = performanceOptimizer.getOptimalRefreshInterval(for: favoriteRoute)
        let regularInterval = performanceOptimizer.getOptimalRefreshInterval(for: regularRoute)
        
        XCTAssertLessThan(favoriteInterval, regularInterval, "Favorite routes should have shorter refresh intervals")
    }
    
    func testImageOptimization() async {
        // Test with a valid URL (this would need a real image URL in practice)
        let testURL = URL(string: "https://example.com/test.png")!
        
        // This test would need to be adapted based on your actual image loading implementation
        let image = await performanceOptimizer.optimizeImageLoading(for: testURL)
        // In a real test, you'd verify the image was loaded and cached properly
    }
    
    func testPreloadCriticalData() async {
        let routes = [
            createTestRoute(name: "Route 1", isFavorite: true),
            createTestRoute(name: "Route 2", isFavorite: false),
            createTestRoute(name: "Route 3", isFavorite: true)
        ]
        
        await performanceOptimizer.preloadCriticalData(routes: routes)
        
        // Verify that preloading was initiated (in practice, you'd check cache state)
        let statistics = requestBatcher.getBatchStatistics()
        // The exact assertion would depend on your implementation details
    }
    
    // MARK: - Integration Tests
    
    func testMemoryPressureIntegration() {
        let expectation = XCTestExpectation(description: "Memory pressure integration")
        
        // Listen for performance optimization reset
        NotificationCenter.default.publisher(for: .performanceOptimizationReset)
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Trigger memory pressure
        memoryMonitor.handleMemoryPressure()
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testPerformanceUnderLoad() {
        let expectation = XCTestExpectation(description: "Performance under load")
        expectation.expectedFulfillmentCount = 10
        
        let routes = (1...10).map { createTestRoute(name: "Route \($0)") }
        
        // Add multiple requests simultaneously
        for route in routes {
            requestBatcher.addRequest(for: route, priority: .normal) { result in
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Verify system handled the load
        let statistics = performanceOptimizer.getPerformanceStatistics()
        XCTAssertGreaterThan(statistics.totalRequests, 0)
    }
    
    // MARK: - Performance Measurement Tests
    
    func testAPIBatchingPerformance() {
        measure {
            let routes = (1...5).map { createTestRoute(name: "Perf Route \($0)") }
            
            for route in routes {
                requestBatcher.addRequest(for: route, priority: .normal) { _ in }
            }
            
            requestBatcher.flushPendingRequests()
        }
    }
    
    func testMemoryUsageUnderLoad() {
        measure {
            let initialMemory = memoryMonitor.currentMemoryUsage
            
            // Simulate memory-intensive operations
            var data: [Data] = []
            for _ in 0..<100 {
                data.append(Data(count: 1024 * 1024)) // 1MB each
            }
            
            let finalMemory = memoryMonitor.currentMemoryUsage
            XCTAssertGreaterThan(finalMemory, initialMemory)
            
            // Clean up
            data.removeAll()
        }
    }
    
    func testCacheEfficiency() {
        measure {
            performanceOptimizer.clearAllCaches()
            
            let route = createTestRoute(name: "Cache Test Route")
            
            // This would test actual caching in a real implementation
            // For now, we just test the cache management
            performanceOptimizer.clearAllCaches()
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestRoute(name: String, isFavorite: Bool = false) -> Route {
        let origin = Place(
            id: "origin_\(name)",
            name: "Origin \(name)",
            coordinate: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050)
        )
        
        let destination = Place(
            id: "dest_\(name)",
            name: "Destination \(name)",
            coordinate: CLLocationCoordinate2D(latitude: 52.5170, longitude: 13.3888)
        )
        
        return Route(
            name: name,
            origin: origin,
            destination: destination,
            isFavorite: isFavorite
        )
    }
}

// MARK: - Mock Transport API for Testing

class MockTransportAPI: TransportAPI {
    func searchLocations(query: String, limit: Int) async throws -> [Place] {
        // Return mock search results
        return []
    }

    func nextJourneyOptions(from: Place, to: Place, results: Int) async throws -> [JourneyOption] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Return mock journey options
        return [
            JourneyOption(
                departure: Date().addingTimeInterval(300), // 5 minutes from now
                arrival: Date().addingTimeInterval(1800), // 30 minutes from now
                lineName: "Test Line",
                platform: "1",
                delayMinutes: 0,
                totalMinutes: 25,
                warnings: nil
            )
        ]
    }

    func refreshJourney(with token: String) async throws -> [JourneyOption] {
        // Return mock refreshed journey options
        return try await nextJourneyOptions(
            from: Place(rawId: "1", name: "A", latitude: nil, longitude: nil),
            to: Place(rawId: "2", name: "B", latitude: nil, longitude: nil),
            results: 1
        )
    }
}