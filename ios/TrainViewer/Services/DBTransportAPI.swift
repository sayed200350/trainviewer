import Foundation

final class DBTransportAPI: TransportAPI {
    private let client: APIClient
    private let provider: TransportProvider

    init(client: APIClient = .shared, provider: TransportProvider = .db) {
        self.client = client
        self.provider = provider
    }

    private var baseURL: URL {
        switch provider {
        case .db: return AppConstants.dbBaseURL
        case .vbb: return AppConstants.vbbBaseURL
        }
    }

    func searchLocations(query: String, limit: Int = 8) async throws -> [Place] {
        guard var components = URLComponents(url: baseURL.appendingPathComponent("locations"), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        guard let url = components.url else { throw APIError.invalidURL }
        let results: [DBPlace] = try await client.get(url, as: [DBPlace].self)
        return results.compactMap { place in
            guard let name = place.name else { return nil }
            return Place(rawId: place.id, name: name, latitude: place.location?.latitude, longitude: place.location?.longitude)
        }
    }

    func nextJourneyOptions(from: Place, to: Place, results: Int = AppConstants.defaultResultsCount) async throws -> [JourneyOption] {
        var components = URLComponents(url: baseURL.appendingPathComponent("journeys"), resolvingAgainstBaseURL: false)
        var items: [URLQueryItem] = [
            URLQueryItem(name: "results", value: String(results)),
            URLQueryItem(name: "stopovers", value: "false"),
            URLQueryItem(name: "remarks", value: "true"),
            URLQueryItem(name: "language", value: "en")
        ]
        // from
        if let id = from.rawId, !id.isEmpty {
            items.append(URLQueryItem(name: "from", value: id))
        } else if let lat = from.latitude, let lon = from.longitude {
            items.append(URLQueryItem(name: "from.latitude", value: String(lat)))
            items.append(URLQueryItem(name: "from.longitude", value: String(lon)))
        }
        // to
        if let id = to.rawId, !id.isEmpty {
            items.append(URLQueryItem(name: "to", value: id))
        } else if let lat = to.latitude, let lon = to.longitude {
            items.append(URLQueryItem(name: "to.latitude", value: String(lat)))
            items.append(URLQueryItem(name: "to.longitude", value: String(lon)))
        }
        components?.queryItems = items
        guard let url = components?.url else { throw APIError.invalidURL }
        let response = try await client.get(url, as: DBJourneysResponse.self)
        return response.journeys.compactMap { $0.toJourneyOption() }
    }
}