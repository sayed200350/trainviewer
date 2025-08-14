import Foundation
import CoreLocation

final class LiveTransitAPI: TransitAPI {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL = URL(string: "https://v6.db.transport.rest")!) {
        self.session = session
        self.baseURL = baseURL
    }

    struct JourneyResponse: Decodable {
        let journeys: [Journey]
    }

    struct Journey: Decodable {
        let legs: [Leg]
    }

    struct Leg: Decodable {
        let origin: Stop
        let destination: Stop
        let departure: String?
        let arrival: String?
        let plannedDeparture: String?
        let plannedArrival: String?
        let departurePlatform: String?
        let arrivalPlatform: String?
        let departureDelay: Int?
    }

    struct Stop: Decodable {
        let name: String?
        let location: Location?
    }

    struct Location: Decodable {
        let latitude: Double?
        let longitude: Double?
    }

    func fetchNextDepartures(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        limit: Int
    ) async throws -> [Departure] {
        // Using transport.rest (German public transport) journeys
        // https://v6.transport.rest/api.html#journeys
        var components = URLComponents(url: baseURL.appendingPathComponent("/journeys"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            .init(name: "from.latitude", value: String(origin.latitude)),
            .init(name: "from.longitude", value: String(origin.longitude)),
            .init(name: "to.latitude", value: String(destination.latitude)),
            .init(name: "to.longitude", value: String(destination.longitude)),
            .init(name: "results", value: String(max(limit, 1))),
            .init(name: "arrival", value: "false")
        ]
        guard let url = components.url else { return [] }
        var departures: [Departure] = []
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let journeys = try decoder.decode(JourneyResponse.self, from: data).journeys
            let fmt = ISO8601DateFormatter()
            fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            for j in journeys {
                guard let first = j.legs.first else { continue }
                let originName = first.origin.name ?? "Origin"
                let destName = first.destination.name ?? "Destination"
                let depISO = first.departure ?? first.plannedDeparture
                let arrISO = first.arrival ?? first.plannedArrival
                guard let depStr = depISO, let arrStr = arrISO else { continue }
                let dep = fmt.date(from: depStr) ?? Date()
                let arr = fmt.date(from: arrStr) ?? dep.addingTimeInterval(30 * 60)
                let d = Departure(
                    id: UUID(),
                    origin: originName,
                    destination: destName,
                    departureTime: dep,
                    arrivalTime: arr,
                    platform: first.departurePlatform,
                    delayMinutes: first.departureDelay
                )
                departures.append(d)
            }
        } catch {
            // network failure; fall through to fallback
        }
        if departures.isEmpty {
            // Fallback to stub-like response if API returns nothing
            return try await StubTransitAPI().fetchNextDepartures(
                origin: origin,
                destination: destination,
                limit: limit
            )
        }
        return departures
    }
}


