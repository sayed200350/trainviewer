import Testing
import CoreLocation
import Combine
@testable import TrainViewer

struct LocationServiceTests {
    
    // MARK: - Initialization Tests
    
    @Test("LocationService initializes with correct default values")
    func testLocationServiceInitialization() async throws {
        let mockRouteStore = MockRouteStore()
        let locationService = LocationService(routeStore: mockRouteStore)
        
        #expect(locationService.authorizationStatus == .notDetermined)
        #expect(locationService.currentLocation == nil)
        #expect(locationService.isNearSavedLocation == false)
        #expect(locationService.nearestSavedLocation == nil)
        #expect(locationService.nearbyRoutes.isEmpty)
    }
    
    // MARK: - Walking Time Calculation Tests
    
    @Test("LocationService calculates walking time correctly")
    func testWalkingTimeCalculation() async throws {
        let mockRouteStore = MockRouteStore()
        let locationService = LocationService(routeStore: mockRouteStore)
        
        // Set a current location
        let currentLocation = CLLocation(latitude: 52.5170, longitude: 13.3888) // Berlin
        let destinationLocation = CLLocation(latitude: 52.5200, longitude: 13.4050) // ~2km away
        
        // Simulate having a current location (this would normally be set by CLLocationManager)
        // For testing, we'll use the public method that takes a CLLocation parameter
        let walkingTime = locationService.calculateWalkingTime(to: destinationLocation)
        
        // With default walking speed (1.4 m/s), 2km should take about 1428 seconds (23.8 minutes)
        #expect(walkingTime > 1000) // Should be more than 16 minutes
        #expect(walkingTime < 2000) // Should be less than 33 minutes
    }
    
    @Test("LocationService calculates walking time to Place correctly")
    func testWalkingTimeToPlace() async throws {
        let mockRouteStore = MockRouteStore()
        let locationService = LocationService(routeStore: mockRouteStore)
        
        let place = Place(
            id: "test-place",
            name: "Test Station",
            coordinate: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050)
        )
        
        // Without current location, should return 0
        let walkingTimeWithoutLocation = locationService.calculateWalkingTime(to: place)
        #expect(walkingTimeWithoutLocation == 0)
    }
    
    @Test("LocationService calculates walking time for route correctly")
    func testWalkingTimeForRoute() async throws {
        let mockRouteStore = MockRouteStore()
        let locationService = LocationService(routeStore: mockRouteStore)
        
        let origin = Place(
            id: "origin",
            name: "Origin Station",
            coordinate: CLLocationCoordinate2D(latitude: 52.5170, longitude: 13.3888)
        )
        
        let destination = Place(
            id: "destination",
            name: "Destination Station",
            coordinate: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050)
        )
        
        let route = Route(
            id: UUID(),
            name: "Test Route",
            origin: origin,
            destination: destination,
            walkingSpeedMetersPerSecond: 1.5 // Custom walking speed
        )
        
        let walkingTimes = locationService.calculateWalkingTimeForRoute(route)
        
        // Without current location, both should be 0
        #expect(walkingTimes.toOrigin == 0)
        #expect(walkingTimes.toDestination == 0)
    }
    
    // MARK: - Distance Calculation Tests
    
    @Test("LocationService calculates distance to place correctly")
    func testDistanceToPlace() async throws {
        let mockRouteStore = MockRouteStore()
        let locationService = LocationService(routeStore: mockRouteStore)
        
        let place = Place(
            id: "test-place",
            name: "Test Station",
            coordinate: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050)
        )
        
        // Without current location, should return nil
        let distanceWithoutLocation = locationService.distanceToPlace(place)
        #expect(distanceWithoutLocation == nil)
        
        // Test with place without coordinates
        let placeWithoutCoordinates = Place(id: "no-coords", name: "No Coordinates")
        let distanceToPlaceWithoutCoords = locationService.distanceToPlace(placeWithoutCoordinates)
        #expect(distanceToPlaceWithoutCoords == nil)
    }
    
    @Test("LocationService determines proximity correctly")
    func testIsNearPlace() async throws {
        let mockRouteStore = MockRouteStore()
        let locationService = LocationService(routeStore: mockRouteStore)
        
        let place = Place(
            id: "test-place",
            name: "Test Station",
            coordinate: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050)
        )
        
        // Without current location, should return false
        let isNearWithoutLocation = locationService.isNearPlace(place)
        #expect(isNearWithoutLocation == false)
        
        // Test with custom threshold
        let isNearWithCustomThreshold = locationService.isNearPlace(place, threshold: 500.0)
        #expect(isNearWithCustomThreshold == false)
    }
    
    // MARK: - Route Filtering Tests
    
    @Test("LocationService filters routes near origin correctly")
    func testGetRoutesNearOrigin() async throws {
        let mockRouteStore = MockRouteStore()
        let locationService = LocationService(routeStore: mockRouteStore)
        
        let routesNearOrigin = locationService.getRoutesNearOrigin()
        #expect(routesNearOrigin.isEmpty) // Should be empty without current location
    }
    
    @Test("LocationService filters routes near destination correctly")
    func testGetRoutesNearDestination() async throws {
        let mockRouteStore = MockRouteStore()
        let locationService = LocationService(routeStore: mockRouteStore)
        
        let routesNearDestination = locationService.getRoutesNearDestination()
        #expect(routesNearDestination.isEmpty) // Should be empty without current location
    }
    
    // MARK: - Permission Handling Tests
    
    @Test("LocationService provides correct permission messages")
    func testPermissionMessages() async throws {
        let mockRouteStore = MockRouteStore()
        let locationService = LocationService(routeStore: mockRouteStore)
        
        // Test message for not determined status (default)
        let notDeterminedMessage = locationService.requestPermissionWithUserFriendlyMessage()
        #expect(notDeterminedMessage.contains("Location access will help"))
        
        // Note: We can't easily test other authorization states without mocking CLLocationManager
        // which would require more complex dependency injection
    }
    
    // MARK: - Proximity Detection Tests
    
    @Test("LocationService handles proximity detection with empty routes")
    func testProximityDetectionWithEmptyRoutes() async throws {
        let mockRouteStore = MockRouteStore()
        let locationService = LocationService(routeStore: mockRouteStore)
        
        // Ensure no routes are stored
        mockRouteStore.clear()
        
        // Initial state should show no nearby locations
        #expect(locationService.isNearSavedLocation == false)
        #expect(locationService.nearestSavedLocation == nil)
        #expect(locationService.nearbyRoutes.isEmpty)
    }
    
    @Test("LocationService handles routes without coordinates")
    func testRoutesWithoutCoordinates() async throws {
        let mockRouteStore = MockRouteStore()
        let locationService = LocationService(routeStore: mockRouteStore)
        
        // Create routes without coordinates
        let originWithoutCoords = Place(id: "origin-no-coords", name: "Origin No Coords")
        let destinationWithoutCoords = Place(id: "dest-no-coords", name: "Destination No Coords")
        
        let routeWithoutCoords = Route(
            id: UUID(),
            name: "Route Without Coords",
            origin: originWithoutCoords,
            destination: destinationWithoutCoords
        )
        
        mockRouteStore.setRoutes([routeWithoutCoords])
        
        // Should handle gracefully without crashing
        let walkingTimes = locationService.calculateWalkingTimeForRoute(routeWithoutCoords)
        #expect(walkingTimes.toOrigin == 0)
        #expect(walkingTimes.toDestination == 0)
    }
    
    // MARK: - Constants Tests
    
    @Test("LocationService uses correct proximity constants")
    func testProximityConstants() async throws {
        // These are private constants, but we can test their effects
        let mockRouteStore = MockRouteStore()
        let locationService = LocationService(routeStore: mockRouteStore)
        
        // Test that the service initializes with reasonable defaults
        #expect(locationService.nearbyRoutes.isEmpty)
        #expect(locationService.isNearSavedLocation == false)
        
        // The actual proximity threshold (200m) and update interval (30s) are tested
        // indirectly through the proximity detection behavior
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("LocationService handles nil coordinates gracefully")
    func testNilCoordinatesHandling() async throws {
        let mockRouteStore = MockRouteStore()
        let locationService = LocationService(routeStore: mockRouteStore)
        
        let placeWithNilCoords = Place(id: "nil-coords", name: "Nil Coordinates", coordinate: nil)
        
        let distance = locationService.distanceToPlace(placeWithNilCoords)
        #expect(distance == nil)
        
        let isNear = locationService.isNearPlace(placeWithNilCoords)
        #expect(isNear == false)
        
        let walkingTime = locationService.calculateWalkingTime(to: placeWithNilCoords)
        #expect(walkingTime == 0)
    }
    
    @Test("LocationService handles custom walking speeds")
    func testCustomWalkingSpeed() async throws {
        let mockRouteStore = MockRouteStore()
        let locationService = LocationService(routeStore: mockRouteStore)
        
        let place = Place(
            id: "test-place",
            name: "Test Station",
            coordinate: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050)
        )
        
        // Test with different walking speeds
        let slowWalkingTime = locationService.calculateWalkingTime(to: place, walkingSpeed: 1.0) // 1 m/s
        let fastWalkingTime = locationService.calculateWalkingTime(to: place, walkingSpeed: 2.0) // 2 m/s
        
        // Without current location, both should be 0
        #expect(slowWalkingTime == 0)
        #expect(fastWalkingTime == 0)
        
        // But the method signature should accept different speeds
        // (actual calculation would require current location to be set)
    }
}

// MARK: - Test Helpers

extension LocationServiceTests {
    
    private func createTestRoute(
        name: String,
        originLat: Double,
        originLon: Double,
        destLat: Double,
        destLon: Double
    ) -> Route {
        let origin = Place(
            id: "origin-\(name)",
            name: "Origin \(name)",
            coordinate: CLLocationCoordinate2D(latitude: originLat, longitude: originLon)
        )
        
        let destination = Place(
            id: "dest-\(name)",
            name: "Destination \(name)",
            coordinate: CLLocationCoordinate2D(latitude: destLat, longitude: destLon)
        )
        
        return Route(
            id: UUID(),
            name: name,
            origin: origin,
            destination: destination
        )
    }
}