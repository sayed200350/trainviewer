import Foundation
import CoreLocation
import WidgetKit

struct RouteStatus: Hashable {
    let options: [JourneyOption]
    let leaveInMinutes: Int?
    let lastUpdated: Date
}

struct ClassSuggestion: Hashable {
    let routeName: String
    let eventTitle: String
    let eventStart: Date
    let leaveInMinutes: Int
}

@MainActor
final class RoutesViewModel: ObservableObject {
    @Published private(set) var routes: [Route] = []
    @Published private(set) var statusByRouteId: [UUID: RouteStatus] = [:]
    @Published var isRefreshing: Bool = false
    @Published var nextClass: ClassSuggestion?
    @Published var isOffline: Bool = false
    
    // Enhanced properties for task 4
    @Published private(set) var favoriteRoutes: [Route] = []
    @Published private(set) var recentRoutes: [Route] = []
    @Published private(set) var routeStatistics: [UUID: RouteStatistics] = [:]
    @Published var isPerformanceOptimized: Bool = true

    private let store: RouteStore
    private let api: TransportAPI
    private let locationService: LocationService
    private let sharedStore: SharedStore
    private let settings: UserSettingsStore
    private let journeyHistoryService: SimpleJourneyHistoryService?

    init(store: RouteStore = RouteStore(), api: TransportAPI = TransportAPIFactory.shared.make(), locationService: LocationService = .shared, sharedStore: SharedStore = .shared, settings: UserSettingsStore = .shared, journeyHistoryService: SimpleJourneyHistoryService? = SimpleJourneyHistoryService.shared) {
        self.store = store
        self.api = api
        self.locationService = locationService
        self.sharedStore = sharedStore
        self.settings = settings
        self.journeyHistoryService = journeyHistoryService
    }

    func loadRoutes() {
        routes = store.fetchAll()
        loadFavoriteRoutes()
        loadRecentRoutes()
        loadRouteStatistics()
        publishRouteSummaries()
    }
    
    private func loadFavoriteRoutes() {
        favoriteRoutes = store.fetchFavorites()
    }
    
    private func loadRecentRoutes() {
        recentRoutes = store.fetchRecentlyUsedRoutes()
    }
    
    private func loadRouteStatistics() {
        let stats = store.fetchRouteStatistics()
        routeStatistics = Dictionary(uniqueKeysWithValues: stats.map { ($0.routeId, $0) })
    }

    func deleteRoute(at offsets: IndexSet) {
        for index in offsets { store.delete(routeId: routes[index].id) }
        loadRoutes()
    }
    
    // Enhanced methods for task 4
    func toggleFavorite(for route: Route) {
        store.toggleFavorite(routeId: route.id)
        loadRoutes()
    }
    
    func reorderFavorites(_ routes: [Route]) {
        // Update widget priorities based on new order
        for (index, route) in routes.enumerated() {
            var updatedRoute = route
            updatedRoute.widgetPriority = index
            store.update(route: updatedRoute)
        }
        loadRoutes()
    }
    
    func updateUsageStatistics(for route: Route) {
        store.markRouteAsUsed(routeId: route.id)
        loadRouteStatistics()
    }
    
    func updateRefreshInterval(for route: Route, interval: RefreshInterval) {
        store.updateRefreshInterval(routeId: route.id, interval: interval)
        loadRoutes()
    }
    
    func getOptimalRefreshInterval(for route: Route) -> RefreshInterval {
        // Get current usage frequency and suggest optimal refresh interval
        let frequency = route.usageFrequency
        
        switch frequency {
        case .daily:
            return .twoMinutes // More frequent for daily routes
        case .weekly:
            return .fiveMinutes // Standard for weekly routes
        case .monthly:
            return .tenMinutes // Less frequent for monthly routes
        case .rarely:
            return .fifteenMinutes // Least frequent for rarely used routes
        }
    }
    
    func batchUpdateRoutes(_ routes: [Route]) async {
        for route in routes {
            store.update(route: route)
        }
        await MainActor.run {
            loadRoutes()
        }
    }
    
    func getMostUsedRoutes(limit: Int = 5) -> [Route] {
        return store.fetchMostUsedRoutes(limit: limit)
    }
    
    func getRouteStatistics(for routeId: UUID) -> RouteStatistics? {
        return routeStatistics[routeId]
    }
    
    func suggestFavoriteRoutes() -> [Route] {
        // Suggest routes that are used frequently but not marked as favorites
        let frequentRoutes = routes.filter { route in
            !route.isFavorite && 
            (route.usageFrequency == .daily || route.usageFrequency == .weekly) &&
            route.usageCount >= 3
        }
        return Array(frequentRoutes.prefix(3))
    }
    
    /// Records a journey when a user selects a journey option
    func recordJourneySelection(_ option: JourneyOption, for route: Route) async {
        guard settings.journeyTrackingEnabled, let historyService = journeyHistoryService else { return }
        
        do {
            try await historyService.recordJourneyFromOption(option, route: route)
            print("✅ [RoutesViewModel] Recorded journey selection for route: \(route.name)")
        } catch {
            print("❌ [RoutesViewModel] Failed to record journey: \(error)")
        }
    }

    func refreshAll() async {
        print("🔄 [RoutesViewModel] Starting refreshAll for \(routes.count) routes")
        isRefreshing = true
        defer { isRefreshing = false }
        var usedCacheAny = false
        
        await withTaskGroup(of: (UUID, RouteStatus?, Bool).self) { group in
            for route in routes {
                print("🔄 [RoutesViewModel] Adding task for route: \(route.name)")
                group.addTask { [weak self] in
                    guard let self = self else { return (route.id, nil, false) }
                    
                    // Check if route should be refreshed based on adaptive logic
                    let shouldRefresh = await self.shouldRefreshRoute(route)
                    if !shouldRefresh {
                        print("⏭️ [RoutesViewModel] Skipping refresh for route: \(route.name) (not needed yet)")
                        // Return existing status if available
                        let existingStatus = await MainActor.run { self.statusByRouteId[route.id] }
                        return (route.id, existingStatus, false)
                    }
                    
                    print("🔄 [RoutesViewModel] Processing route: \(route.name)")
                    do {
                        let options = try await self.api.nextJourneyOptions(from: route.origin, to: route.destination, results: AppConstants.defaultResultsCount)
                        print("✅ [RoutesViewModel] Got \(options.count) options for route: \(route.name)")
                        
                        await MainActor.run {
                            self.cache(options: options, for: route)
                        }
                        let status = await MainActor.run {
                            self.computeStatus(for: route, options: options)
                        }
                        return (route.id, status, false)
                    } catch {
                        print("❌ [RoutesViewModel] API failed for route \(route.name): \(error)")
                        let cached = OfflineCache.shared.load(routeId: route.id) ?? []
                        print("📦 [RoutesViewModel] Using \(cached.count) cached options for route: \(route.name)")
                        
                        let status = await MainActor.run {
                            self.computeStatus(for: route, options: cached)
                        }
                        return (route.id, status, true)
                    }
                }
            }
            
            var newStatus: [UUID: RouteStatus] = [:]
            for await (id, status, usedCache) in group {
                if let status = status { 
                    newStatus[id] = status
                    print("✅ [RoutesViewModel] Status updated for route ID: \(id), leave in: \(status.leaveInMinutes ?? 0) minutes")
                }
                if usedCache { usedCacheAny = true }
            }
            
            await MainActor.run {
                statusByRouteId = newStatus
                isOffline = usedCacheAny
                print("🔄 [RoutesViewModel] Updated status for \(newStatus.count) routes, offline: \(usedCacheAny)")
                publishSnapshotIfAvailable()
                notifyIfDisruptions()
            }
            await refreshClassSuggestion()
        }
    }
    
    /// Check if a route should be refreshed based on adaptive refresh logic
    private func shouldRefreshRoute(_ route: Route) async -> Bool {
        let adaptiveService = AdaptiveRefreshService.shared
        
        // Get last refresh time for this route
        let lastRefresh = statusByRouteId[route.id]?.lastUpdated ?? Date.distantPast
        
        // Get next departure time if available
        let nextDeparture = statusByRouteId[route.id]?.options.first?.departure
        
        return adaptiveService.shouldRefreshRoute(route, lastRefresh: lastRefresh, nextDeparture: nextDeparture)
    }
    
    /// Refresh a specific route with adaptive timing
    func refreshRoute(_ route: Route) async {
        print("🔄 [RoutesViewModel] Refreshing specific route: \(route.name)")
        
        do {
            let options = try await api.nextJourneyOptions(from: route.origin, to: route.destination, results: AppConstants.defaultResultsCount)
            print("✅ [RoutesViewModel] Got \(options.count) options for route: \(route.name)")
            
            await MainActor.run {
                cache(options: options, for: route)
                let status = computeStatus(for: route, options: options)
                statusByRouteId[route.id] = status
                
                // Update usage statistics
                updateUsageStatistics(for: route)
                
                print("✅ [RoutesViewModel] Route \(route.name) refreshed successfully")
            }
        } catch {
            print("❌ [RoutesViewModel] Failed to refresh route \(route.name): \(error)")
            
            // Fall back to cached data
            let cached = OfflineCache.shared.load(routeId: route.id) ?? []
            await MainActor.run {
                let status = computeStatus(for: route, options: cached)
                statusByRouteId[route.id] = status
                isOffline = true
            }
        }
    }

    private func cache(options: [JourneyOption], for route: Route) {
        OfflineCache.shared.save(routeId: route.id, options: options)
    }

    private func publishRouteSummaries() {
        let summaries = routes.map { RouteSummary(id: $0.id, name: $0.name) }
        sharedStore.saveRouteSummaries(summaries)
    }

    private func publishSnapshotIfAvailable() {
        print("🔧 MAIN: Checking if snapshot should be published...")
        guard let firstRoute = routes.first, let status = statusByRouteId[firstRoute.id], let firstOption = status.options.first else {
            print("⚠️ MAIN: Cannot publish snapshot - missing route data")
            return
        }
        let leave = status.leaveInMinutes ?? 0
        let snapshot = WidgetSnapshot(routeId: firstRoute.id, routeName: firstRoute.name, leaveInMinutes: leave, departure: firstOption.departure, arrival: firstOption.arrival)
        print("🔧 MAIN: Publishing snapshot - Route: \(firstRoute.name), Leave in: \(leave)min")
        sharedStore.save(snapshot: snapshot)
        sharedStore.save(snapshot: snapshot, for: firstRoute.id)
        WidgetCenter.shared.reloadAllTimelines()
        print("✅ MAIN: Snapshot published and widget timelines reloaded")
    }

    func computeStatus(for route: Route, options: [JourneyOption]) -> RouteStatus {
        let now = Date()
        print("⏰ [RoutesViewModel] Computing status for route: \(route.name)")
        print("⏰ [RoutesViewModel] Current time: \(now)")
        print("⏰ [RoutesViewModel] Number of options: \(options.count)")
        
        var leaveIn: Int? = nil
        if let first = options.first {
            print("⏰ [RoutesViewModel] First departure: \(first.departure)")
            print("⏰ [RoutesViewModel] First arrival: \(first.arrival)")
            print("⏰ [RoutesViewModel] Line: \(first.lineName ?? "Unknown")")
            print("⏰ [RoutesViewModel] Platform: \(first.platform ?? "Unknown")")
            print("⏰ [RoutesViewModel] Delay: \(first.delayMinutes ?? 0) minutes")
            
            let walkingMinutes = computeWalkingMinutes(to: route.origin)
            let baseBuffer = route.preparationBufferMinutes
            let examExtra = settings.examModeEnabled ? 5 : 0
            let buffer = baseBuffer + examExtra
            let minutesUntilDeparture = Int(first.departure.timeIntervalSince(now) / 60)
            let minutesToLeave = minutesUntilDeparture - walkingMinutes - buffer
            leaveIn = max(0, minutesToLeave)
            
            print("⏰ [RoutesViewModel] Calculation breakdown:")
            print("⏰ [RoutesViewModel] - Walking time: \(walkingMinutes) minutes")
            print("⏰ [RoutesViewModel] - Base buffer: \(baseBuffer) minutes")
            print("⏰ [RoutesViewModel] - Exam extra: \(examExtra) minutes")
            print("⏰ [RoutesViewModel] - Total buffer: \(buffer) minutes")
            print("⏰ [RoutesViewModel] - Minutes until departure: \(minutesUntilDeparture)")
            print("⏰ [RoutesViewModel] - Minutes to leave: \(minutesToLeave)")
            print("⏰ [RoutesViewModel] - Final leave in: \(leaveIn ?? 0) minutes")
        } else {
            print("⚠️ [RoutesViewModel] No journey options available")
        }
        
        let status = RouteStatus(options: options, leaveInMinutes: leaveIn, lastUpdated: now)
        print("✅ [RoutesViewModel] Status computed - Leave in: \(leaveIn ?? 0) minutes")
        return status
    }

    private func computeWalkingMinutes(to place: Place) -> Int {
        print("🚶 [RoutesViewModel] Computing walking time to: \(place.name)")
        
        guard let dest = place.coordinate, let current = locationService.currentLocation else { 
            print("⚠️ [RoutesViewModel] Missing location data - dest: \(place.coordinate != nil), current: \(locationService.currentLocation != nil)")
            return 0 
        }
        
        let distance = current.distance(from: CLLocation(latitude: dest.latitude, longitude: dest.longitude))
        let speed = settings.nightModePreference ? AppConstants.defaultWalkingSpeedMetersPerSecond * 0.9 : AppConstants.defaultWalkingSpeedMetersPerSecond
        let seconds = distance / speed
        let minutes = Int(ceil(seconds / 60.0))
        
        print("🚶 [RoutesViewModel] Walking calculation:")
        print("🚶 [RoutesViewModel] - Current location: \(current.coordinate.latitude), \(current.coordinate.longitude)")
        print("🚶 [RoutesViewModel] - Destination: \(dest.latitude), \(dest.longitude)")
        print("🚶 [RoutesViewModel] - Distance: \(distance) meters")
        print("🚶 [RoutesViewModel] - Walking speed: \(speed) m/s (night mode: \(settings.nightModePreference))")
        print("🚶 [RoutesViewModel] - Walking time: \(seconds) seconds = \(minutes) minutes")
        
        return minutes
    }

    private func routeMatchingCampus() -> Route? {
        guard let campus = settings.campusPlace else { return nil }
        if let byName = routes.first(where: { $0.destination.name.localizedCaseInsensitiveContains(campus.name) }) { return byName }
        if let campusCoord = campus.coordinate {
            return routes.min(by: { lhs, rhs in
                let lhsD = distance(to: lhs.destination.coordinate, from: campusCoord)
                let rhsD = distance(to: rhs.destination.coordinate, from: campusCoord)
                return lhsD < rhsD
            })
        }
        return nil
    }

    private func distance(to coord: CLLocationCoordinate2D?, from other: CLLocationCoordinate2D) -> CLLocationDistance {
        guard let c = coord else { return .greatestFiniteMagnitude }
        let a = CLLocation(latitude: c.latitude, longitude: c.longitude)
        let b = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return a.distance(from: b)
    }

    private func notifyIfDisruptions() {
        for route in routes {
            guard let status = statusByRouteId[route.id] else { continue }
            if status.options.contains(where: { opt in
                let ws = (opt.warnings ?? [])
                return ws.contains(where: { w in
                    let s = w.lowercased()
                    return s.contains("streik") || s.contains("strike") || s.contains("cancel")
                })
            }) {
                Task { await NotificationService.shared.scheduleLeaveReminder(routeName: "Disruption: \(route.name)", leaveAt: Date().addingTimeInterval(2)) }
            }
        }
    }

    private func secondsOffset(bufferMinutes: Int) -> Int { bufferMinutes * 60 }

    private func computeLeaveForEvent(using option: JourneyOption, buffer: Int, eventStart: Date) -> Int {
        let arrivalLead = 5 * 60
        let timeToLeaveSec = option.departure.timeIntervalSince(Date())
        let extra = buffer + arrivalLead
        return max(0, Int(timeToLeaveSec / 60) - extra / 60)
    }

    private func findOptionArrivingBefore(_ options: [JourneyOption], eventStart: Date) -> JourneyOption? {
        let target = eventStart.addingTimeInterval(-5 * 60)
        return options.filter { $0.arrival <= target }.sorted { $0.arrival < $1.arrival }.last ?? options.first
    }

    private func bufferForRoute(_ route: Route) -> Int {
        let base = route.preparationBufferMinutes
        return base + (settings.examModeEnabled ? 5 : 0)
    }

    private func refreshClassSuggestion() async {
        guard let campus = settings.campusPlace, let route = routeMatchingCampus() else { nextClass = nil; return }
        guard let event = await EventKitService.shared.nextEvent(withinHours: 12, matchingCampus: campus) else { nextClass = nil; return }
        if let options = try? await api.nextJourneyOptions(from: route.origin, to: route.destination, results: 5), let selected = findOptionArrivingBefore(options, eventStart: event.startDate) {
            let buffer = bufferForRoute(route) * 60
            let leave = computeLeaveForEvent(using: selected, buffer: buffer, eventStart: event.startDate)
            nextClass = ClassSuggestion(routeName: route.name, eventTitle: event.title, eventStart: event.startDate, leaveInMinutes: leave)
        } else {
            nextClass = nil
        }
    }
}