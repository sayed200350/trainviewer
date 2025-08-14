import Foundation
import CoreLocation

struct Departure: Identifiable, Codable, Equatable {
    let id: UUID
    let origin: String
    let destination: String
    let departureTime: Date
    let arrivalTime: Date
    let platform: String?
    let delayMinutes: Int?
}

protocol TransitAPI {
    func fetchNextDepartures(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        limit: Int
    ) async throws -> [Departure]
}

final class StubTransitAPI: TransitAPI {
    func fetchNextDepartures(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        limit: Int
    ) async throws -> [Departure] {
        // Simulate network latency
        try await Task.sleep(nanoseconds: 400_000_000)
        let now = Date()
        return (0..<max(limit, 1)).map { idx in
            let depart = Calendar.current.date(byAdding: .minute, value: 8 + idx * 12, to: now) ?? now
            let arrive = Calendar.current.date(byAdding: .minute, value: 37 + idx * 12, to: now) ?? now
            return Departure(
                id: UUID(),
                origin: "Origin",
                destination: "Destination",
                departureTime: depart,
                arrivalTime: arrive,
                platform: ["1", "2", "3"].randomElement(),
                delayMinutes: [0, 2, 5, nil].randomElement() ?? nil
            )
        }
    }
}


