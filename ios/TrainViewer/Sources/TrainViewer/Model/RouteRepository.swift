import Foundation
import CoreData
import CoreLocation

struct RouteRepository {
    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    func create(
        name: String,
        originName: String,
        origin: CLLocationCoordinate2D,
        originPlaceId: String?,
        destName: String,
        dest: CLLocationCoordinate2D,
        destPlaceId: String?,
        walkBufferMins: Int = 2,
        user: UserEntity? = nil
    ) throws {
        let context = persistence.viewContext
        let route = RouteEntity(context: context)
        route.id = UUID().uuidString
        route.name = name
        route.originName = originName
        route.originLatitude = origin.latitude
        route.originLongitude = origin.longitude
        route.originPlaceId = originPlaceId
        route.destName = destName
        route.destLatitude = dest.latitude
        route.destLongitude = dest.longitude
        route.destPlaceId = destPlaceId
        route.walkBufferMins = Int16(walkBufferMins)
        route.createdAt = Date()
        route.user = user
        try context.save()
    }

    func fetchAll() throws -> [RouteEntity] {
        let request: NSFetchRequest<RouteEntity> = RouteEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(RouteEntity.createdAt), ascending: false)]
        return try persistence.viewContext.fetch(request)
    }

    func delete(_ route: RouteEntity) throws {
        let context = persistence.viewContext
        context.delete(route)
        try context.save()
    }

    func saveChanges() throws {
        try persistence.viewContext.save()
    }
}


