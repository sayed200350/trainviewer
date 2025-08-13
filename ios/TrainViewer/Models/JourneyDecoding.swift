import Foundation

struct DBJourneysResponse: Codable {
    let journeys: [DBJourney]
}

struct DBJourney: Codable {
    let legs: [DBLeg]
    let refreshToken: String?
}

struct DBLeg: Codable {
    let origin: DBStop
    let destination: DBStop
    let departure: Date?
    let plannedDeparture: Date?
    let departureDelay: Int?
    let arrival: Date?
    let plannedArrival: Date?
    let arrivalDelay: Int?
    let platform: String?
    let line: DBLine?

    // Alternative keys seen in transport.rest
    let departurePlatform: String?
    let arrivalPlatform: String?

    enum CodingKeys: String, CodingKey {
        case origin, destination, departure, plannedDeparture, departureDelay, arrival, plannedArrival, arrivalDelay, platform, line
        case departurePlatform, arrivalPlatform
    }
}

struct DBStop: Codable {
    let name: String?
    let id: String?
    let platform: String?

    enum CodingKeys: String, CodingKey { case name, id, platform }
}

struct DBLine: Codable {
    let name: String?
}

extension DBJourney {
    func toJourneyOption() -> JourneyOption? {
        guard let first = legs.first else { return nil }
        guard let last = legs.last else { return nil }
        let dep = first.departure ?? first.plannedDeparture
        let arr = last.arrival ?? last.plannedArrival
        guard let departure = dep, let arrival = arr else { return nil }
        let delay = (first.departureDelay ?? 0) / 60
        let platform = first.departurePlatform ?? first.origin.platform ?? first.platform ?? legs.compactMap { $0.departurePlatform ?? $0.origin.platform ?? $0.platform }.first
        let lineName = first.line?.name
        let total = Int(arrival.timeIntervalSince(departure) / 60.0)
        return JourneyOption(departure: departure, arrival: arrival, lineName: lineName, platform: platform, delayMinutes: delay, totalMinutes: total)
    }
}