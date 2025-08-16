import Foundation
import CoreLocation

/// A utility class to validate LocationService functionality
/// This provides testing capabilities without requiring XCTest framework
final class LocationServiceValidator {
    
    // MARK: - Test Results
    
    struct TestResult {
        let testName: String
        let passed: Bool
        let message: String
        let executionTime: TimeInterval
    }
    
    struct ValidationReport {
        let totalTests: Int
        let passedTests: Int
        let failedTests: Int
        let results: [TestResult]
        let totalExecutionTime: TimeInterval
        
        var successRate: Double {
            return totalTests > 0 ? Double(passedTests) / Double(totalTests) : 0.0
        }
    }
    
    // MARK: - Validation Methods
    
    static func validateLocationService() -> ValidationReport {
        var results: [TestResult] = []
        let startTime = Date()
        
        // Test walking time calculations
        results.append(testWalkingTimeCalculation())
        results.append(testWalkingTimeWithCustomSpeed())
        results.append(testWalkingTimeWithoutCurrentLocation())
        results.append(testWalkingTimeToPlaceWithoutCoordinates())
        
        // Test distance calculations
        results.append(testDistanceCalculation())
        results.append(testDistanceToPlaceWithoutCoordinates())
        
        // Test proximity detection logic
        results.append(testProximityDetectionLogic())
        results.append(testIsNearPlaceMethod())
        
        // Test permission handling
        results.append(testPermissionMessages())
        
        // Test edge cases
        results.append(testExtremeDistances())
        results.append(testInvalidCoordinates())
        
        let totalExecutionTime = Date().timeIntervalSince(startTime)
        let passedTests = results.filter { $0.passed }.count
        
        return ValidationReport(
            totalTests: results.count,
            passedTests: passedTests,
            failedTests: results.count - passedTests,
            results: results,
            totalExecutionTime: totalExecutionTime
        )
    }
    
    // MARK: - Individual Test Methods
    
    private static func testWalkingTimeCalculation() -> TestResult {
        let startTime = Date()
        let testName = "Walking Time Calculation"
        
        do {
            let mockRouteStore: RouteStoreProtocol = MockRouteStore()
            let locationService = LocationService(routeStore: mockRouteStore)
            
            let currentLocation = CLLocation(latitude: 52.5200, longitude: 13.4050)
            let destination = CLLocation(latitude: 52.5170, longitude: 13.3888)
            
            // Simulate setting current location by directly calling the delegate method
            let manager = CLLocationManager()
            let delegate = locationService as CLLocationManagerDelegate
            delegate.locationManager?(manager, didUpdateLocations: [currentLocation])
            
            let walkingTime = locationService.calculateWalkingTime(to: destination)
            
            let expectedDistance = currentLocation.distance(from: destination)
            let expectedTime = expectedDistance / AppConstants.defaultWalkingSpeedMetersPerSecond
            
            let isValid = abs(walkingTime - expectedTime) < 1.0
            let executionTime = Date().timeIntervalSince(startTime)
            
            return TestResult(
                testName: testName,
                passed: isValid,
                message: isValid ? "Walking time calculation is accurate" : "Walking time calculation failed: expected \(expectedTime), got \(walkingTime)",
                executionTime: executionTime
            )
        } catch {
            return TestResult(
                testName: testName,
                passed: false,
                message: "Test failed with error: \(error)",
                executionTime: Date().timeIntervalSince(startTime)
            )
        }
    }
    
    private static func testWalkingTimeWithCustomSpeed() -> TestResult {
        let startTime = Date()
        let testName = "Walking Time with Custom Speed"
        
        do {
            let mockRouteStore: RouteStoreProtocol = MockRouteStore()
            let locationService = LocationService(routeStore: mockRouteStore)
            
            let currentLocation = CLLocation(latitude: 52.5200, longitude: 13.4050)
            let destination = CLLocation(latitude: 52.5170, longitude: 13.3888)
            let customSpeed = 2.0
            
            // Simulate setting current location
            let manager = CLLocationManager()
            let delegate = locationService as CLLocationManagerDelegate
            delegate.locationManager?(manager, didUpdateLocations: [currentLocation])
            
            let walkingTime = locationService.calculateWalkingTime(to: destination, walkingSpeed: customSpeed)
            
            let expectedDistance = currentLocation.distance(from: destination)
            let expectedTime = expectedDistance / customSpeed
            
            let isValid = abs(walkingTime - expectedTime) < 1.0
            let executionTime = Date().timeIntervalSince(startTime)
            
            return TestResult(
                testName: testName,
                passed: isValid,
                message: isValid ? "Custom speed calculation works correctly" : "Custom speed calculation failed",
                executionTime: executionTime
            )
        } catch {
            return TestResult(
                testName: testName,
                passed: false,
                message: "Test failed with error: \(error)",
                executionTime: Date().timeIntervalSince(startTime)
            )
        }
    }
    
    private static func testWalkingTimeWithoutCurrentLocation() -> TestResult {
        let startTime = Date()
        let testName = "Walking Time without Current Location"
        
        do {
            let mockRouteStore: RouteStoreProtocol = MockRouteStore()
            let locationService = LocationService(routeStore: mockRouteStore)
            
            let destination = CLLocation(latitude: 52.5170, longitude: 13.3888)
            let walkingTime = locationService.calculateWalkingTime(to: destination)
            
            let isValid = walkingTime == 0
            let executionTime = Date().timeIntervalSince(startTime)
            
            return TestResult(
                testName: testName,
                passed: isValid,
                message: isValid ? "Correctly returns 0 when no current location" : "Should return 0 when no current location",
                executionTime: executionTime
            )
        } catch {
            return TestResult(
                testName: testName,
                passed: false,
                message: "Test failed with error: \(error)",
                executionTime: Date().timeIntervalSince(startTime)
            )
        }
    }
    
    private static func testWalkingTimeToPlaceWithoutCoordinates() -> TestResult {
        let startTime = Date()
        let testName = "Walking Time to Place without Coordinates"
        
        do {
            let mockRouteStore: RouteStoreProtocol = MockRouteStore()
            let locationService = LocationService(routeStore: mockRouteStore)
            
            let currentLocation = CLLocation(latitude: 52.5200, longitude: 13.4050)
            let place = Place(rawId: "test", name: "Test Place", latitude: nil, longitude: nil)
            
            // Simulate setting current location
            let manager = CLLocationManager()
            let delegate = locationService as CLLocationManagerDelegate
            delegate.locationManager?(manager, didUpdateLocations: [currentLocation])
            
            let walkingTime = locationService.calculateWalkingTime(to: place)
            
            let isValid = walkingTime == 0
            let executionTime = Date().timeIntervalSince(startTime)
            
            return TestResult(
                testName: testName,
                passed: isValid,
                message: isValid ? "Correctly handles places without coordinates" : "Should return 0 for places without coordinates",
                executionTime: executionTime
            )
        } catch {
            return TestResult(
                testName: testName,
                passed: false,
                message: "Test failed with error: \(error)",
                executionTime: Date().timeIntervalSince(startTime)
            )
        }
    }
    
    private static func testDistanceCalculation() -> TestResult {
        let startTime = Date()
        let testName = "Distance Calculation"
        
        do {
            let mockRouteStore: RouteStoreProtocol = MockRouteStore()
            let locationService = LocationService(routeStore: mockRouteStore)
            
            let currentLocation = CLLocation(latitude: 52.5200, longitude: 13.4050)
            let place = Place(rawId: "test", name: "Test Place", latitude: 52.5170, longitude: 13.3888)
            
            // Simulate setting current location
            let manager = CLLocationManager()
            let delegate = locationService as CLLocationManagerDelegate
            delegate.locationManager?(manager, didUpdateLocations: [currentLocation])
            
            let distance = locationService.distanceToPlace(place)
            
            let isValid = distance != nil && distance! > 0
            let executionTime = Date().timeIntervalSince(startTime)
            
            return TestResult(
                testName: testName,
                passed: isValid,
                message: isValid ? "Distance calculation works correctly" : "Distance calculation failed",
                executionTime: executionTime
            )
        } catch {
            return TestResult(
                testName: testName,
                passed: false,
                message: "Test failed with error: \(error)",
                executionTime: Date().timeIntervalSince(startTime)
            )
        }
    }
    
    private static func testDistanceToPlaceWithoutCoordinates() -> TestResult {
        let startTime = Date()
        let testName = "Distance to Place without Coordinates"
        
        do {
            let mockRouteStore: RouteStoreProtocol = MockRouteStore()
            let locationService = LocationService(routeStore: mockRouteStore)
            
            let currentLocation = CLLocation(latitude: 52.5200, longitude: 13.4050)
            let place = Place(rawId: "test", name: "Test Place", latitude: nil, longitude: nil)
            
            // Simulate setting current location
            let manager = CLLocationManager()
            let delegate = locationService as CLLocationManagerDelegate
            delegate.locationManager?(manager, didUpdateLocations: [currentLocation])
            
            let distance = locationService.distanceToPlace(place)
            
            let isValid = distance == nil
            let executionTime = Date().timeIntervalSince(startTime)
            
            return TestResult(
                testName: testName,
                passed: isValid,
                message: isValid ? "Correctly returns nil for places without coordinates" : "Should return nil for places without coordinates",
                executionTime: executionTime
            )
        } catch {
            return TestResult(
                testName: testName,
                passed: false,
                message: "Test failed with error: \(error)",
                executionTime: Date().timeIntervalSince(startTime)
            )
        }
    }
    
    private static func testProximityDetectionLogic() -> TestResult {
        let startTime = Date()
        let testName = "Proximity Detection Logic"
        
        do {
            let mockRouteStore: RouteStoreProtocol = MockRouteStore()
            let locationService = LocationService(routeStore: mockRouteStore)
            
            let currentLocation = CLLocation(latitude: 52.5200, longitude: 13.4050)
            let nearbyPlace = Place(rawId: "test", name: "Nearby Place", latitude: 52.5202, longitude: 13.4052)
            
            // Simulate setting current location
            let manager = CLLocationManager()
            let delegate = locationService as CLLocationManagerDelegate
            delegate.locationManager?(manager, didUpdateLocations: [currentLocation])
            
            let isNear = locationService.isNearPlace(nearbyPlace, threshold: 100.0)
            
            let executionTime = Date().timeIntervalSince(startTime)
            
            return TestResult(
                testName: testName,
                passed: isNear,
                message: isNear ? "Proximity detection works correctly" : "Proximity detection failed for nearby place",
                executionTime: executionTime
            )
        } catch {
            return TestResult(
                testName: testName,
                passed: false,
                message: "Test failed with error: \(error)",
                executionTime: Date().timeIntervalSince(startTime)
            )
        }
    }
    
    private static func testIsNearPlaceMethod() -> TestResult {
        let startTime = Date()
        let testName = "Is Near Place Method"
        
        do {
            let mockRouteStore: RouteStoreProtocol = MockRouteStore()
            let locationService = LocationService(routeStore: mockRouteStore)
            
            let currentLocation = CLLocation(latitude: 52.5200, longitude: 13.4050)
            let farPlace = Place(rawId: "test", name: "Far Place", latitude: 52.5300, longitude: 13.4200)
            
            // Simulate setting current location
            let manager = CLLocationManager()
            let delegate = locationService as CLLocationManagerDelegate
            delegate.locationManager?(manager, didUpdateLocations: [currentLocation])
            
            let isNear = locationService.isNearPlace(farPlace, threshold: 100.0)
            
            let executionTime = Date().timeIntervalSince(startTime)
            
            return TestResult(
                testName: testName,
                passed: !isNear,
                message: !isNear ? "Correctly identifies far places as not near" : "Should not identify far places as near",
                executionTime: executionTime
            )
        } catch {
            return TestResult(
                testName: testName,
                passed: false,
                message: "Test failed with error: \(error)",
                executionTime: Date().timeIntervalSince(startTime)
            )
        }
    }
    
    private static func testPermissionMessages() -> TestResult {
        let startTime = Date()
        let testName = "Permission Messages"
        
        do {
            // Test permission messages without needing to set internal state
            let mockRouteStore: RouteStoreProtocol = MockRouteStore()
            
            // Test that the method exists and returns reasonable messages
            let locationService = LocationService(routeStore: mockRouteStore)
            let message = locationService.requestPermissionWithUserFriendlyMessage()
            
            // Verify it returns a non-empty, reasonable message
            let isValid = !message.isEmpty && message.contains("Location")
            
            let executionTime = Date().timeIntervalSince(startTime)
            
            return TestResult(
                testName: testName,
                passed: isValid,
                message: isValid ? "Permission messages are working" : "Permission message method failed",
                executionTime: executionTime
            )
        } catch {
            return TestResult(
                testName: testName,
                passed: false,
                message: "Test failed with error: \(error)",
                executionTime: Date().timeIntervalSince(startTime)
            )
        }
    }
    
    private static func testExtremeDistances() -> TestResult {
        let startTime = Date()
        let testName = "Extreme Distances"
        
        do {
            let mockRouteStore: RouteStoreProtocol = MockRouteStore()
            let locationService = LocationService(routeStore: mockRouteStore)
            
            let currentLocation = CLLocation(latitude: 52.5200, longitude: 13.4050)
            let veryClose = CLLocation(latitude: 52.5200001, longitude: 13.4050001)
            let veryFar = CLLocation(latitude: -33.8688, longitude: 151.2093) // Sydney
            
            // Simulate setting current location
            let manager = CLLocationManager()
            let delegate = locationService as CLLocationManagerDelegate
            delegate.locationManager?(manager, didUpdateLocations: [currentLocation])
            
            let shortTime = locationService.calculateWalkingTime(to: veryClose)
            let longTime = locationService.calculateWalkingTime(to: veryFar)
            
            let shortValid = shortTime > 0 && shortTime < 10
            let longValid = longTime > 1000000
            
            let executionTime = Date().timeIntervalSince(startTime)
            
            return TestResult(
                testName: testName,
                passed: shortValid && longValid,
                message: (shortValid && longValid) ? "Extreme distances handled correctly" : "Extreme distance calculations failed",
                executionTime: executionTime
            )
        } catch {
            return TestResult(
                testName: testName,
                passed: false,
                message: "Test failed with error: \(error)",
                executionTime: Date().timeIntervalSince(startTime)
            )
        }
    }
    
    private static func testInvalidCoordinates() -> TestResult {
        let startTime = Date()
        let testName = "Invalid Coordinates"
        
        do {
            let mockRouteStore: RouteStoreProtocol = MockRouteStore()
            let locationService = LocationService(routeStore: mockRouteStore)
            
            let currentLocation = CLLocation(latitude: 52.5200, longitude: 13.4050)
            let invalidPlace = Place(rawId: "invalid", name: "Invalid Place", latitude: nil, longitude: nil)
            
            // Simulate setting current location
            let manager = CLLocationManager()
            let delegate = locationService as CLLocationManagerDelegate
            delegate.locationManager?(manager, didUpdateLocations: [currentLocation])
            
            let walkingTime = locationService.calculateWalkingTime(to: invalidPlace)
            let distance = locationService.distanceToPlace(invalidPlace)
            let isNear = locationService.isNearPlace(invalidPlace)
            
            let isValid = walkingTime == 0 && distance == nil && !isNear
            let executionTime = Date().timeIntervalSince(startTime)
            
            return TestResult(
                testName: testName,
                passed: isValid,
                message: isValid ? "Invalid coordinates handled gracefully" : "Invalid coordinates not handled properly",
                executionTime: executionTime
            )
        } catch {
            return TestResult(
                testName: testName,
                passed: false,
                message: "Test failed with error: \(error)",
                executionTime: Date().timeIntervalSince(startTime)
            )
        }
    }
    
    // MARK: - Report Generation
    
    static func printValidationReport(_ report: ValidationReport) {
        print("\n=== LocationService Validation Report ===")
        print("Total Tests: \(report.totalTests)")
        print("Passed: \(report.passedTests)")
        print("Failed: \(report.failedTests)")
        print("Success Rate: \(String(format: "%.1f", report.successRate * 100))%")
        print("Total Execution Time: \(String(format: "%.3f", report.totalExecutionTime))s")
        print("\n--- Individual Test Results ---")
        
        for result in report.results {
            let status = result.passed ? "✅ PASS" : "❌ FAIL"
            let time = String(format: "%.3f", result.executionTime)
            print("\(status) \(result.testName) (\(time)s)")
            if !result.passed {
                print("   └─ \(result.message)")
            }
        }
        
        print("\n=== End Report ===\n")
    }
}

// MARK: - Mock RouteStore for Testing

class MockRouteStore: RouteStoreProtocol {
    var routes: [Route] = []
    
    func fetchAll() -> [Route] {
        return routes
    }
    
    func add(route: Route) {
        routes.append(route)
    }
    
    func update(route: Route) {
        if let index = routes.firstIndex(where: { $0.id == route.id }) {
            routes[index] = route
        }
    }
    
    func delete(routeId: UUID) {
        routes.removeAll { $0.id == routeId }
    }
}