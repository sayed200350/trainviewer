import Foundation
import CoreData

/// Simplified Journey History Service for basic functionality
final class SimpleJourneyHistoryService {
    static let shared = SimpleJourneyHistoryService()
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
    }
    
    /// Records a journey from a JourneyOption and Route
    func recordJourneyFromOption(_ option: JourneyOption, route: Route, wasSuccessful: Bool = true) async throws {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let entity = JourneyHistoryEntity(context: self.context)
                    entity.id = UUID()
                    entity.routeId = route.id
                    entity.routeName = route.name
                    entity.departureTime = option.departure
                    entity.arrivalTime = option.arrival
                    entity.actualDepartureTime = option.delayMinutes != nil ? option.departure.addingTimeInterval(TimeInterval((option.delayMinutes ?? 0) * 60)) : nil
                    entity.actualArrivalTime = option.delayMinutes != nil ? option.arrival.addingTimeInterval(TimeInterval((option.delayMinutes ?? 0) * 60)) : nil
                    entity.delayMinutes = Int16(option.delayMinutes ?? 0)
                    entity.wasSuccessful = wasSuccessful
                    entity.createdAt = Date()
                    
                    // Link to route if it exists
                    let routeRequest = NSFetchRequest<RouteEntity>(entityName: "RouteEntity")
                    routeRequest.predicate = NSPredicate(format: "id == %@", route.id as CVarArg)
                    if let routeEntity = try? self.context.fetch(routeRequest).first {
                        entity.route = routeEntity
                    }
                    
                    try self.context.save()
                    print("✅ [SimpleJourneyHistoryService] Recorded journey for route: \(route.name)")
                    continuation.resume()
                } catch {
                    print("❌ [SimpleJourneyHistoryService] Failed to record journey: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Clears all journey history
    func clearAllHistory() async throws {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request = NSFetchRequest<JourneyHistoryEntity>(entityName: "JourneyHistoryEntity")
                    let entries = try self.context.fetch(request)
                    
                    for entry in entries {
                        self.context.delete(entry)
                    }
                    
                    try self.context.save()
                    print("🧹 [SimpleJourneyHistoryService] Cleared all journey history (\(entries.count) entries)")
                    continuation.resume()
                } catch {
                    print("❌ [SimpleJourneyHistoryService] Failed to clear history: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}