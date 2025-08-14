import Foundation
import CoreData

@objc(UserEntity)
public class UserEntity: NSManagedObject {}

extension UserEntity: Identifiable {}

extension UserEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        NSFetchRequest<UserEntity>(entityName: "User")
    }

    @NSManaged public var id: String
    @NSManaged public var email: String?
    @NSManaged public var preferencesJSON: String?
    @NSManaged public var routes: NSSet?
    @NSManaged public var ticket: TicketEntity?
}

// MARK: Generated accessors for routes
extension UserEntity {
    @objc(addRoutesObject:)
    @NSManaged public func addToRoutes(_ value: RouteEntity)

    @objc(removeRoutesObject:)
    @NSManaged public func removeFromRoutes(_ value: RouteEntity)

    @objc(addRoutes:)
    @NSManaged public func addToRoutes(_ values: NSSet)

    @objc(removeRoutes:)
    @NSManaged public func removeFromRoutes(_ values: NSSet)
}


