import Foundation
import WidgetKit

struct SharedCache {
    static let suiteName = "group.com.trainviewer"
    private static let routesKey = "routesList"
    private static let lastUsedRouteKey = "lastUsedRouteId"
    private static let departuresKeyPrefix = "departures_" // followed by routeId

    struct RouteSummary: Codable, Identifiable, Equatable {
        let id: String
        let name: String
        let originName: String
        let destName: String
    }

    struct WidgetDeparturePayload: Codable {
        let routeId: String
        let routeName: String
        let firstDeparture: Date
        let firstArrival: Date
        let platform: String?
        let walkBufferMins: Int
        let updatedAt: Date
    }

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static func saveRoutes(_ routes: [RouteSummary]) {
        guard let defaults else { return }
        do {
            let data = try JSONEncoder().encode(routes)
            defaults.set(data, forKey: routesKey)
            WidgetCenter.shared.reloadTimelines(ofKind: "NextDepartureWidget")
        } catch {
            // ignore encoding errors in cache
        }
    }

    static func saveRoutes(from entities: [RouteEntity]) {
        let routes = entities.map { e in
            RouteSummary(id: e.id, name: e.name, originName: e.originName, destName: e.destName)
        }
        saveRoutes(routes)
    }

    static func setLastUsedRouteId(_ id: String) {
        guard let defaults else { return }
        defaults.set(id, forKey: lastUsedRouteKey)
        WidgetCenter.shared.reloadTimelines(ofKind: "NextDepartureWidget")
    }

    static func updateDepartures(for route: RouteEntity, departures: [Departure]) {
        guard let defaults else { return }
        guard let first = departures.first else { return }
        let payload = WidgetDeparturePayload(
            routeId: route.id,
            routeName: route.name,
            firstDeparture: first.departureTime,
            firstArrival: first.arrivalTime,
            platform: first.platform,
            walkBufferMins: Int(route.walkBufferMins),
            updatedAt: Date()
        )
        do {
            let data = try JSONEncoder().encode(payload)
            defaults.set(data, forKey: departuresKeyPrefix + route.id)
            WidgetCenter.shared.reloadTimelines(ofKind: "NextDepartureWidget")
        } catch {
            // ignore encoding errors in cache
        }
    }
}


