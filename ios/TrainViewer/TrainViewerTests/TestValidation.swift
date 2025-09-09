import Testing
import Foundation
import CoreLocation
@testable import TrainViewer


/// Simple validation to ensure all test components are properly structured
struct TestValidation {
    
    @Test("All test components can be instantiated")
    func testComponentInstantiation() async throws {
        // Test that we can create all the main components without errors
        
        // Test TransitStation creation
        let coordinate = CLLocationCoordinate2D(latitude: 52.5170, longitude: 13.3888)
        let station = TransitStation(
            id: "test",
            name: "Test Station",
            coordinate: coordinate,
            type: .train
        )
        #expect(station.id == "test")
        
        // Test mock services can be created
        let mockLocationService = MockLocationService()
        let mockTransportAPI = MockTransportAPI()
        let mockRouteStore = MockRouteStore()
        
        #expect(mockLocationService != nil)
        #expect(mockTransportAPI != nil)
        #expect(mockRouteStore != nil)
        
        // Test that we can create real services for MapViewModel testing
        // (MapViewModel requires actual types, not mock protocols)
        let locationService = LocationService.shared
        let transportAPI = TransportAPIFactory.createAPI()
        let routeStore = RouteStore()
        
        #expect(locationService != nil)
        #expect(transportAPI != nil)
        #expect(routeStore != nil)
        
        // Test MapComponentValidator can run
        let report = MapComponentValidator.validateMapComponents()
        #expect(report.totalTests > 0)
    }
    
    @Test("StationType enum is complete")
    func testStationTypeCompleteness() async throws {
        let allTypes = StationType.allCases
        #expect(allTypes.count == 5)
        
        // Verify all types have proper display names and icons
        for type in allTypes {
            #expect(!type.displayName.isEmpty)
            #expect(!type.iconName.isEmpty)
            #expect(!type.rawValue.isEmpty)
        }
    }
    
    @Test("Route creation works correctly")
    func testRouteCreation() async throws {
        let origin = Place(rawId: "origin", name: "Origin", latitude: 52.5170, longitude: 13.3888)
        let destination = Place(rawId: "dest", name: "Destination", latitude: 52.5200, longitude: 13.4050)
        
        let route = Route(
            name: "Test Route",
            origin: origin,
            destination: destination,
            color: .blue,
            isFavorite: false
        )
        
        #expect(route.name == "Test Route")
        #expect(route.origin.name == "Origin")
        #expect(route.destination.name == "Destination")
        #expect(route.color == .blue)
        #expect(route.isFavorite == false)
    }
}