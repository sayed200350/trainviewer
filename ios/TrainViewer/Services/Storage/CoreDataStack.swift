import Foundation
import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    var context: NSManagedObjectContext { container.viewContext }

    init(inMemory: Bool = false) {
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
        
        // Perform migration for existing routes
        migrateExistingRoutesIfNeeded()
    }
    
    func migrateExistingRoutesIfNeeded() {
        let context = container.viewContext
        let request = NSFetchRequest<RouteEntity>(entityName: "RouteEntity")
        
        do {
            let routes = try context.fetch(request)
            var needsSave = false
            
            for route in routes {
                // Check if migration is needed (if new properties are not set)
                if route.colorRawValue.isEmpty {
                    route.colorRawValue = RouteColor.blue.rawValue
                    route.isWidgetEnabled = false
                    route.widgetPriority = 0
                    route.isFavorite = false
                    
                    // Set creation date to current date if not set
                    if route.createdAt == Date(timeIntervalSince1970: 0) {
                        route.createdAt = Date()
                    }
                    
                    // Set last used to creation date if not set
                    if route.lastUsed == Date(timeIntervalSince1970: 0) {
                        route.lastUsed = route.createdAt
                    }
                    
                    needsSave = true
                }
            }
            
            if needsSave {
                try context.save()
            }
        } catch {
            print("Migration failed: \(error)")
        }
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
        
        // New MVP attributes with default values
        let isWidgetEnabledAttr = addAttribute("isWidgetEnabled", type: .booleanAttributeType)
        isWidgetEnabledAttr.defaultValue = false
        
        let widgetPriorityAttr = addAttribute("widgetPriority", type: .integer16AttributeType)
        widgetPriorityAttr.defaultValue = 0
        
        let colorRawValueAttr = addAttribute("colorRawValue", type: .stringAttributeType)
        colorRawValueAttr.defaultValue = RouteColor.blue.rawValue
        
        let isFavoriteAttr = addAttribute("isFavorite", type: .booleanAttributeType)
        isFavoriteAttr.defaultValue = false
        
        let createdAtAttr = addAttribute("createdAt", type: .dateAttributeType)
        createdAtAttr.defaultValue = Date()
        
        let lastUsedAttr = addAttribute("lastUsed", type: .dateAttributeType)
        lastUsedAttr.defaultValue = Date()

        routeEntity.properties = [idAttr, nameAttr,
                                  originIdAttr, originNameAttr, originLatAttr, originLonAttr,
                                  destIdAttr, destNameAttr, destLatAttr, destLonAttr,
                                  bufferAttr, walkingAttr,
                                  isWidgetEnabledAttr, widgetPriorityAttr, colorRawValueAttr,
                                  isFavoriteAttr, createdAtAttr, lastUsedAttr]

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
    
    // New MVP properties
    @NSManaged var isWidgetEnabled: Bool
    @NSManaged var widgetPriority: Int16
    @NSManaged var colorRawValue: String
    @NSManaged var isFavorite: Bool
    @NSManaged var createdAt: Date
    @NSManaged var lastUsed: Date
}