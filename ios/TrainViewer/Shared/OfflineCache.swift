import Foundation

final class OfflineCache {
    static let shared = OfflineCache()
    private init() {}

    private let defaults = UserDefaults.standard

    func save(routeId: UUID, options: [JourneyOption]) {
        let key = cacheKey(for: routeId)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(options) {
            defaults.set(data, forKey: key)
        }
    }

    func load(routeId: UUID) -> [JourneyOption]? {
        let key = cacheKey(for: routeId)
        guard let data = defaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode([JourneyOption].self, from: data)
    }

    func delete(routeId: UUID) {
        let key = cacheKey(for: routeId)
        defaults.removeObject(forKey: key)
    }

    func clearAll(routeIds: [UUID]) {
        routeIds.forEach { delete(routeId: $0) }
    }

    private func cacheKey(for id: UUID) -> String { "cache.journeys." + id.uuidString }
}