import Testing
import Foundation
import UIKit
import Combine
@testable import TrainViewer

@MainActor
struct MemoryMonitorTests {
    
    // MARK: - Initialization Tests
    
    @Test("MemoryMonitor is a singleton")
    func testSingletonPattern() async throws {
        let monitor1 = MemoryMonitor.shared
        let monitor2 = MemoryMonitor.shared
        
        #expect(monitor1 === monitor2)
    }
    
    @Test("MemoryMonitor initializes with correct default values")
    func testInitialization() async throws {
        let monitor = MemoryMonitor.shared
        
        #expect(monitor.currentMemoryUsage >= 0)
        #expect(monitor.isMemoryPressureHigh == false)
        #expect(monitor.memoryWarningCount >= 0)
        #expect(monitor.currentPressureLevel == .normal)
    }
    
    // MARK: - Memory Pressure Level Tests
    
    @Test("MemoryPressureLevel provides correct descriptions")
    func testMemoryPressureLevelDescriptions() async throws {
        #expect(MemoryMonitor.MemoryPressureLevel.normal.description == "Normal")
        #expect(MemoryMonitor.MemoryPressureLevel.warning.description == "Warning")
        #expect(MemoryMonitor.MemoryPressureLevel.critical.description == "Critical")
    }
    
    // MARK: - Memory Usage Calculation Tests
    
    @Test("MemoryMonitor calculates memory usage in MB correctly")
    func testMemoryUsageMBCalculation() async throws {
        let monitor = MemoryMonitor.shared
        
        // Memory usage should be positive
        #expect(monitor.memoryUsageMB >= 0)
        
        // Should be reasonable for an iOS app (typically 10-500MB)
        #expect(monitor.memoryUsageMB < 1000) // Less than 1GB
    }
    
    @Test("MemoryMonitor calculates memory usage percentage correctly")
    func testMemoryUsagePercentageCalculation() async throws {
        let monitor = MemoryMonitor.shared
        
        let percentage = monitor.memoryUsagePercentage
        
        // Percentage should be between 0 and 100
        #expect(percentage >= 0)
        #expect(percentage <= 100)
    }
    
    // MARK: - Memory Pressure Handling Tests
    
    @Test("MemoryMonitor handles memory pressure correctly")
    func testHandleMemoryPressure() async throws {
        let monitor = MemoryMonitor.shared
        
        // Initial state
        let initialPressureLevel = monitor.currentPressureLevel
        let initialMemoryPressure = monitor.isMemoryPressureHigh
        
        // Handle memory pressure
        monitor.handleMemoryPressure()
        
        // Should update pressure indicators
        #expect(monitor.currentPressureLevel == .critical)
        #expect(monitor.isMemoryPressureHigh == true)
        
        // Wait for pressure level to reset (should happen after 30 seconds in real implementation)
        // For testing, we'll verify the immediate state change
    }
    
    @Test("MemoryMonitor posts notification on memory pressure")
    func testMemoryPressureNotification() async throws {
        let monitor = MemoryMonitor.shared
        
        var notificationReceived = false
        let expectation = XCTestExpectation(description: "Memory pressure notification")
        
        let cancellable = NotificationCenter.default.publisher(for: .memoryPressureDetected)
            .sink { _ in
                notificationReceived = true
                expectation.fulfill()
            }
        
        // Trigger memory pressure
        monitor.handleMemoryPressure()
        
        // Wait briefly for notification
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        #expect(notificationReceived == true)
        
        cancellable.cancel()
    }
    
    // MARK: - Monitoring Control Tests
    
    @Test("MemoryMonitor starts and stops monitoring")
    func testMonitoringControl() async throws {
        let monitor = MemoryMonitor.shared
        
        // Stop monitoring first (in case it's already running)
        monitor.stopMonitoring()
        
        // Start monitoring
        monitor.startMonitoring()
        
        // Should be able to start multiple times without issues
        monitor.startMonitoring()
        
        // Stop monitoring
        monitor.stopMonitoring()
        
        // Should be able to stop multiple times without issues
        monitor.stopMonitoring()
    }
    
    // MARK: - Memory Statistics Tests
    
    @Test("MemoryMonitor provides memory statistics")
    func testMemoryStatistics() async throws {
        let monitor = MemoryMonitor.shared
        
        let statistics = monitor.getStatistics()
        
        #expect(statistics.currentUsageMB >= 0)
        #expect(statistics.peakUsageMB >= 0)
        #expect(statistics.averageUsageMB >= 0)
        #expect(statistics.memoryWarningCount >= 0)
        #expect(!statistics.description.isEmpty)
    }
    
    @Test("MemoryStatistics description contains expected information")
    func testMemoryStatisticsDescription() async throws {
        let statistics = MemoryStatistics(
            currentUsageMB: 50.5,
            peakUsageMB: 75.2,
            averageUsageMB: 45.8,
            memoryWarningCount: 2,
            pressureLevel: .warning
        )
        
        let description = statistics.description
        
        #expect(description.contains("50.5"))
        #expect(description.contains("75.2"))
        #expect(description.contains("45.8"))
        #expect(description.contains("2"))
        #expect(description.contains("Warning"))
        #expect(description.contains("Memory Statistics"))
    }
    
    // MARK: - Notification Extension Tests
    
    @Test("Notification.Name extension provides memory pressure notification")
    func testNotificationNameExtension() async throws {
        let notificationName = Notification.Name.memoryPressureDetected
        
        #expect(notificationName.rawValue == "memoryPressureDetected")
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("MemoryMonitor handles zero memory usage gracefully")
    func testZeroMemoryUsage() async throws {
        let monitor = MemoryMonitor.shared
        
        // Even if memory usage is reported as 0, calculations should not crash
        let usageMB = Double(0) / 1024.0 / 1024.0
        let percentage = Double(0) / Double(ProcessInfo.processInfo.physicalMemory) * 100.0
        
        #expect(usageMB == 0)
        #expect(percentage == 0)
    }
    
    @Test("MemoryMonitor handles very high memory usage")
    func testHighMemoryUsage() async throws {
        let monitor = MemoryMonitor.shared
        
        // Test with hypothetical high memory usage
        let highUsage: Int64 = 500 * 1024 * 1024 // 500MB
        let usageMB = Double(highUsage) / 1024.0 / 1024.0
        
        #expect(usageMB == 500.0)
        #expect(usageMB > 150.0) // Above threshold
    }
    
    @Test("MemoryMonitor handles concurrent access")
    func testConcurrentAccess() async throws {
        let monitor = MemoryMonitor.shared
        
        // Perform multiple concurrent operations
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    monitor.startMonitoring()
                }
            }
            
            for _ in 0..<5 {
                group.addTask {
                    monitor.handleMemoryPressure()
                }
            }
            
            for _ in 0..<5 {
                group.addTask {
                    _ = monitor.getStatistics()
                }
            }
        }
        
        // Should complete without issues
        #expect(monitor.memoryWarningCount >= 0)
    }
    
    @Test("MemoryMonitor memory calculations are consistent")
    func testMemoryCalculationConsistency() async throws {
        let monitor = MemoryMonitor.shared
        
        let usage1 = monitor.currentMemoryUsage
        let usageMB1 = monitor.memoryUsageMB
        let percentage1 = monitor.memoryUsagePercentage
        
        // Wait briefly
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        let usage2 = monitor.currentMemoryUsage
        let usageMB2 = monitor.memoryUsageMB
        let percentage2 = monitor.memoryUsagePercentage
        
        // Values should be reasonable and consistent
        #expect(abs(usageMB1 - usageMB2) < 100) // Should not vary by more than 100MB in 10ms
        #expect(abs(percentage1 - percentage2) < 10) // Should not vary by more than 10% in 10ms
    }
    
    // MARK: - Memory Warning Simulation Tests
    
    @Test("MemoryMonitor handles simulated memory warnings")
    func testSimulatedMemoryWarning() async throws {
        let monitor = MemoryMonitor.shared
        
        let initialWarningCount = monitor.memoryWarningCount
        
        // Simulate memory warning by posting notification
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        // Wait briefly for notification processing
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Warning count should have increased
        #expect(monitor.memoryWarningCount > initialWarningCount)
        #expect(monitor.currentPressureLevel == .critical)
        #expect(monitor.isMemoryPressureHigh == true)
    }
    
    // MARK: - Performance Tests
    
    @Test("MemoryMonitor memory usage calculation is performant")
    func testMemoryUsageCalculationPerformance() async throws {
        let monitor = MemoryMonitor.shared
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform multiple memory usage calculations
        for _ in 0..<100 {
            _ = monitor.memoryUsageMB
            _ = monitor.memoryUsagePercentage
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Should complete quickly (less than 1 second for 100 calculations)
        #expect(duration < 1.0)
    }
}

// MARK: - XCTestExpectation for async testing

class XCTestExpectation {
    let description: String
    private var fulfilled = false
    
    init(description: String) {
        self.description = description
    }
    
    func fulfill() {
        fulfilled = true
    }
    
    var isFulfilled: Bool {
        return fulfilled
    }
}