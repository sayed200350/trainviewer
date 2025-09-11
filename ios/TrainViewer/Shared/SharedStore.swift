import Foundation

public final class SharedStore {
    public static let shared = SharedStore()
    private init() {}

    private let snapshotKey = "widget_main_snapshot"
    private let perRoutePrefix = "widget_snapshot."
    private let routeSummariesKey = "route_summaries"
    private let widgetRouteKey = "widget.selectedRouteId"
    private let campusKey = "settings.campusPlace"
    private let homeKey = "settings.homePlace"
    private let lastLocationLatKey = "lastLocation.lat"
    private let lastLocationLonKey = "lastLocation.lon"
    private let lastLocationTimestampKey = "lastLocation.timestamp"
    private let pendingRouteKey = "pending.routeId"

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: AppConstants.appGroupIdentifier)
    }

    public func save(snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: snapshotKey)
        // Also save per-route
        defaults?.set(data, forKey: perRoutePrefix + snapshot.routeId.uuidString)
    }

    public func save(snapshot: WidgetSnapshot, for routeId: UUID) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: perRoutePrefix + routeId.uuidString)
    }

    public func loadSnapshot() -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    public func loadSnapshot(for routeId: UUID) -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: perRoutePrefix + routeId.uuidString) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    public func saveRouteSummaries(_ routes: [RouteSummary]) {
        guard let data = try? JSONEncoder().encode(routes) else { return }
        defaults?.set(data, forKey: routeSummariesKey)
    }

    public func loadRouteSummaries() -> [RouteSummary] {
        guard let data = defaults?.data(forKey: routeSummariesKey) else { return [] }
        return (try? JSONDecoder().decode([RouteSummary].self, from: data)) ?? []
    }

    // MARK: - Settings sharing
    public func saveSettings(campusPlace: Place?, homePlace: Place?) {
        let encoder = JSONEncoder()
        if let campus = campusPlace, let data = try? encoder.encode(campus) { defaults?.set(data, forKey: campusKey) } else { defaults?.removeObject(forKey: campusKey) }
        if let home = homePlace, let data = try? encoder.encode(home) { defaults?.set(data, forKey: homeKey) } else { defaults?.removeObject(forKey: homeKey) }
    }

    public func loadSettings() -> (campus: Place?, home: Place?) {
        let decoder = JSONDecoder()
        var campus: Place? = nil
        var home: Place? = nil
        if let data = defaults?.data(forKey: campusKey) { campus = try? decoder.decode(Place.self, from: data) }
        if let data = defaults?.data(forKey: homeKey) { home = try? decoder.decode(Place.self, from: data) }
        return (campus, home)
    }

    // MARK: - Last location
    public func saveLastLocation(latitude: Double, longitude: Double) {
        let now = Date()
        defaults?.set(latitude, forKey: lastLocationLatKey)
        defaults?.set(longitude, forKey: lastLocationLonKey)
        defaults?.set(now, forKey: lastLocationTimestampKey)
    }

    public func saveLocationForSmartWidget(latitude: Double, longitude: Double) {
        let now = Date()
        // Save to main app UserDefaults
        defaults?.set(latitude, forKey: "currentLocation.latitude")
        defaults?.set(longitude, forKey: "currentLocation.longitude")
        defaults?.set(now, forKey: "currentLocation.timestamp")

        // Also save the regular location
        saveLastLocation(latitude: latitude, longitude: longitude)
    }

    public func loadLastLocation() -> (lat: Double, lon: Double)? {
        guard let lat = defaults?.object(forKey: lastLocationLatKey) as? Double, let lon = defaults?.object(forKey: lastLocationLonKey) as? Double else { return nil }
        return (lat, lon)
    }

    // MARK: - Widget route selection
    public func saveWidgetRoute(id: UUID) {
        defaults?.set(id.uuidString, forKey: widgetRouteKey)
    }

    public func loadWidgetRoute() -> UUID? {
        guard let str = defaults?.string(forKey: widgetRouteKey), let id = UUID(uuidString: str) else { return nil }
        return id
    }

    // MARK: - Pending deep link
    public func savePendingRoute(id: UUID) {
        defaults?.set(id.uuidString, forKey: pendingRouteKey)
    }

    public func takePendingRoute() -> UUID? {
        guard let str = defaults?.string(forKey: pendingRouteKey), let id = UUID(uuidString: str) else { return nil }
        defaults?.removeObject(forKey: pendingRouteKey)
        return id
    }
}