import Foundation
import CoreLocation
import WidgetKit
import SwiftUI
import ActivityKit

// MARK: - Shared Types
/// Achievement badge types for route usage milestones
public enum AchievementType: String, CaseIterable {
    case firstUse = "First Journey"
    case regularTraveler = "Regular Traveler"
    case loyalCommuter = "Loyal Commuter"
    case veteranExplorer = "Veteran Explorer"
    case milestoneMaster = "Milestone Master"

    public var iconName: String {
        switch self {
        case .firstUse: return "star.circle.fill"
        case .regularTraveler: return "figure.walk.circle.fill"
        case .loyalCommuter: return "crown.fill"
        case .veteranExplorer: return "medal.fill"
        case .milestoneMaster: return "trophy.fill"
        }
    }

    public var color: Color {
        switch self {
        case .firstUse: return .accentGreen
        case .regularTraveler: return .brandBlue
        case .loyalCommuter: return .accentOrange
        case .veteranExplorer: return .accentRed
        case .milestoneMaster: return .accentGreen
        }
    }

    public var description: String {
        switch self {
        case .firstUse: return "Your first journey with this route!"
        case .regularTraveler: return "Used this route 10 times"
        case .loyalCommuter: return "Used this route 50 times"
        case .veteranExplorer: return "Used this route 100 times"
        case .milestoneMaster: return "Used this route 250 times"
        }
    }

    public func isEarned(by route: Route) -> Bool {
        switch self {
        case .firstUse: return route.usageCount >= 1
        case .regularTraveler: return route.usageCount >= 10
        case .loyalCommuter: return route.usageCount >= 50
        case .veteranExplorer: return route.usageCount >= 100
        case .milestoneMaster: return route.usageCount >= 250
        }
    }
}

/// Personalized route recommendations based on user behavior
public struct RouteRecommendation: Identifiable {
    public let id = UUID()
    public let route: Route
    public let reason: String
    public let confidenceScore: Double // 0.0 to 1.0
    public let confidenceLevel: Int // 1 to 5 stars
    public let lastUsed: Date?
    public let recommendationType: RecommendationType

    public enum RecommendationType {
        case frequent
        case timeBased
        case patternBased
        case favorite
        case reliable
    }
}

public enum TimeOfDay: String, CaseIterable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case now = "Right Now"

    public var timeRange: (start: Int, end: Int) {
        switch self {
        case .morning: return (6, 12)
        case .afternoon: return (12, 18)
        case .evening: return (18, 24)
        case .now: return (Calendar.current.component(.hour, from: Date()), Calendar.current.component(.hour, from: Date()) + 1)
        }
    }

    public var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .now: return "clock.fill"
        }
    }
}

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
    @Published var achievementToCelebrate: AchievementType?
    @Published var showAchievementCelebration: Bool = false

    private let store: RouteStore
    private let api: TransportAPI
    private let locationService: LocationService
    private let sharedStore: SharedStore
    private let settings: UserSettingsStore
    private let journeyHistoryService: SimpleJourneyHistoryService?
    private let liveActivityService = LiveActivityService.shared

    // Track active Live Activities by route ID
    private var activeLiveActivities: [UUID: String] = [:]

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

    func deleteRouteByObject(_ route: Route) {
        store.delete(routeId: route.id)
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
        let oldUsageCount = route.usageCount
        store.markRouteAsUsed(routeId: route.id)
        loadRouteStatistics()

        // Check for new achievements
        checkForNewAchievements(routeId: route.id, oldUsageCount: oldUsageCount)
    }

    private func checkForNewAchievements(routeId: UUID, oldUsageCount: Int) {
        guard let route = routes.first(where: { $0.id == routeId }) else { return }

        // Find newly earned achievements
        for achievement in AchievementType.allCases {
            if !achievement.isEarned(by: Route(id: route.id, name: route.name, origin: route.origin, destination: route.destination, preparationBufferMinutes: route.preparationBufferMinutes, walkingSpeedMetersPerSecond: route.walkingSpeedMetersPerSecond, isWidgetEnabled: route.isWidgetEnabled, widgetPriority: route.widgetPriority, color: route.color, isFavorite: route.isFavorite, createdAt: route.createdAt, lastUsed: route.lastUsed, customRefreshInterval: route.customRefreshInterval, usageCount: oldUsageCount)) &&
               achievement.isEarned(by: route) {

                // Trigger celebration
                achievementToCelebrate = achievement
                showAchievementCelebration = true
                break // Only celebrate one achievement at a time
            }
        }
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

            // Manage Live Activities for upcoming departures (outside MainActor.run since it's async)
            await manageLiveActivities(for: newStatus)

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
        let summaries = routes.compactMap { route -> RouteSummary? in
            guard let destLat = route.destination.latitude,
                  let destLon = route.destination.longitude else { return nil }
            return RouteSummary(
                id: route.id,
                name: route.name,
                fromName: route.origin.name,
                toName: route.destination.name,
                toLat: destLat,
                toLon: destLon
            )
        }
        sharedStore.saveRouteSummaries(summaries)
    }

    private func publishSnapshotIfAvailable() {
        print("🔧 MAIN: Checking if snapshot should be published...")

        // Try to use selected widget route first, fallback to first route
        var selectedRoute: Route?

        if let widgetRouteId = sharedStore.loadWidgetRoute(),
           let route = routes.first(where: { $0.id == widgetRouteId }) {
            selectedRoute = route
            print("🔧 MAIN: Using selected widget route: \(route.name)")
        } else if let firstRoute = routes.first {
            selectedRoute = firstRoute
            print("🔧 MAIN: Using first route as fallback: \(firstRoute.name)")
        }

        guard let route = selectedRoute,
              let status = statusByRouteId[route.id],
              let firstOption = status.options.first else {
            print("⚠️ MAIN: Cannot publish snapshot - missing route data")
            return
        }

        let leave = status.leaveInMinutes ?? 0
        // Calculate walking time (you can enhance this with actual location-based calculation)
        let walkingTime = calculateWalkingTime(for: route)
        let snapshot = WidgetSnapshot(routeId: route.id, routeName: route.name, leaveInMinutes: leave, departure: firstOption.departure, arrival: firstOption.arrival, walkingTime: walkingTime)
        print("🔧 MAIN: Publishing snapshot - Route: \(route.name), Leave in: \(leave)min, Walking: \(walkingTime ?? 0)min")
        sharedStore.save(snapshot: snapshot)
        sharedStore.save(snapshot: snapshot, for: route.id)
        print("🔧 MAIN: Snapshot saved to SharedStore")

        // Debug: Verify the data was saved
        if let loadedSnapshot = sharedStore.loadSnapshot() {
            print("✅ MAIN: Snapshot verification successful - Loaded: \(loadedSnapshot.routeName)")
        } else {
            print("❌ MAIN: Snapshot verification failed - Could not load saved snapshot")
        }

        WidgetCenter.shared.reloadAllTimelines()
        print("✅ MAIN: Widget timelines reloaded")
    }

    // MARK: - Widget Route Selection
    func selectRouteForWidget(routeId: UUID) {
        print("🔧 MAIN: Selecting route for widget: \(routeId)")
        sharedStore.saveWidgetRoute(id: routeId)
        publishSnapshotIfAvailable() // Update widget immediately
        print("✅ MAIN: Widget route selection saved")
    }

    // MARK: - Widget Testing
    func testWidgetDataFlow() {
        print("🧪 MAIN: Testing widget data flow...")
        publishSnapshotIfAvailable()
        print("🧪 MAIN: Widget data flow test completed")
    }

    func getSelectedWidgetRoute() -> Route? {
        guard let routeId = sharedStore.loadWidgetRoute() else { return nil }
        return routes.first(where: { $0.id == routeId })
    }

    private func calculateWalkingTime(for route: Route) -> Int {
        // Simple walking time calculation based on route name
        // You can enhance this with actual location-based calculations
        if route.name.lowercased().contains("home") {
            return 5 // 5 minutes to home station
        } else if route.name.lowercased().contains("work") || route.name.lowercased().contains("office") {
            return 8 // 8 minutes to work station
        } else {
            return 6 // Default 6 minutes
        }
    }

    // MARK: - Journey Details with Stops
    @Published var selectedJourneyDetails: JourneyDetails?
    @Published var isLoadingJourneyDetails = false

    func loadJourneyDetails(for journeyOption: JourneyOption) async {
        isLoadingJourneyDetails = true
        defer { isLoadingJourneyDetails = false }

        do {
            // Use real journey data from the JourneyOption
            let journeyDetails = await createJourneyDetailsFromOption(journeyOption)
            await MainActor.run {
                selectedJourneyDetails = journeyDetails
            }
            print("✅ [RoutesViewModel] Successfully loaded journey details with \(journeyDetails.legs.count) legs")

            // DEBUG: Log total stops across all legs
            let totalStops = journeyDetails.legs.reduce(0) { $0 + $1.intermediateStops.count + 2 } // +2 for origin/destination
            print("🎯 [RoutesViewModel] Total stops in journey: \(totalStops)")
            print("🎯 [RoutesViewModel] Legs breakdown:")
            for (index, leg) in journeyDetails.legs.enumerated() {
                let stopsInLeg = leg.intermediateStops.count + 2 // +2 for origin/destination
                print("🎯 [RoutesViewModel]   Leg \(index): \(stopsInLeg) stops (\(leg.intermediateStops.count) intermediate)")
            }
        } catch {
            print("❌ [RoutesViewModel] Failed to load journey details: \(error)")
        }
    }

    // MARK: - Live Activity Management

    private func manageLiveActivities(for routeStatuses: [UUID: RouteStatus]) async {
        print("🚂 [LiveActivity] Managing Live Activities for \(routeStatuses.count) routes")

        for (routeId, status) in routeStatuses {
            guard let route = routes.first(where: { $0.id == routeId }),
                  let firstOption = status.options.first else {
                continue
            }

            let leaveInMinutes = status.leaveInMinutes ?? 0
            let hasExistingActivity = activeLiveActivities[routeId] != nil

            // Start Live Activity for upcoming departures (within 30 minutes)
            if leaveInMinutes > 0 && leaveInMinutes <= 30 && !hasExistingActivity {
                // Use a timeout to prevent Live Activity operations from hanging
                Task {
                    do {
                        // Set a timeout for Live Activity operations
                        let timeoutTask = Task {
                            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds timeout
                            throw NSError(domain: "LiveActivityTimeout", code: -1, userInfo: [NSLocalizedDescriptionKey: "Live Activity operation timed out"])
                        }

                        let activityTask = Task {
                            return try await liveActivityService.startTrainDepartureActivity(
                                routeId: routeId.uuidString,
                                routeName: route.name,
                                originName: route.origin.name,
                                destinationName: route.destination.name,
                                departureTime: firstOption.departure,
                                arrivalTime: firstOption.arrival,
                                platform: firstOption.platform,
                                lineName: firstOption.lineName,
                                delayMinutes: firstOption.delayMinutes,
                                walkingTime: Int(locationService.calculateWalkingTimeForRoute(route).toOrigin / 60)
                            )
                        }

                        let result = try await activityTask.value
                        timeoutTask.cancel() // Cancel timeout since operation completed

                        if let activityId = result {
                            await MainActor.run {
                                activeLiveActivities[routeId] = activityId
                            }
                            print("✅ [LiveActivity] Started activity for route: \(route.name) - ID: \(activityId)")
                        }
                    } catch {
                        print("❌ [LiveActivity] Failed to start activity for route: \(route.name) - \(error.localizedDescription)")
                    }
                }
            }

            // Update existing Live Activity
            else if let activityId = activeLiveActivities[routeId] {
                Task {
                    do {
                        // Set a timeout for Live Activity update operations
                        let timeoutTask = Task {
                            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds timeout
                            throw NSError(domain: "LiveActivityUpdateTimeout", code: -1, userInfo: [NSLocalizedDescriptionKey: "Live Activity update timed out"])
                        }

                        let updateTask = Task {
                            await liveActivityService.updateTrainDepartureActivity(
                                activityId: activityId,
                                routeName: route.name,
                                leaveInMinutes: leaveInMinutes,
                                departureTime: firstOption.departure,
                                arrivalTime: firstOption.arrival,
                                platform: firstOption.platform,
                                lineName: firstOption.lineName,
                                delayMinutes: firstOption.delayMinutes,
                                walkingTime: Int(locationService.calculateWalkingTimeForRoute(route).toOrigin / 60)
                            )
                        }

                        await updateTask.value
                        timeoutTask.cancel()
                        print("🔄 [LiveActivity] Updated activity for route: \(route.name)")
                    } catch {
                        print("❌ [LiveActivity] Failed to update activity for route: \(route.name) - \(error.localizedDescription)")
                    }
                }
            }

            // End Live Activity if departure is too far away or already departed
            else if let activityId = activeLiveActivities[routeId], (leaveInMinutes > 30 || leaveInMinutes <= 0) {
                Task {
                    do {
                        // Set a timeout for Live Activity end operations
                        let timeoutTask = Task {
                            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second timeout
                            throw NSError(domain: "LiveActivityEndTimeout", code: -1, userInfo: [NSLocalizedDescriptionKey: "Live Activity end timed out"])
                        }

                        let endTask = Task {
                            await liveActivityService.endTrainDepartureActivity(activityId: activityId, finalStatus: leaveInMinutes <= 0 ? "departed" : "completed")
                        }

                        await endTask.value
                        timeoutTask.cancel()

                        await MainActor.run {
                            activeLiveActivities.removeValue(forKey: routeId)
                        }
                        print("🏁 [LiveActivity] Ended activity for route: \(route.name)")
                    } catch {
                        print("❌ [LiveActivity] Failed to end activity for route: \(route.name) - \(error.localizedDescription)")
                    }
                }
            }
        }

        print("🚂 [LiveActivity] Active activities: \(activeLiveActivities.count)")
    }

    // MARK: - Debug Functions

    // DEBUG: Manual testing function for journey stops
    func debugJourneyStops() {
        print("🧪 [RoutesViewModel] DEBUG: Journey Stops Testing")
        print("🧪 [RoutesViewModel] ===============================")

        // Show expected API response structure
        debugJourneyStopovers()

        print("🧪 [RoutesViewModel] Current journey details available: \(selectedJourneyDetails != nil)")
        if let details = selectedJourneyDetails {
            print("🧪 [RoutesViewModel] Journey has \(details.legs.count) legs")
            for (index, leg) in details.legs.enumerated() {
                print("🧪 [RoutesViewModel] Leg \(index): \(leg.origin.name) → \(leg.destination.name)")
                print("🧪 [RoutesViewModel]   Intermediate stops: \(leg.intermediateStops.count)")
                if !leg.intermediateStops.isEmpty {
                    print("🧪 [RoutesViewModel]   Stop details:")
                    for (stopIndex, stop) in leg.intermediateStops.enumerated() {
                        print("🧪 [RoutesViewModel]     \(stopIndex + 1). \(stop.name) (Platform: \(stop.platform ?? "N/A"))")
                        if let arr = stop.scheduledArrival {
                            print("🧪 [RoutesViewModel]        Arrival: \(arr.formatted())")
                        }
                        if let dep = stop.scheduledDeparture {
                            print("🧪 [RoutesViewModel]        Departure: \(dep.formatted())")
                        }
                    }
                } else {
                    print("🧪 [RoutesViewModel]   No intermediate stops found")
                }
            }
        } else {
            print("🧪 [RoutesViewModel] No journey details loaded yet. Select a journey option first.")
        }

        print("🧪 [RoutesViewModel] ===============================")
        print("🧪 [RoutesViewModel] If you see 'No intermediate stops found', the API may not be returning stopovers.")
        print("🧪 [RoutesViewModel] Check the API logs above to verify stopovers=true is being sent.")
    }

    private func createJourneyDetailsFromOption(_ journeyOption: JourneyOption) async -> JourneyDetails {
        // Use the real leg data from the JourneyOption if available, otherwise create a basic structure
        let legsToUse: [JourneyLeg]

        if let optionLegs = journeyOption.legs, !optionLegs.isEmpty {
            // Use the real leg data from the API
            legsToUse = optionLegs
            print("🔧 [RoutesViewModel] Using real journey legs: \(optionLegs.count) legs")

            // DEBUG: Log intermediate stops for each leg
            for (index, leg) in optionLegs.enumerated() {
                print("🔍 [RoutesViewModel] Leg \(index): \(leg.origin.name) → \(leg.destination.name)")
                print("🔍 [RoutesViewModel] Intermediate stops: \(leg.intermediateStops.count)")
                for (stopIndex, stop) in leg.intermediateStops.enumerated() {
                    print("🔍 [RoutesViewModel]   Stop \(stopIndex): \(stop.name) at \(stop.scheduledArrival?.formatted() ?? "No time")")
                }
            }
        } else {
            // Fallback: create a basic single leg if no detailed leg information
            let basicOrigin = StopInfo(
                id: "origin",
                name: "Origin Station",
                platform: journeyOption.platform,
                scheduledDeparture: journeyOption.departure,
                actualDeparture: journeyOption.departure
            )

            let basicDestination = StopInfo(
                id: "destination",
                name: "Destination Station",
                platform: nil,
                scheduledArrival: journeyOption.arrival,
                actualArrival: journeyOption.arrival
            )

            let basicLeg = JourneyLeg(
                origin: basicOrigin,
                destination: basicDestination,
                intermediateStops: [],
                departure: journeyOption.departure,
                arrival: journeyOption.arrival,
                lineName: journeyOption.lineName,
                platform: journeyOption.platform,
                direction: nil,
                delayMinutes: journeyOption.delayMinutes
            )

            legsToUse = [basicLeg]
            print("🔧 [RoutesViewModel] Using basic single leg (no detailed leg data available)")
        }

        // Calculate total stops (origin + destination + intermediate stops)
        let totalStops = legsToUse.reduce(0) { $0 + $1.allStops.count }

        return JourneyDetails(
            id: journeyOption.id.uuidString,
            journeyId: journeyOption.id.uuidString,
            legs: legsToUse,
            totalDuration: journeyOption.totalMinutes,
            totalStops: totalStops
        )
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

    // MARK: - Personalized Recommendations
    func generateRecommendations(for timeOfDay: TimeOfDay) -> [RouteRecommendation] {
        var recommendations: [RouteRecommendation] = []

        // Get routes with sufficient usage data
        let eligibleRoutes = routes.filter { $0.usageCount >= 3 }

        guard !eligibleRoutes.isEmpty else { return [] }

        // 1. Favorite routes (highest priority)
        let favoriteRecommendations = eligibleRoutes
            .filter { $0.isFavorite }
            .map { route in
                RouteRecommendation(
                    route: route,
                    reason: "Your favorite route that you love",
                    confidenceScore: 0.95,
                    confidenceLevel: 5,
                    lastUsed: route.lastUsed,
                    recommendationType: .favorite
                )
            }
        recommendations.append(contentsOf: favoriteRecommendations)

        // 2. Time-based recommendations
        let timeBasedRecommendations = generateTimeBasedRecommendations(for: timeOfDay, from: eligibleRoutes)
        recommendations.append(contentsOf: timeBasedRecommendations)

        // 3. Pattern-based recommendations (frequent routes)
        let patternRecommendations = generatePatternBasedRecommendations(from: eligibleRoutes)
        recommendations.append(contentsOf: patternRecommendations)

        // 4. Reliability-based recommendations
        let reliableRecommendations = generateReliabilityBasedRecommendations(from: eligibleRoutes)
        recommendations.append(contentsOf: reliableRecommendations)

        // Remove duplicates and sort by confidence
        let uniqueRecommendations = Array(Set(recommendations.map { $0.route.id }).map { id in
            recommendations.first { $0.route.id == id }!
        })

        return uniqueRecommendations
            .sorted { $0.confidenceScore > $1.confidenceScore }
            .prefix(5)
            .map { $0 }
    }

    private func generateTimeBasedRecommendations(for timeOfDay: TimeOfDay, from routes: [Route]) -> [RouteRecommendation] {
        let currentHour = Calendar.current.component(.hour, from: Date())
        let timeRange = timeOfDay.timeRange

        // Find routes typically used during this time period
        return routes
            .filter { route in
                // Check if route is typically used during this time
                let routeHour = Calendar.current.component(.hour, from: route.lastUsed)
                return routeHour >= timeRange.start && routeHour < timeRange.end
            }
            .map { route in
                let reason = timeOfDay == .now ?
                    "Perfect timing for your usual schedule" :
                    "You often travel during \(timeOfDay.rawValue.lowercased()) hours"

                return RouteRecommendation(
                    route: route,
                    reason: reason,
                    confidenceScore: 0.85,
                    confidenceLevel: 4,
                    lastUsed: route.lastUsed,
                    recommendationType: .timeBased
                )
            }
    }

    private func generatePatternBasedRecommendations(from routes: [Route]) -> [RouteRecommendation] {
        // Find routes with high usage frequency
        return routes
            .filter { $0.usageFrequency == .daily || $0.usageCount >= 20 }
            .sorted { $0.usageCount > $1.usageCount }
            .prefix(3)
            .map { route in
                let frequency = route.usageFrequency.rawValue
                let reason = "Your most \(frequency) route with \(route.usageCount) trips"

                return RouteRecommendation(
                    route: route,
                    reason: reason,
                    confidenceScore: 0.80,
                    confidenceLevel: 4,
                    lastUsed: route.lastUsed,
                    recommendationType: .patternBased
                )
            }
            .map { $0 }
    }

    private func generateReliabilityBasedRecommendations(from routes: [Route]) -> [RouteRecommendation] {
        // Find routes with good reliability scores
        return routes
            .filter { route in
                if let stats = routeStatistics[route.id] {
                    return stats.reliabilityScore >= 0.8
                }
                return false
            }
            .sorted { (routeStatistics[$0.id]?.reliabilityScore ?? 0) > (routeStatistics[$1.id]?.reliabilityScore ?? 0) }
            .prefix(2)
            .map { route in
                RouteRecommendation(
                    route: route,
                    reason: "Highly reliable route with consistent performance",
                    confidenceScore: 0.75,
                    confidenceLevel: 4,
                    lastUsed: route.lastUsed,
                    recommendationType: .reliable
                )
            }
            .map { $0 }
    }
}