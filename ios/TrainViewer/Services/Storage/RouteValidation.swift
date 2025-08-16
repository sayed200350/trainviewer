import Foundation
import SwiftUI

/// Utility class to validate Route model and Core Data operations
final class RouteValidation {
    
    static func validateRouteColorEnum() -> Bool {
        // Test all color cases exist
        guard RouteColor.allCases.count == 6 else { return false }
        
        // Test color values
        guard RouteColor.blue.color == .blue,
              RouteColor.green.color == .green,
              RouteColor.orange.color == .orange,
              RouteColor.red.color == .red,
              RouteColor.purple.color == .purple,
              RouteColor.pink.color == .pink else { return false }
        
        // Test display names
        guard RouteColor.blue.displayName == "Blue",
              RouteColor.green.displayName == "Green",
              RouteColor.orange.displayName == "Orange",
              RouteColor.red.displayName == "Red",
              RouteColor.purple.displayName == "Purple",
              RouteColor.pink.displayName == "Pink" else { return false }
        
        return true
    }
    
    static func validateRouteModel() -> Bool {
        let origin = Place(rawId: "origin1", name: "Origin Station", latitude: 52.5200, longitude: 13.4050)
        let destination = Place(rawId: "dest1", name: "Destination Station", latitude: 52.5170, longitude: 13.3888)
        
        // Test default initialization
        let route = Route(name: "Test Route", origin: origin, destination: destination)
        
        guard !route.isWidgetEnabled,
              route.widgetPriority == 0,
              route.color == .blue,
              !route.isFavorite,
              route.preparationBufferMinutes == AppConstants.defaultPreparationBufferMinutes,
              route.walkingSpeedMetersPerSecond == AppConstants.defaultWalkingSpeedMetersPerSecond else { return false }
        
        // Test custom initialization
        let customRoute = Route(
            name: "Custom Route",
            origin: origin,
            destination: destination,
            preparationBufferMinutes: 5,
            walkingSpeedMetersPerSecond: 1.2,
            isWidgetEnabled: true,
            widgetPriority: 2,
            color: .red,
            isFavorite: true
        )
        
        guard customRoute.isWidgetEnabled,
              customRoute.widgetPriority == 2,
              customRoute.color == .red,
              customRoute.isFavorite,
              customRoute.preparationBufferMinutes == 5,
              customRoute.walkingSpeedMetersPerSecond == 1.2 else { return false }
        
        return true
    }
    
    static func validateCoreDataOperations() -> Bool {
        let coreDataStack = CoreDataStack(inMemory: true)
        let routeStore = RouteStore(context: coreDataStack.context)
        
        let origin = Place(rawId: "origin1", name: "Origin Station", latitude: 52.5200, longitude: 13.4050)
        let destination = Place(rawId: "dest1", name: "Destination Station", latitude: 52.5170, longitude: 13.3888)
        
        // Test adding a route
        let route = Route(
            name: "Test Route",
            origin: origin,
            destination: destination,
            isWidgetEnabled: true,
            widgetPriority: 1,
            color: .red,
            isFavorite: true
        )
        
        routeStore.add(route: route)
        
        let fetchedRoutes = routeStore.fetchAll()
        guard fetchedRoutes.count == 1 else { return false }
        
        let fetchedRoute = fetchedRoutes.first!
        guard fetchedRoute.id == route.id,
              fetchedRoute.name == route.name,
              fetchedRoute.isWidgetEnabled == route.isWidgetEnabled,
              fetchedRoute.widgetPriority == route.widgetPriority,
              fetchedRoute.color == route.color,
              fetchedRoute.isFavorite == route.isFavorite else { return false }
        
        // Test favorites
        let favorites = routeStore.fetchFavorites()
        guard favorites.count == 1,
              favorites.first?.name == "Test Route" else { return false }
        
        // Test widget enabled routes
        let widgetRoutes = routeStore.fetchWidgetEnabled()
        guard widgetRoutes.count == 1,
              widgetRoutes.first?.name == "Test Route" else { return false }
        
        // Test mark as used
        let originalLastUsed = fetchedRoute.lastUsed
        Thread.sleep(forTimeInterval: 0.01)
        routeStore.markRouteAsUsed(routeId: route.id)
        
        let updatedRoute = routeStore.fetchAll().first!
        guard updatedRoute.lastUsed > originalLastUsed else { return false }
        
        return true
    }
    
    static func validateRouteEntityConversion() -> Bool {
        let coreDataStack = CoreDataStack(inMemory: true)
        let context = coreDataStack.context
        let entity = RouteEntity(context: context)
        
        let routeId = UUID()
        entity.id = routeId
        entity.name = "Test Route"
        entity.originId = "origin1"
        entity.originName = "Origin Station"
        entity.originLat = NSNumber(value: 52.5200)
        entity.originLon = NSNumber(value: 13.4050)
        entity.destId = "dest1"
        entity.destName = "Destination Station"
        entity.destLat = NSNumber(value: 52.5170)
        entity.destLon = NSNumber(value: 13.3888)
        entity.preparationBufferMinutes = 5
        entity.walkingSpeedMetersPerSecond = 1.4
        entity.isWidgetEnabled = true
        entity.widgetPriority = 2
        entity.colorRawValue = RouteColor.green.rawValue
        entity.isFavorite = true
        entity.createdAt = Date()
        entity.lastUsed = Date()
        
        guard let route = entity.toModel() else { return false }
        
        guard route.id == routeId,
              route.name == "Test Route",
              route.origin.name == "Origin Station",
              route.destination.name == "Destination Station",
              route.preparationBufferMinutes == 5,
              route.walkingSpeedMetersPerSecond == 1.4,
              route.isWidgetEnabled,
              route.widgetPriority == 2,
              route.color == .green,
              route.isFavorite else { return false }
        
        // Test invalid color fallback
        entity.colorRawValue = "invalid_color"
        guard let routeWithInvalidColor = entity.toModel(),
              routeWithInvalidColor.color == .blue else { return false }
        
        return true
    }
    
    static func runAllValidations() -> (success: Bool, results: [String: Bool]) {
        let results: [String: Bool] = [
            "RouteColor Enum": validateRouteColorEnum(),
            "Route Model": validateRouteModel(),
            "Core Data Operations": validateCoreDataOperations(),
            "Route Entity Conversion": validateRouteEntityConversion()
        ]
        
        let success = results.values.allSatisfy { $0 }
        return (success, results)
    }
}

// MARK: - Debug Helper
extension RouteValidation {
    static func printValidationResults() {
        let (success, results) = runAllValidations()
        
        print("=== Route Model Validation Results ===")
        for (test, passed) in results {
            print("\(test): \(passed ? "✅ PASSED" : "❌ FAILED")")
        }
        print("Overall: \(success ? "✅ ALL TESTS PASSED" : "❌ SOME TESTS FAILED")")
        print("=====================================")
    }
}