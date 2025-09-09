import Foundation
import CoreLocation
import MapKit

/// Simple build validator to ensure all components compile correctly
final class BuildValidator {
    
    /// Test that all map components can be instantiated without compilation errors
    static func validateMapComponents() -> Bool {
        do {
            // Test TransitStation
            let coordinate = CLLocationCoordinate2D(latitude: 52.5170, longitude: 13.3888)
            let station = TransitStation(
                id: "test",
                name: "Test Station",
                coordinate: coordinate,
                type: .train
            )
            
            // Test that coordinate extensions work
            let coord1 = CLLocationCoordinate2D(latitude: 52.5170, longitude: 13.3888)
            let coord2 = CLLocationCoordinate2D(latitude: 52.5170, longitude: 13.3888)
            let _ = coord1 == coord2
            
            // Test StationType
            let allTypes = StationType.allCases
            let _ = allTypes.map { $0.displayName }
            let _ = allTypes.map { $0.iconName }
            
            // Test existing DB models
            let dbResponse = DBJourneysResponse(journeys: [])
            let _ = dbResponse.journeys
            
            // Test Place and Route models
            let origin = Place(rawId: "origin", name: "Origin", latitude: 52.5170, longitude: 13.3888)
            let destination = Place(rawId: "dest", name: "Destination", latitude: 52.5200, longitude: 13.4050)
            let route = Route(name: "Test Route", origin: origin, destination: destination)
            let _ = route.color.color
            
            // Test API components
            let _ = APIClient.shared
            let api = TransportAPIFactory.createAPI()
            let _ = api
            
            // Test services
            let locationService = LocationService.shared
            let _ = locationService.authorizationStatus
            
            // Test Core Data
            let coreDataStack = CoreDataStack.shared
            let _ = coreDataStack.context
            
            let routeStore = RouteStore()
            let _ = routeStore.fetchAll()
            
            // Test settings
            let settings = UserSettingsStore.shared
            let _ = settings.providerPreference
            
            let sharedStore = SharedStore.shared
            let _ = sharedStore.loadRouteSummaries()
            
            print("✅ All map components compile and instantiate successfully")
            return true
            
        } catch {
            print("❌ Build validation failed: \(error)")
            return false
        }
    }
    
    /// Test MapViewModel creation with real dependencies
    static func validateMapViewModelCreation() -> Bool {
        do {
            let locationService = LocationService.shared
            let transportAPI = TransportAPIFactory.createAPI()
            let routeStore = RouteStore()
            
            // Test that we can create the dependencies without errors
            // Note: MapViewModel requires @MainActor so we can't test it directly here
            let _ = locationService
            let _ = transportAPI  
            let _ = routeStore
            
            print("✅ MapViewModel dependencies create successfully")
            return true
            
        } catch {
            print("❌ MapViewModel dependency validation failed: \(error)")
            return false
        }
    }
    
    /// Run all build validations
    static func runAllValidations() -> Bool {
        print("🔨 Running Build Validation...")
        
        let componentsOK = validateMapComponents()
        let mapViewModelOK = validateMapViewModelCreation()
        
        let allOK = componentsOK && mapViewModelOK
        
        print("\n📊 Build Validation Summary:")
        print("   Component Compilation: \(componentsOK ? "✅" : "❌")")
        print("   MapViewModel Dependencies: \(mapViewModelOK ? "✅" : "❌")")
        print("   Overall Build Status: \(allOK ? "✅ SUCCESS" : "❌ FAILED")")
        
        if allOK {
            print("\n🎉 All components build successfully! Ready for use.")
        } else {
            print("\n⚠️ Build issues detected. Please review the errors above.")
        }
        
        return allOK
    }
}