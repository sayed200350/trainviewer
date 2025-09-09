import Foundation
import CoreData

final class RouteStore {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
    }

    func fetchAll() -> [Route] {
        let request = NSFetchRequest<RouteEntity>(entityName: "RouteEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toModel() }
        } catch {
            return []
        }
    }

    func add(route: Route) {
        let entity = RouteEntity(context: context)
        entity.id = route.id
        entity.name = route.name

        entity.originId = route.origin.rawId
        entity.originName = route.origin.name
        if let lat = route.origin.latitude { entity.originLat = NSNumber(value: lat) }
        if let lon = route.origin.longitude { entity.originLon = NSNumber(value: lon) }

        entity.destId = route.destination.rawId
        entity.destName = route.destination.name
        if let lat = route.destination.latitude { entity.destLat = NSNumber(value: lat) }
        if let lon = route.destination.longitude { entity.destLon = NSNumber(value: lon) }

        entity.preparationBufferMinutes = Int16(route.preparationBufferMinutes)
        entity.walkingSpeedMetersPerSecond = route.walkingSpeedMetersPerSecond
        
        // New MVP properties
        entity.isWidgetEnabled = route.isWidgetEnabled
        entity.widgetPriority = Int16(route.widgetPriority)
        entity.colorRawValue = route.color.rawValue
        entity.isFavorite = route.isFavorite
        entity.createdAt = route.createdAt
        entity.lastUsed = route.lastUsed
        
        // Enhanced properties for task 4
        entity.customRefreshIntervalRaw = Int16(route.customRefreshInterval.rawValue)
        entity.usageCount = Int32(route.usageCount)

        CoreDataStack.shared.save()
    }

    func update(route: Route) {
        let request = NSFetchRequest<RouteEntity>(entityName: "RouteEntity")
        request.predicate = NSPredicate(format: "id == %@", route.id as CVarArg)
        if let entity = try? context.fetch(request).first {
            entity.name = route.name
            entity.originId = route.origin.rawId
            entity.originName = route.origin.name
            entity.originLat = route.origin.latitude.map { NSNumber(value: $0) }
            entity.originLon = route.origin.longitude.map { NSNumber(value: $0) }
            entity.destId = route.destination.rawId
            entity.destName = route.destination.name
            entity.destLat = route.destination.latitude.map { NSNumber(value: $0) }
            entity.destLon = route.destination.longitude.map { NSNumber(value: $0) }
            entity.preparationBufferMinutes = Int16(route.preparationBufferMinutes)
            entity.walkingSpeedMetersPerSecond = route.walkingSpeedMetersPerSecond
            
            // Update new MVP properties
            entity.isWidgetEnabled = route.isWidgetEnabled
            entity.widgetPriority = Int16(route.widgetPriority)
            entity.colorRawValue = route.color.rawValue
            entity.isFavorite = route.isFavorite
            entity.createdAt = route.createdAt
            entity.lastUsed = route.lastUsed
            
            // Update enhanced properties for task 4
            entity.customRefreshIntervalRaw = Int16(route.customRefreshInterval.rawValue)
            entity.usageCount = Int32(route.usageCount)
            
            CoreDataStack.shared.save()
        }
    }

    func delete(routeId: UUID) {
        let request = NSFetchRequest<RouteEntity>(entityName: "RouteEntity")
        request.predicate = NSPredicate(format: "id == %@", routeId as CVarArg)
        if let entity = try? context.fetch(request).first {
            context.delete(entity)
            CoreDataStack.shared.save()
        }
    }
    
    func fetchFavorites() -> [Route] {
        let request = NSFetchRequest<RouteEntity>(entityName: "RouteEntity")
        request.predicate = NSPredicate(format: "isFavorite == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "lastUsed", ascending: false)]
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toModel() }
        } catch {
            return []
        }
    }
    
    func fetchWidgetEnabled() -> [Route] {
        let request = NSFetchRequest<RouteEntity>(entityName: "RouteEntity")
        request.predicate = NSPredicate(format: "isWidgetEnabled == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "widgetPriority", ascending: true)]
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toModel() }
        } catch {
            return []
        }
    }
    
    func markRouteAsUsed(routeId: UUID) {
        let request = NSFetchRequest<RouteEntity>(entityName: "RouteEntity")
        request.predicate = NSPredicate(format: "id == %@", routeId as CVarArg)
        if let entity = try? context.fetch(request).first {
            entity.lastUsed = Date()
            entity.usageCount += 1
            CoreDataStack.shared.save()
        }
    }
    
    func toggleFavorite(routeId: UUID) {
        let request = NSFetchRequest<RouteEntity>(entityName: "RouteEntity")
        request.predicate = NSPredicate(format: "id == %@", routeId as CVarArg)
        if let entity = try? context.fetch(request).first {
            entity.isFavorite.toggle()
            CoreDataStack.shared.save()
        }
    }
    
    func updateRefreshInterval(routeId: UUID, interval: RefreshInterval) {
        let request = NSFetchRequest<RouteEntity>(entityName: "RouteEntity")
        request.predicate = NSPredicate(format: "id == %@", routeId as CVarArg)
        if let entity = try? context.fetch(request).first {
            entity.customRefreshIntervalRaw = Int16(interval.rawValue)
            CoreDataStack.shared.save()
        }
    }
    
    func fetchRouteStatistics() -> [RouteStatistics] {
        let routes = fetchAll()
        return routes.map { route in
            RouteStatistics(
                routeId: route.id,
                usageCount: route.usageCount,
                usageFrequency: route.usageFrequency,
                lastUsed: route.lastUsed,
                createdAt: route.createdAt,
                averageDelayMinutes: nil, // Will be calculated from journey history in future tasks
                reliabilityScore: 1.0 // Will be calculated from journey history in future tasks
            )
        }
    }
    
    func fetchMostUsedRoutes(limit: Int = 5) -> [Route] {
        let request = NSFetchRequest<RouteEntity>(entityName: "RouteEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "usageCount", ascending: false)]
        request.fetchLimit = limit
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toModel() }
        } catch {
            return []
        }
    }
    
    func fetchRecentlyUsedRoutes(limit: Int = 5) -> [Route] {
        let request = NSFetchRequest<RouteEntity>(entityName: "RouteEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "lastUsed", ascending: false)]
        request.fetchLimit = limit
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toModel() }
        } catch {
            return []
        }
    }
}

extension RouteEntity {
    func toModel() -> Route? {
        let origin = Place(rawId: originId, name: originName, latitude: originLat?.doubleValue, longitude: originLon?.doubleValue)
        let dest = Place(rawId: destId, name: destName, latitude: destLat?.doubleValue, longitude: destLon?.doubleValue)
        
        // Handle color conversion with fallback
        let routeColor = RouteColor(rawValue: colorRawValue) ?? .blue
        
        return Route(
            id: id, 
            name: name, 
            origin: origin, 
            destination: dest, 
            preparationBufferMinutes: Int(preparationBufferMinutes), 
            walkingSpeedMetersPerSecond: walkingSpeedMetersPerSecond,
            isWidgetEnabled: isWidgetEnabled,
            widgetPriority: Int(widgetPriority),
            color: routeColor,
            isFavorite: isFavorite,
            createdAt: createdAt,
            lastUsed: lastUsed,
            customRefreshInterval: customRefreshInterval,
            usageCount: Int(usageCount)
        )
    }
}