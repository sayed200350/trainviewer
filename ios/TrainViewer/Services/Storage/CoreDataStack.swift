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
                
                // Migrate enhanced properties for task 4
                if route.customRefreshIntervalRaw == 0 && route.usageCount == 0 {
                    route.customRefreshIntervalRaw = Int16(RefreshInterval.fiveMinutes.rawValue)
                    route.usageCount = 0
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
        
        let journeyHistoryEntity = NSEntityDescription()
        journeyHistoryEntity.name = "JourneyHistoryEntity"
        journeyHistoryEntity.managedObjectClassName = NSStringFromClass(JourneyHistoryEntity.self)

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
        
        // Enhanced attributes for task 4
        let customRefreshIntervalAttr = addAttribute("customRefreshIntervalRaw", type: .integer16AttributeType)
        customRefreshIntervalAttr.defaultValue = RefreshInterval.fiveMinutes.rawValue
        
        let usageCountAttr = addAttribute("usageCount", type: .integer32AttributeType)
        usageCountAttr.defaultValue = 0

        routeEntity.properties = [idAttr, nameAttr,
                                  originIdAttr, originNameAttr, originLatAttr, originLonAttr,
                                  destIdAttr, destNameAttr, destLatAttr, destLonAttr,
                                  bufferAttr, walkingAttr,
                                  isWidgetEnabledAttr, widgetPriorityAttr, colorRawValueAttr,
                                  isFavoriteAttr, createdAtAttr, lastUsedAttr,
                                  customRefreshIntervalAttr, usageCountAttr]

        // Journey History Entity attributes
        let journeyIdAttr = addAttribute("id", type: .UUIDAttributeType)
        let journeyRouteIdAttr = addAttribute("routeId", type: .UUIDAttributeType)
        let journeyRouteNameAttr = addAttribute("routeName", type: .stringAttributeType)
        let journeyDepartureTimeAttr = addAttribute("departureTime", type: .dateAttributeType)
        let journeyArrivalTimeAttr = addAttribute("arrivalTime", type: .dateAttributeType)
        let journeyActualDepartureTimeAttr = addAttribute("actualDepartureTime", type: .dateAttributeType, isOptional: true)
        let journeyActualArrivalTimeAttr = addAttribute("actualArrivalTime", type: .dateAttributeType, isOptional: true)
        let journeyDelayMinutesAttr = addAttribute("delayMinutes", type: .integer16AttributeType)
        journeyDelayMinutesAttr.defaultValue = 0
        let journeyWasSuccessfulAttr = addAttribute("wasSuccessful", type: .booleanAttributeType)
        journeyWasSuccessfulAttr.defaultValue = true
        let journeyCreatedAtAttr = addAttribute("createdAt", type: .dateAttributeType)
        journeyCreatedAtAttr.defaultValue = Date()

        journeyHistoryEntity.properties = [journeyIdAttr, journeyRouteIdAttr, journeyRouteNameAttr,
                                          journeyDepartureTimeAttr, journeyArrivalTimeAttr,
                                          journeyActualDepartureTimeAttr, journeyActualArrivalTimeAttr,
                                          journeyDelayMinutesAttr, journeyWasSuccessfulAttr, journeyCreatedAtAttr]

        // Create relationship between Route and JourneyHistory
        let routeToHistoryRelationship = NSRelationshipDescription()
        routeToHistoryRelationship.name = "journeyHistory"
        routeToHistoryRelationship.destinationEntity = journeyHistoryEntity
        routeToHistoryRelationship.deleteRule = .cascadeDeleteRule
        routeToHistoryRelationship.minCount = 0
        routeToHistoryRelationship.maxCount = 0 // 0 means unlimited (to-many)
        
        let historyToRouteRelationship = NSRelationshipDescription()
        historyToRouteRelationship.name = "route"
        historyToRouteRelationship.destinationEntity = routeEntity
        historyToRouteRelationship.deleteRule = .nullifyDeleteRule
        historyToRouteRelationship.minCount = 0
        historyToRouteRelationship.maxCount = 1 // to-one relationship
        
        // Set inverse relationships
        routeToHistoryRelationship.inverseRelationship = historyToRouteRelationship
        historyToRouteRelationship.inverseRelationship = routeToHistoryRelationship
        
        // Add relationships to entities
        routeEntity.properties.append(routeToHistoryRelationship)
        journeyHistoryEntity.properties.append(historyToRouteRelationship)

        model.entities = [routeEntity, journeyHistoryEntity]
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
    
    // Enhanced properties for task 4
    @NSManaged var customRefreshIntervalRaw: Int16
    @NSManaged var usageCount: Int32
    
    // Relationship to JourneyHistoryEntity
    @NSManaged var journeyHistory: NSSet?
    
    var customRefreshInterval: RefreshInterval {
        get { RefreshInterval(rawValue: Int(customRefreshIntervalRaw)) ?? .fiveMinutes }
        set { customRefreshIntervalRaw = Int16(newValue.rawValue) }
    }
}

@objc(JourneyHistoryEntity)
final class JourneyHistoryEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var routeId: UUID
    @NSManaged var routeName: String
    @NSManaged var departureTime: Date
    @NSManaged var arrivalTime: Date
    @NSManaged var actualDepartureTime: Date?
    @NSManaged var actualArrivalTime: Date?
    @NSManaged var delayMinutes: Int16
    @NSManaged var wasSuccessful: Bool
    @NSManaged var createdAt: Date
    
    // Relationship to RouteEntity
    @NSManaged var route: RouteEntity?
    

}