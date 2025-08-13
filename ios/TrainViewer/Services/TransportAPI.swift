import Foundation

protocol TransportAPI {
    func searchLocations(query: String, limit: Int) async throws -> [Place]
    func nextJourneyOptions(from: Place, to: Place, results: Int) async throws -> [JourneyOption]
}

enum TransportProvider {
    case db
    case vbb
}