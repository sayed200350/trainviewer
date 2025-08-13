import Foundation
import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    var context: NSManagedObjectContext { container.viewContext }

    private init(inMemory: Bool = false) {
        let model = CoreDataStack.makeModel()
        container = NSPersistentContainer(name: "TrainViewer", managedObjectModel: model)
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved Core Data error: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let routeEntity = NSEntityDescription()
        routeEntity.name = "RouteEntity"
        routeEntity.managedObjectClassName = NSStringFromClass(RouteEntity.self)

        func addAttribute(_ name: String, type: NSAttributeType, isOptional: Bool = false) -> NSAttributeDescription {
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.isOptional = isOptional
            return attr
        }

        let idAttr = addAttribute("id", type: .UUIDAttributeType)
        let nameAttr = addAttribute("name", type: .stringAttributeType)

        let originIdAttr = addAttribute("originId", type: .stringAttributeType, isOptional: true)
        let originNameAttr = addAttribute("originName", type: .stringAttributeType)
        let originLatAttr = addAttribute("originLat", type: .doubleAttributeType, isOptional: true)
        let originLonAttr = addAttribute("originLon", type: .doubleAttributeType, isOptional: true)

        let destIdAttr = addAttribute("destId", type: .stringAttributeType, isOptional: true)
        let destNameAttr = addAttribute("destName", type: .stringAttributeType)
        let destLatAttr = addAttribute("destLat", type: .doubleAttributeType, isOptional: true)
        let destLonAttr = addAttribute("destLon", type: .doubleAttributeType, isOptional: true)

        let bufferAttr = addAttribute("preparationBufferMinutes", type: .integer16AttributeType)
        let walkingAttr = addAttribute("walkingSpeedMetersPerSecond", type: .doubleAttributeType)

        routeEntity.properties = [idAttr, nameAttr,
                                  originIdAttr, originNameAttr, originLatAttr, originLonAttr,
                                  destIdAttr, destNameAttr, destLatAttr, destLonAttr,
                                  bufferAttr, walkingAttr]

        model.entities = [routeEntity]
        return model
    }

    func save() {
        if context.hasChanges {
            try? context.save()
        }
    }
}

@objc(RouteEntity)
final class RouteEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String

    @NSManaged var originId: String?
    @NSManaged var originName: String
    @NSManaged var originLat: NSNumber?
    @NSManaged var originLon: NSNumber?

    @NSManaged var destId: String?
    @NSManaged var destName: String
    @NSManaged var destLat: NSNumber?
    @NSManaged var destLon: NSNumber?

    @NSManaged var preparationBufferMinutes: Int16
    @NSManaged var walkingSpeedMetersPerSecond: Double
}