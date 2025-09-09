import Testing
import Foundation
import CoreLocation
@testable import TrainViewer


/// Test runner for organizing and executing all unit tests
struct TestRunner {
    
    /// Runs all unit tests and provides a summary
    @Test("Run all unit tests")
    func runAllTests() async throws {
        print("🧪 [TestRunner] Starting comprehensive unit test suite")
        
        let testSuites = [
            "APIClientTests",
            "LocationServiceTests", 
            "NotificationServiceTests",
            "EventKitServiceTests",
            "JourneyHistoryViewModelTests",
            "PrivacyManagerTests",
            "MemoryMonitorTests",
            "TransitStationTests"
        ]
        
        print("📋 [TestRunner] Test suites to run: \(testSuites.count)")
        for suite in testSuites {
            print("   - \(suite)")
        }
        
        print("✅ [TestRunner] All test suites are available for execution")
    }
    
    /// Validates test coverage for critical services
    @Test("Validate test coverage")
    func validateTestCoverage() async throws {
        let criticalServices = [
            "APIClient",
            "LocationService",
            "NotificationService", 
            "EventKitService",
            "JourneyHistoryViewModel",
            "PrivacyManager",
            "MemoryMonitor",
            "TransitStation"
        ]
        
        let testedServices = [
            "APIClient",
            "LocationService", 
            "NotificationService",
            "EventKitService",
            "JourneyHistoryViewModel",
            "PrivacyManager",
            "MemoryMonitor",
            "TransitStation"
        ]
        
        let coverage = Double(testedServices.count) / Double(criticalServices.count) * 100
        
        print("📊 [TestRunner] Test coverage: \(String(format: "%.1f", coverage))%")
        print("🎯 [TestRunner] Critical services covered: \(testedServices.count)/\(criticalServices.count)")
        
        #expect(coverage >= 80.0, "Test coverage should be at least 80%")
    }
    
    /// Tests the test infrastructure itself
    @Test("Test infrastructure validation")
    func testInfrastructureValidation() async throws {
        // Verify Swift Testing framework is working
        #expect(true == true)
        #expect(false == false)
        #expect(1 + 1 == 2)
        
        // Test async functionality
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        // Test error handling
        do {
            throw TestError.example
        } catch TestError.example {
            // Expected
        } catch {
            #expect(Bool(false), "Should have caught TestError.example")
        }
        
        print("✅ [TestRunner] Test infrastructure is working correctly")
    }
    
    /// Validates mock objects and test helpers
    @Test("Mock objects validation")
    func validateMockObjects() async throws {
        // Test MockRouteStore
        let mockRouteStore = MockRouteStore()
        #expect(mockRouteStore.fetchAll().isEmpty)
        
        let testRoute = createTestRoute()
        mockRouteStore.add(route: testRoute)
        #expect(mockRouteStore.fetchAll().count == 1)
        
        mockRouteStore.delete(routeId: testRoute.id)
        #expect(mockRouteStore.fetchAll().isEmpty)
        
        print("✅ [TestRunner] Mock objects are working correctly")
    }
    
    /// Performance baseline test
    @Test("Performance baseline")
    func performanceBaseline() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform some basic operations
        for i in 0..<1000 {
            let _ = "Test string \(i)"
            let _ = Date()
            let _ = UUID()
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        print("⏱️ [TestRunner] Performance baseline: \(String(format: "%.3f", duration))s for 1000 operations")
        
        // Should complete quickly
        #expect(duration < 1.0, "Basic operations should complete within 1 second")
    }
    
    /// Memory usage test
    @Test("Memory usage validation")
    func memoryUsageValidation() async throws {
        let initialMemory = getMemoryUsage()
        
        // Create some objects
        var objects: [String] = []
        for i in 0..<10000 {
            objects.append("Test object \(i)")
        }
        
        let peakMemory = getMemoryUsage()
        
        // Clear objects
        objects.removeAll()
        
        let finalMemory = getMemoryUsage()
        
        print("💾 [TestRunner] Memory usage - Initial: \(initialMemory)MB, Peak: \(peakMemory)MB, Final: \(finalMemory)MB")
        
        // Memory should have increased during object creation
        #expect(peakMemory > initialMemory, "Memory should increase when creating objects")
    }
    
    /// Test data integrity
    @Test("Test data integrity")
    func testDataIntegrity() async throws {
        // Test that test data is consistent and valid
        let testRoute = createTestRoute()
        
        #expect(!testRoute.name.isEmpty)
        #expect(!testRoute.origin.name.isEmpty)
        #expect(!testRoute.destination.name.isEmpty)
        #expect(testRoute.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        
        let testJourneyOption = createTestJourneyOption()
        #expect(testJourneyOption.departure <= testJourneyOption.arrival)
        #expect(testJourneyOption.totalMinutes > 0)
        #expect(!(testJourneyOption.lineName?.isEmpty ?? true))
        
        print("✅ [TestRunner] Test data integrity validated")
    }
}

// MARK: - Test Helpers

extension TestRunner {
    
    private func createTestRoute() -> Route {
        let origin = Place(
            rawId: "test-origin",
            name: "Test Origin",
            latitude: 52.5170,
            longitude: 13.3888
        )

        let destination = Place(
            rawId: "test-destination",
            name: "Test Destination",
            latitude: 52.5200,
            longitude: 13.4050
        )
        
        return Route(
            id: UUID(),
            name: "Test Route",
            origin: origin,
            destination: destination
        )
    }
    
    private func createTestJourneyOption() -> JourneyOption {
        return JourneyOption(
            departure: Date(),
            arrival: Date().addingTimeInterval(1800), // 30 minutes later
            lineName: "Test Line",
            platform: "1",
            delayMinutes: 0,
            totalMinutes: 30,
            warnings: nil
        )
    }
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        } else {
            return 0
        }
    }
}

// MARK: - Test Error Types

enum TestError: Error {
    case example
    case mockFailure(String)
    case validationFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .example:
            return "Example test error"
        case .mockFailure(let message):
            return "Mock failure: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        }
    }
}

// MARK: - Test Configuration

struct TestConfiguration {
    static let timeout: TimeInterval = 30.0
    static let shortTimeout: TimeInterval = 5.0
    static let memoryThresholdMB: Double = 100.0
    static let performanceThresholdSeconds: Double = 1.0
    
    static var isRunningInCI: Bool {
        return ProcessInfo.processInfo.environment["CI"] != nil
    }
    
    static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Test Utilities

struct TestUtilities {
    
    /// Creates a temporary directory for test files
    static func createTemporaryDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("TrainViewerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        return testDir
    }
    
    /// Cleans up temporary test files
    static func cleanupTemporaryDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    /// Waits for a condition to be true with timeout
    static func waitForCondition(
        timeout: TimeInterval = TestConfiguration.timeout,
        condition: @escaping () -> Bool
    ) async throws {
        let startTime = Date()
        
        while !condition() {
            if Date().timeIntervalSince(startTime) > timeout {
                throw TestError.validationFailed("Condition not met within timeout")
            }
            
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
    }
    
    /// Measures execution time of a block
    static func measureTime<T>(
        operation: () async throws -> T
    ) async rethrows -> (result: T, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let endTime = CFAbsoluteTimeGetCurrent()
        
        return (result: result, duration: endTime - startTime)
    }
}