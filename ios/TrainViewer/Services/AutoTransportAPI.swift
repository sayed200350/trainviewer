import Foundation

final class AutoTransportAPI: TransportAPI {
    private let primary: TransportAPI
    private let fallback: TransportAPI

    init(primary: TransportAPI, fallback: TransportAPI) {
        self.primary = primary
        self.fallback = fallback
    }

    func searchLocations(query: String, limit: Int) async throws -> [Place] {
        do { return try await primary.searchLocations(query: query, limit: limit) }
        catch { return try await fallback.searchLocations(query: query, limit: limit) }
    }

    func nextJourneyOptions(from: Place, to: Place, results: Int) async throws -> [JourneyOption] {
        do { return try await primary.nextJourneyOptions(from: from, to: to, results: results) }
        catch { return try await fallback.nextJourneyOptions(from: from, to: to, results: results) }
    }
    
    func refreshJourney(refreshToken: String) async throws -> JourneyOption? {
        do { return try await primary.refreshJourney(refreshToken: refreshToken) }
        catch { return try await fallback.refreshJourney(refreshToken: refreshToken) }
    }
}