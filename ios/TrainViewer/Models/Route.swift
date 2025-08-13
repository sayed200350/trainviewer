import Foundation
import CoreLocation

struct Route: Identifiable, Hashable {
    let id: UUID
    var name: String

    var origin: Place
    var destination: Place

    var preparationBufferMinutes: Int
    var walkingSpeedMetersPerSecond: Double

    init(id: UUID = UUID(), name: String, origin: Place, destination: Place, preparationBufferMinutes: Int = AppConstants.defaultPreparationBufferMinutes, walkingSpeedMetersPerSecond: Double = AppConstants.defaultWalkingSpeedMetersPerSecond) {
        self.id = id
        self.name = name
        self.origin = origin
        self.destination = destination
        self.preparationBufferMinutes = preparationBufferMinutes
        self.walkingSpeedMetersPerSecond = walkingSpeedMetersPerSecond
    }
}

struct JourneyOption: Identifiable, Hashable {
    let id: UUID = UUID()
    let departure: Date
    let arrival: Date
    let lineName: String?
    let platform: String?
    let delayMinutes: Int?
    let totalMinutes: Int
}