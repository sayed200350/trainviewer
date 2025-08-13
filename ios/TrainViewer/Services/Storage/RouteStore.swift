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
}

extension RouteEntity {
    func toModel() -> Route? {
        let origin = Place(rawId: originId, name: originName, latitude: originLat?.doubleValue, longitude: originLon?.doubleValue)
        let dest = Place(rawId: destId, name: destName, latitude: destLat?.doubleValue, longitude: destLon?.doubleValue)
        return Route(id: id, name: name, origin: origin, destination: dest, preparationBufferMinutes: Int(preparationBufferMinutes), walkingSpeedMetersPerSecond: walkingSpeedMetersPerSecond)
    }
}