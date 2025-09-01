import Foundation

public final class SharedStore {
    public static let shared = SharedStore()
    private init() {
        print("🔧 SHARED: SharedStore initialized")
        print("🔧 SHARED: App Group Identifier: \(AppConstants.appGroupIdentifier)")
        checkAppGroupAccess()
    }

    private func checkAppGroupAccess() {
        #if !APP_EXTENSION
        print("🔧 SHARED: Checking app group access (Main App)...")
        #else
        print("🔧 SHARED: Checking app group access (Widget Extension)...")
        #endif

        if defaults == nil {
            print("❌ SHARED: App group access FAILED - Check Xcode configuration")
            print("🔧 SHARED: Make sure both targets have the same App Group entitlement")
        } else {
            print("✅ SHARED: App group access SUCCESS")
        }
    }

    private let snapshotKey = "widget_main_snapshot"
    private let perRoutePrefix = "widget_snapshot."
    private let routeSummariesKey = "route_summaries"
    private let campusKey = "settings.campusPlace"
    private let homeKey = "settings.homePlace"
    private let lastLocationLatKey = "lastLocation.lat"
    private let lastLocationLonKey = "lastLocation.lon"
    private let pendingRouteKey = "pending.routeId"

    private var defaults: UserDefaults? {
        let suiteName = AppConstants.appGroupIdentifier
        print("🔧 SHARED: Initializing UserDefaults with suite: \(suiteName)")

        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("❌ SHARED: Failed to create UserDefaults with suite: \(suiteName)")
            print("🔧 SHARED: Available app groups might be misconfigured")
            print("🔧 SHARED: Make sure:")
            print("🔧 SHARED: 1. Both targets have App Groups entitlement")
            print("🔧 SHARED: 2. App Group ID matches: 'group.com.trainviewer'")
            print("🔧 SHARED: 3. You're running on PHYSICAL DEVICE (widgets don't work on simulator)")
            print("🔧 SHARED: 4. App is signed with correct provisioning profile")
            return nil
        }

        print("✅ SHARED: Successfully created UserDefaults with suite: \(suiteName)")
        return defaults
    }

    public func save(snapshot: WidgetSnapshot) {
        print("🔧 SHARED: Saving widget snapshot - Route: \(snapshot.routeName), Leave in: \(snapshot.leaveInMinutes)min")
        guard let data = try? JSONEncoder().encode(snapshot) else {
            print("❌ SHARED: Failed to encode snapshot")
            return
        }
        defaults?.set(data, forKey: snapshotKey)
        // Also save per-route
        defaults?.set(data, forKey: perRoutePrefix + snapshot.routeId.uuidString)
        print("✅ SHARED: Widget snapshot saved successfully")
    }

    public func save(snapshot: WidgetSnapshot, for routeId: UUID) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: perRoutePrefix + routeId.uuidString)
    }

    public func loadSnapshot() -> WidgetSnapshot? {
        print("🔧 SHARED: Loading widget snapshot...")
        guard let data = defaults?.data(forKey: snapshotKey) else {
            print("⚠️ SHARED: No snapshot data found in UserDefaults")
            return nil
        }
        guard let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            print("❌ SHARED: Failed to decode snapshot data")
            return nil
        }
        print("✅ SHARED: Successfully loaded snapshot - Route: \(snapshot.routeName), Leave in: \(snapshot.leaveInMinutes)min")
        return snapshot
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
        defaults?.set(latitude, forKey: lastLocationLatKey)
        defaults?.set(longitude, forKey: lastLocationLonKey)
    }

    public func loadLastLocation() -> (lat: Double, lon: Double)? {
        guard let lat = defaults?.object(forKey: lastLocationLatKey) as? Double, let lon = defaults?.object(forKey: lastLocationLonKey) as? Double else { return nil }
        return (lat, lon)
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