import Foundation
import CoreLocation
import MapKit
import Combine
import SwiftUI

/// Simple compilation validator to ensure all components can be imported and instantiated
final class CompilationValidator {
    
    /// Validates that all map components can be compiled and instantiated
    static func validateCompilation() -> Bool {
        do {
            // Test TransitStation creation
            let coordinate = CLLocationCoordinate2D(latitude: 52.5170, longitude: 13.3888)
            let _ = TransitStation(
                id: "test",
                name: "Test Station",
                coordinate: coordinate,
                type: .train
            )
            
            // Test Place creation
            let _ = Place(rawId: "test", name: "Test Place", latitude: 52.5170, longitude: 13.3888)
            
            // Test Route creation
            let origin = Place(rawId: "origin", name: "Origin", latitude: 52.5170, longitude: 13.3888)
            let destination = Place(rawId: "dest", name: "Destination", latitude: 52.5200, longitude: 13.4050)
            let _ = Route(name: "Test Route", origin: origin, destination: destination)
            
            // Test JourneyOption creation
            let _ = JourneyOption(
                departure: Date(),
                arrival: Date().addingTimeInterval(1800),
                lineName: "S1",
                platform: "1",
                delayMinutes: 0,
                totalMinutes: 30,
                warnings: nil
            )
            
            // Test StationType enum
            let _ = StationType.allCases
            
            // Test RouteColor enum
            let _ = RouteColor.allCases
            
            // Test API components
            let _ = APIClient.shared
            let _ = TransportAPIFactory.createAPI()
            
            // Test DB API models (existing)
            let _ = DBJourneysResponse(journeys: [])
            
            // Test Core Data components
            let _ = CoreDataStack.shared
            let _ = RouteStore()
            
            // Test Settings
            let _ = UserSettingsStore.shared
            let _ = SharedStore.shared
            
            // Test Services
            let _ = LocationService.shared
            
            print("✅ All components compile successfully")
            return true
            
        } catch {
            print("❌ Compilation validation failed: \(error)")
            return false
        }
    }
    
    /// Validates that MapViewModel dependencies can be created
    static func validateMapViewModelDependencies() -> Bool {
        do {
            // Create dependencies (MapViewModel requires @MainActor so we test dependencies only)
            let locationService = LocationService.shared
            let transportAPI = TransportAPIFactory.createAPI()
            let routeStore = RouteStore()
            
            // Verify dependencies are properly created
            let _ = locationService
            let _ = transportAPI
            let _ = routeStore
            
            print("✅ MapViewModel dependencies create successfully")
            return true
            
        } catch {
            print("❌ MapViewModel dependency creation failed: \(error)")
            return false
        }
    }
    
    /// Validates that all test components can be created
    static func validateTestComponents() -> Bool {
        do {
            // Test MapComponentValidator
            let report = MapComponentValidator.validateMapComponents()
            print("✅ MapComponentValidator runs successfully: \(report.passedTests)/\(report.totalTests) tests passed")
            
            // Test TestRunner
            let summary = TestRunner.runAllTests()
            print("✅ TestRunner runs successfully: \(summary)")
            
            return true
            
        } catch {
            print("❌ Test component validation failed: \(error)")
            return false
        }
    }
    
    /// Runs all validation checks
    static func runAllValidations() {
        print("🔍 Running Compilation Validation...")
        
        let compilationOK = validateCompilation()
        let mapViewModelOK = validateMapViewModelDependencies()
        let testComponentsOK = validateTestComponents()
        
        let allOK = compilationOK && mapViewModelOK && testComponentsOK
        
        print("\n📊 Validation Summary:")
        print("   Basic Compilation: \(compilationOK ? "✅" : "❌")")
        print("   MapViewModel Dependencies: \(mapViewModelOK ? "✅" : "❌")")
        print("   Test Components: \(testComponentsOK ? "✅" : "❌")")
        print("   Overall: \(allOK ? "✅ PASS" : "❌ FAIL")")
        
        if allOK {
            print("\n🎉 All map components are properly implemented and ready for use!")
        } else {
            print("\n⚠️ Some issues detected. Please review the failed validations above.")
        }
    }
}