import Foundation

public final class SharedStore {
    public static let shared = SharedStore()
    private init() {}

    private let snapshotKey = "widget_main_snapshot"
    private let perRoutePrefix = "widget_snapshot."
    private let routeSummariesKey = "route_summaries"

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
}