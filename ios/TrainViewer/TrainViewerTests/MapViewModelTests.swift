import Testing
import CoreLocation
import MapKit
@testable import TrainViewer

struct MapViewModelTests {
    
    @Test("MapViewModel initializes with correct default values")
    func testInitialization() async throws {
        let mockLocationService = MockLocationService()
        let mockTransportAPI = MockTransportAPI()
        let mockRouteStore = MockRouteStore()
        
        let viewModel = MapViewModel(
            locationService: mockLocationService,
            transportAPI: mockTransportAPI,
            routeStore: mockRouteStore
        )
        
        #expect(viewModel.nearbyStations.isEmpty)
        #expect(viewModel.selectedRoute == nil)
        #expect(viewModel.showingRouteOverlay == false)
        #expect(viewModel.userLocation == nil)
        #expect(viewModel.isLoadingStations == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("MapViewModel initializes with Berlin center as default region")
    func testDefaultRegion() async throws {
        let mockLocationService = MockLocationService()
        let mockTransportAPI = MockTransportAPI()
        let mockRouteStore = MockRouteStore()
        
        let viewModel = MapViewModel(
            locationService: mockLocationService,
            transportAPI: mockTransportAPI,
            routeStore: mockRouteStore
        )
        
        let berlinCoordinate = CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050)
        #expect(abs(viewModel.region.center.latitude - berlinCoordinate.latitude) < 0.001)
        #expect(abs(viewModel.region.center.longitude - berlinCoordinate.longitude) < 0.001)
    }
    
    @Test("MapViewModel centers on user location when available")
    func testCenterOnUserLocationWithLocation() async throws {
        let mockLocationService = MockLocationService()
        let mockTransportAPI = MockTransportAPI()
        let mockRouteStore = MockRouteStore()
        
        let testLocation = CLLocation(latitude: 52.5170, longitude: 13.3888)
        mockLocationService.currentLocation = testLocation
        
        let viewModel = MapViewModel(
            locationService: mockLocationService,
            transportAPI: mockTransportAPI,
            routeStore: mockRouteStore
        )
        
        viewModel.centerOnUserLocation()
        
        #expect(abs(viewModel.region.center.latitude - testLocation.coordinate.latitude) < 0.001)
        #expect(abs(viewModel.region.center.longitude - testLocation.coordinate.longitude) < 0.001)
    }
    
    @Test("MapViewModel requests authorization when no location available")
    func testCenterOnUserLocationWithoutLocation() async throws {
        let mockLocationService = MockLocationService()
        let mockTransportAPI = MockTransportAPI()
        let mockRouteStore = MockRouteStore()
        
        mockLocationService.currentLocation = nil
        
        let viewModel = MapViewModel(
            locationService: mockLocationService,
            transportAPI: mockTransportAPI,
            routeStore: mockRouteStore
        )
        
        viewModel.centerOnUserLocation()
        
        #expect(mockLocationService.requestAuthorizationCalled)
    }
    
    @Test("MapViewModel selects route correctly")
    func testSelectRoute() async throws {
        let mockLocationService = MockLocationService()
        let mockTransportAPI = MockTransportAPI()
        let mockRouteStore = MockRouteStore()
        
        let viewModel = MapViewModel(
            locationService: mockLocationService,
            transportAPI: mockTransportAPI,
            routeStore: mockRouteStore
        )
        
        let route = createTestRoute()
        
        viewModel.selectRoute(route)
        
        #expect(viewModel.selectedRoute?.id == route.id)
        #expect(viewModel.showingRouteOverlay == true)
    }
    
    @Test("MapViewModel clears selected route correctly")
    func testClearSelectedRoute() async throws {
        let mockLocationService = MockLocationService()
        let mockTransportAPI = MockTransportAPI()
        let mockRouteStore = MockRouteStore()
        
        let viewModel = MapViewModel(
            locationService: mockLocationService,
            transportAPI: mockTransportAPI,
            routeStore: mockRouteStore
        )
        
        let route = createTestRoute()
        viewModel.selectRoute(route)
        
        viewModel.clearSelectedRoute()
        
        #expect(viewModel.selectedRoute == nil)
        #expect(viewModel.showingRouteOverlay == false)
    }
    
    @Test("MapViewModel updates region for route correctly")
    func testUpdateRegionForRoute() async throws {
        let mockLocationService = MockLocationService()
        let mockTransportAPI = MockTransportAPI()
        let mockRouteStore = MockRouteStore()
        
        let viewModel = MapViewModel(
            locationService: mockLocationService,
            transportAPI: mockTransportAPI,
            routeStore: mockRouteStore
        )
        
        let route = createTestRoute()
        
        viewModel.updateRegionForRoute(route)
        
        // Should center between origin and destination
        let expectedLat = (route.origin.latitude! + route.destination.latitude!) / 2
        let expectedLon = (route.origin.longitude! + route.destination.longitude!) / 2
        
        #expect(abs(viewModel.region.center.latitude - expectedLat) < 0.001)
        #expect(abs(viewModel.region.center.longitude - expectedLon) < 0.001)
    }
    
    @Test("MapViewModel creates route polyline correctly")
    func testCreateRoutePolyline() async throws {
        let mockLocationService = MockLocationService()
        let mockTransportAPI = MockTransportAPI()
        let mockRouteStore = MockRouteStore()
        
        let viewModel = MapViewModel(
            locationService: mockLocationService,
            transportAPI: mockTransportAPI,
            routeStore: mockRouteStore
        )
        
        let route = createTestRoute()
        viewModel.selectedRoute = route
        
        let polyline = viewModel.createRoutePolyline()
        
        #expect(polyline != nil)
        #expect(polyline?.pointCount == 2)
    }
    
    @Test("MapViewModel returns nil polyline without route")
    func testCreateRoutePolylineWithoutRoute() async throws {
        let mockLocationService = MockLocationService()
        let mockTransportAPI = MockTransportAPI()
        let mockRouteStore = MockRouteStore()
        
        let viewModel = MapViewModel(
            locationService: mockLocationService,
            transportAPI: mockTransportAPI,
            routeStore: mockRouteStore
        )
        
        viewModel.selectedRoute = nil
        
        let polyline = viewModel.createRoutePolyline()
        
        #expect(polyline == nil)
    }
    
    @Test("MapViewModel creates route annotations correctly")
    func testCreateRouteAnnotations() async throws {
        let mockRouteStore = MockRouteStore()
        let routes = [createTestRoute(), createTestRoute(name: "Route 2")]
        mockRouteStore.routes = routes
        
        let viewModel = MapViewModel(
            locationService: MockLocationService(),
            transportAPI: MockTransportAPI(),
            routeStore: mockRouteStore
        )
        
        let annotations = viewModel.createRouteAnnotations()
        
        #expect(annotations.count == 4) // 2 routes × 2 points each
        
        let originAnnotations = annotations.filter { $0.type == .origin }
        let destinationAnnotations = annotations.filter { $0.type == .destination }
        
        #expect(originAnnotations.count == 2)
        #expect(destinationAnnotations.count == 2)
    }
    
    @Test("MapViewModel creates station annotations correctly")
    func testCreateStationAnnotations() async throws {
        let mockLocationService = MockLocationService()
        let mockTransportAPI = MockTransportAPI()
        let mockRouteStore = MockRouteStore()
        
        let viewModel = MapViewModel(
            locationService: mockLocationService,
            transportAPI: mockTransportAPI,
            routeStore: mockRouteStore
        )
        
        let stations = [
            TransitStation(
                id: "1",
                name: "Test Station",
                coordinate: CLLocationCoordinate2D(latitude: 52.5170, longitude: 13.3888),
                type: .train
            )
        ]
        viewModel.nearbyStations = stations
        
        let annotations = viewModel.createStationAnnotations()
        
        #expect(annotations.count == 1)
        #expect(annotations[0].title == "Test Station")
        #expect(annotations[0].subtitle == "Train")
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
