import Foundation
import CoreData

// MARK: - JourneyHistoryEntity Extensions

extension JourneyHistoryEntity {
    func toModel() -> JourneyHistoryEntry {
        return JourneyHistoryEntry(
            id: id,
            routeId: routeId,
            routeName: routeName,
            departureTime: departureTime,
            arrivalTime: arrivalTime,
            actualDepartureTime: actualDepartureTime,
            actualArrivalTime: actualArrivalTime,
            delayMinutes: Int(delayMinutes),
            wasSuccessful: wasSuccessful,
            createdAt: createdAt
        )
    }
}