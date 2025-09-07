import Foundation
import CoreData

// Compilation test for Route model enhancements
final class RouteEnhancementCompilationTest {
    
    func testRouteModelCompilation() {
        let place1 = Place(rawId: "test1", name: "Test 1", latitude: 52.5200, longitude: 13.4050)
        let place2 = Place(rawId: "test2", name: "Test 2", latitude: 52.5170, longitude: 13.3888)
        
        // Test Route initialization with new properties
        var route = Route(
            name: "Test Route",
            origin: place1,
            destination: place2,
            customRefreshInterval: .fiveMinutes,
            usageCount: 0
        )
        
        // Test new methods
        route.markAsUsed()
        route.toggleFavorite()
        route.updateRefreshInterval(.tenMinutes)
        
        // Test computed properties
        let _ = route.usageFrequency
        
        // Test RefreshInterval enum
        let interval = RefreshInterval.oneMinute
        let _ = interval.displayName
        let _ = interval.timeInterval
        
        // Test UsageFrequency enum
        let frequency = UsageFrequency.daily
        let _ = frequency.displayName
        let _ = frequency.sortOrder
        
        // Test RouteStatistics
        let statistics = RouteStatistics(
            routeId: route.id,
            usageCount: route.usageCount,
            usageFrequency: route.usageFrequency,
            lastUsed: route.lastUsed,
            createdAt: route.createdAt
        )
        let _ = statistics.reliabilityScore
        
        print("✅ Route model enhancements compile successfully")
    }
    
    func testRouteStoreCompilation() {
        let coreDataStack = CoreDataStack(inMemory: true)
        let store = RouteStore(context: coreDataStack.context)
        
        let place1 = Place(rawId: "test1", name: "Test 1", latitude: 52.5200, longitude: 13.4050)
        let place2 = Place(rawId: "test2", name: "Test 2", latitude: 52.5170, longitude: 13.3888)
        let route = Route(name: "Test", origin: place1, destination: place2)
        
        // Test new RouteStore methods
        store.toggleFavorite(routeId: route.id)
        store.updateRefreshInterval(routeId: route.id, interval: .fiveMinutes)
        let _ = store.fetchRouteStatistics()
        let _ = store.fetchMostUsedRoutes()
        let _ = store.fetchRecentlyUsedRoutes()
        
        print("✅ RouteStore enhancements compile successfully")
    }
    
    func testCoreDataEnhancementsCompilation() {
        let coreDataStack = CoreDataStack(inMemory: true)
        let context = coreDataStack.context
        
        let entity = RouteEntity(context: context)
        
        // Test new Core Data properties
        entity.customRefreshIntervalRaw = Int16(RefreshInterval.fiveMinutes.rawValue)
        entity.usageCount = 5
        
        // Test computed property
        entity.customRefreshInterval = .tenMinutes
        let _ = entity.customRefreshInterval
        
        print("✅ Core Data enhancements compile successfully")
    }
    
    static func runAllTests() {
        let test = RouteEnhancementCompilationTest()
        test.testRouteModelCompilation()
        test.testRouteStoreCompilation()
        test.testCoreDataEnhancementsCompilation()
        print("🎉 All Route enhancement compilation tests passed!")
    }
}