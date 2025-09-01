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

    private let store: RouteStore
    private let api: TransportAPI
    private let locationService: LocationService
    private let sharedStore: SharedStore
    private let settings: UserSettingsStore

    init(store: RouteStore = RouteStore(), api: TransportAPI = TransportAPIFactory.shared.make(), locationService: LocationService = .shared, sharedStore: SharedStore = .shared, settings: UserSettingsStore = .shared) {
        self.store = store
        self.api = api
        self.locationService = locationService
        self.sharedStore = sharedStore
        self.settings = settings
    }

    func loadRoutes() {
        routes = store.fetchAll()
        publishRouteSummaries()
    }

    func deleteRoute(at offsets: IndexSet) {
        for index in offsets { store.delete(routeId: routes[index].id) }
        loadRoutes()
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

    private func cache(options: [JourneyOption], for route: Route) {
        OfflineCache.shared.save(routeId: route.id, options: options)
    }

    private func publishRouteSummaries() {
        let summaries = routes.map { RouteSummary(id: $0.id, name: $0.name) }
        sharedStore.saveRouteSummaries(summaries)
    }

    private func publishSnapshotIfAvailable() {
        guard let firstRoute = routes.first, let status = statusByRouteId[firstRoute.id], let firstOption = status.options.first else { return }
        let leave = status.leaveInMinutes ?? 0
        let snapshot = WidgetSnapshot(routeId: firstRoute.id, routeName: firstRoute.name, leaveInMinutes: leave, departure: firstOption.departure, arrival: firstOption.arrival)
        sharedStore.save(snapshot: snapshot)
        sharedStore.save(snapshot: snapshot, for: firstRoute.id)
        WidgetCenter.shared.reloadAllTimelines()
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