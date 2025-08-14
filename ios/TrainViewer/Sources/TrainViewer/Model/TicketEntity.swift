import Foundation
import CoreData

@objc(TicketEntity)
public class TicketEntity: NSManagedObject {}

extension TicketEntity: Identifiable {}

extension TicketEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TicketEntity> {
        NSFetchRequest<TicketEntity>(entityName: "Ticket")
    }

    @NSManaged public var id: String
    @NSManaged public var type: String
    @NSManaged public var zones: String?
    @NSManaged public var expiry: Date?
    @NSManaged public var imageRef: String?
    @NSManaged public var user: UserEntity?
}


