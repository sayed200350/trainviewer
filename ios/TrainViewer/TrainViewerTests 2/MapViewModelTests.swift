import Testing
import CoreLocation
import MapKit
@testable import TrainViewer

struct MapViewModelTests {
    
    @Test("MapViewModel initializes with correct default values")
    @MainActor
    func testInitialization() async throws {
        let locationService = LocationService.shared
        let transportAPI = TransportAPIFactory.createAPI()
        let routeStore = RouteStore()
        
        let viewModel = MapViewModel(
            locationService: locationService,
            transportAPI: transportAPI,
            routeStore: routeStore
        )
        
        #expect(viewModel.nearbyStations.isEmpty)
        #expect(viewModel.selectedRoute == nil)
        #expect(viewModel.showingRouteOverlay == false)
        #expect(viewModel.userLocation == nil)
        #expect(viewModel.isLoadingStations == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("MapViewModel initializes with Berlin center as default region")
    @MainActor
    func testDefaultRegion() async throws {
        let locationService = LocationService.shared
        let transportAPI = TransportAPIFactory.createAPI()
        let routeStore = RouteStore()
        
        let viewModel = MapViewModel(
            locationService: locationService,
            transportAPI: transportAPI,
            routeStore: routeStore
        )
        
        let berlinCoordinate = CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050)
        #expect(abs(viewModel.region.center.latitude - berlinCoordinate.latitude) < 0.001)
        #expect(abs(viewModel.region.center.longitude - berlinCoordinate.longitude) < 0.001)
    }
    
    // Note: Simplified tests using real services instead of mocks
    // This approach avoids complex mocking setup while still testing core functionality
    
    @Test("MapViewModel basic functionality works")
    @MainActor
    func testBasicFunctionality() async throws {
        let locationService = LocationService.shared
        let transportAPI = TransportAPIFactory.createAPI()
        let routeStore = RouteStore()
        
        let viewModel = MapViewModel(
            locationService: locationService,
            transportAPI: transportAPI,
            routeStore: routeStore
        )
        
        // Test route selection
        let route = createTestRoute()
        viewModel.selectRoute(route)
        #expect(viewModel.selectedRoute?.id == route.id)
        #expect(viewModel.showingRouteOverlay == true)
        
        // Test route clearing
        viewModel.clearSelectedRoute()
        #expect(viewModel.selectedRoute == nil)
        #expect(viewModel.showingRouteOverlay == false)
        
        // Test polyline creation
        viewModel.selectedRoute = route
        let polyline = viewModel.createRoutePolyline()
        #expect(polyline != nil)
        #expect(polyline?.pointCount == 2)
        
        // Test without route
        viewModel.selectedRoute = nil
        let nilPolyline = viewModel.createRoutePolyline()
        #expect(nilPolyline == nil)
    }
    
    // MARK: - Helper Methods
    
    private func createTestRoute(name: String = "Test Route", 
                                color: RouteColor = .blue, 
                                isFavorite: Bool = false) -> Route {
        return Route(
            name: name,
            origin: Place(rawId: "origin1", name: "Origin", latitude: 52.5170, longitude: 13.3888),
            destination: Place(rawId: "dest1", name: "Destination", latitude: 52.5200, longitude: 13.4050),
            color: color,
            isFavorite: isFavorite
        )
    }
}

// MARK: - Mock Classes

// MARK: - Mock Protocols
private protocol MockLocationServiceProtocol {
    var requestAuthorizationCalled: Bool { get set }
    var currentLocation: CLLocation? { get set }
    func requestAuthorization()
    func simulateLocationUpdate(_ location: CLLocation)
}

private protocol MockTransportAPIProtocol {
    var searchLocationsCalled: Bool { get set }
    var nextJourneyOptionsCalled: Bool { get set }
    func searchLocations(query: String, limit: Int) async throws -> [Place]
    func nextJourneyOptions(from: Place, to: Place, results: Int) async throws -> [JourneyOption]
}

private protocol MockRouteStoreProtocol {
    var routes: [Route] { get set }
    func fetchAll() -> [Route]
    func add(route: Route)
    func update(route: Route)
    func delete(routeId: UUID)
    func fetchFavorites() -> [Route]
}

// MARK: - Mock Implementations
class MockLocationService: MockLocationServiceProtocol {
    var requestAuthorizationCalled = false
    var currentLocation: CLLocation?
    
    func requestAuthorization() {
        requestAuthorizationCalled = true
    }
    
    func simulateLocationUpdate(_ location: CLLocation) {
        DispatchQueue.main.async {
            self.currentLocation = location
        }
    }
}

class MockTransportAPI: MockTransportAPIProtocol {
    var searchLocationsCalled = false
    var nextJourneyOptionsCalled = false
    
    func searchLocations(query: String, limit: Int) async throws -> [Place] {
        searchLocationsCalled = true
        return []
    }
    
    func nextJourneyOptions(from: Place, to: Place, results: Int) async throws -> [JourneyOption] {
        nextJourneyOptionsCalled = true
        return []
    }
}

class MockRouteStore: MockRouteStoreProtocol {
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
    
    func fetchFavorites() -> [Route] {
        return routes.filter { $0.isFavorite }
    }
}