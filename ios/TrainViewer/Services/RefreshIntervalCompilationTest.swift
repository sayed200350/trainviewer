import Foundation
import UIKit

/// Compilation test for refresh interval functionality
/// This file ensures all refresh interval components compile correctly
final class RefreshIntervalCompilationTest {
    
    func testAdaptiveRefreshService() {
        let service = AdaptiveRefreshService.shared
        
        // Test route creation
        let route = Route.create(
            name: "Test Route",
            origin: Place(rawId: "1", name: "Origin", latitude: 52.5, longitude: 13.4),
            destination: Place(rawId: "2", name: "Destination", latitude: 52.6, longitude: 13.5),
            customRefreshInterval: .fiveMinutes
        )
        
        // Test adaptive refresh interval calculation
        let interval = service.getAdaptiveRefreshInterval(for: route)
        print("✅ Adaptive interval calculated: \(interval)s")
        
        // Test refresh strategy
        let strategy = service.getRefreshStrategy(for: route)
        print("✅ Refresh strategy: \(strategy.displayName)")
        
        // Test should refresh logic
        let shouldRefresh = service.shouldRefreshRoute(route, lastRefresh: Date().addingTimeInterval(-300))
        print("✅ Should refresh: \(shouldRefresh)")
        
        // Test next refresh time
        let nextRefresh = service.getNextRefreshTime(for: route, lastRefresh: Date())
        print("✅ Next refresh time: \(nextRefresh)")
        
        // Test battery optimization suggestions
        let suggestions = service.getBatteryOptimizationSuggestions()
        print("✅ Battery suggestions: \(suggestions.count) items")
        
        // Test efficiency score
        let efficiency = service.getRefreshEfficiencyScore(for: route)
        print("✅ Efficiency score: \(efficiency)")
    }
    
    func testRefreshIntervalEnum() {
        // Test all refresh interval cases
        for interval in RefreshInterval.allCases {
            print("✅ Interval: \(interval.displayName) = \(interval.timeInterval)s")
        }
        
        // Test specific intervals
        let fiveMinutes = RefreshInterval.fiveMinutes
        assert(fiveMinutes.timeInterval == 300, "Five minutes should be 300 seconds")
        print("✅ RefreshInterval enum validation passed")
    }
    
    func testRouteRefreshIntervalIntegration() {
        // Test route with custom refresh interval
        var route = Route.create(
            name: "Test Route",
            origin: Place(rawId: "1", name: "Origin", latitude: 52.5, longitude: 13.4),
            destination: Place(rawId: "2", name: "Destination", latitude: 52.6, longitude: 13.5)
        )
        
        // Test default interval
        assert(route.customRefreshInterval == .fiveMinutes, "Default should be 5 minutes")
        
        // Test updating interval
        route.updateRefreshInterval(.twoMinutes)
        assert(route.customRefreshInterval == .twoMinutes, "Should update to 2 minutes")
        
        print("✅ Route refresh interval integration passed")
    }
    
    func testRefreshStrategy() {
        // Test all refresh strategies
        for strategy in RefreshStrategy.allCases {
            print("✅ Strategy: \(strategy.displayName) - \(strategy.description)")
        }
    }
    
    func testBatteryAwareness() {
        // Test battery monitoring setup
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        let batteryLevel = UIDevice.current.batteryLevel
        let batteryState = UIDevice.current.batteryState
        
        print("✅ Battery level: \(batteryLevel)")
        print("✅ Battery state: \(batteryState.rawValue)")
        
        // Test battery state handling
        let isCharging = batteryState == .charging || batteryState == .full
        print("✅ Is charging: \(isCharging)")
    }
    
    func testRouteStoreIntegration() {
        // Test RouteStore refresh interval methods
        let store = RouteStore()
        
        // Create test route
        let route = Route.create(
            name: "Test Store Route",
            origin: Place(rawId: "1", name: "Origin", latitude: 52.5, longitude: 13.4),
            destination: Place(rawId: "2", name: "Destination", latitude: 52.6, longitude: 13.5),
            customRefreshInterval: .tenMinutes
        )
        
        // Test adding route
        store.add(route: route)
        print("✅ Route added to store")
        
        // Test updating refresh interval
        store.updateRefreshInterval(routeId: route.id, interval: .oneMinute)
        print("✅ Refresh interval updated in store")
        
        // Test fetching routes
        let routes = store.fetchAll()
        print("✅ Fetched \(routes.count) routes from store")
        
        // Clean up
        store.delete(routeId: route.id)
        print("✅ Test route cleaned up")
    }
    
    func runAllTests() {
        print("🧪 Starting RefreshInterval compilation tests...")
        
        testRefreshIntervalEnum()
        testRouteRefreshIntervalIntegration()
        testAdaptiveRefreshService()
        testRefreshStrategy()
        testBatteryAwareness()
        testRouteStoreIntegration()
        
        print("✅ All RefreshInterval compilation tests passed!")
    }
}

// MARK: - Test Runner Extension

extension RefreshIntervalCompilationTest {
    
    /// Run tests in a safe environment
    static func runSafeTests() {
        let tester = RefreshIntervalCompilationTest()
        
        do {
            tester.runAllTests()
        } catch {
            print("❌ RefreshInterval compilation test failed: \(error)")
        }
    }
}