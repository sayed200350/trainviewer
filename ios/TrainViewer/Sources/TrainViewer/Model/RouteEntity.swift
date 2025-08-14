import Foundation
import CoreData
import CoreLocation

@objc(RouteEntity)
public class RouteEntity: NSManagedObject {}

extension RouteEntity: Identifiable {}

extension RouteEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RouteEntity> {
        NSFetchRequest<RouteEntity>(entityName: "Route")
    }

    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var originName: String
    @NSManaged public var originLatitude: Double
    @NSManaged public var originLongitude: Double
    @NSManaged public var originPlaceId: String?
    @NSManaged public var destName: String
    @NSManaged public var destLatitude: Double
    @NSManaged public var destLongitude: Double
    @NSManaged public var destPlaceId: String?
    @NSManaged public var walkBufferMins: Int16
    @NSManaged public var createdAt: Date
    @NSManaged public var user: UserEntity?

    public var originCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: originLatitude, longitude: originLongitude)
    }

    public var destCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: destLatitude, longitude: destLongitude)
    }

    static func create(
        in context: NSManagedObjectContext,
        name: String,
        originName: String,
        origin: CLLocationCoordinate2D,
        originPlaceId: String?,
        destName: String,
        dest: CLLocationCoordinate2D,
        destPlaceId: String?,
        walkBufferMins: Int = 2
    ) throws {
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
        try context.save()
    }
}

