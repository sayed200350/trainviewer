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
        isRefreshing = true
        defer { isRefreshing = false }
        await withTaskGroup(of: (UUID, RouteStatus?).self) { group in
            for route in routes {
                group.addTask { [weak self] in
                    guard let self = self else { return (route.id, nil) }
                    do {
                        let options = try await self.api.nextJourneyOptions(from: route.origin, to: route.destination, results: AppConstants.defaultResultsCount)
                        self.cache(options: options, for: route)
                        let status = self.computeStatus(for: route, options: options)
                        return (route.id, status)
                    } catch {
                        let cached = OfflineCache.shared.load(routeId: route.id) ?? []
                        let status = self.computeStatus(for: route, options: cached)
                        return (route.id, status)
                    }
                }
            }
            var newStatus: [UUID: RouteStatus] = [:]
            for await (id, status) in group {
                if let status = status { newStatus[id] = status }
            }
            statusByRouteId = newStatus
            publishSnapshotIfAvailable()
            await refreshClassSuggestion()
            notifyIfDisruptions()
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

    private func computeStatus(for route: Route, options: [JourneyOption]) -> RouteStatus {
        let now = Date()
        var leaveIn: Int? = nil
        if let first = options.first {
            let walkingMinutes = computeWalkingMinutes(to: route.origin)
            let baseBuffer = route.preparationBufferMinutes
            let examExtra = settings.examModeEnabled ? 5 : 0
            let buffer = baseBuffer + examExtra
            let minutesUntilDeparture = Int(first.departure.timeIntervalSince(now) / 60)
            let minutesToLeave = minutesUntilDeparture - walkingMinutes - buffer
            leaveIn = max(0, minutesToLeave)
        }
        return RouteStatus(options: options, leaveInMinutes: leaveIn, lastUpdated: now)
    }

    private func computeWalkingMinutes(to place: Place) -> Int {
        guard let dest = place.coordinate, let current = locationService.currentLocation else { return 0 }
        let distance = current.distance(from: CLLocation(latitude: dest.latitude, longitude: dest.longitude))
        let speed = settings.nightModePreference ? AppConstants.defaultWalkingSpeedMetersPerSecond * 0.9 : AppConstants.defaultWalkingSpeedMetersPerSecond
        let seconds = distance / speed
        return Int(ceil(seconds / 60.0))
    }

    private func routeMatchingCampus() -> Route? {
        guard let campus = settings.campusPlace else { return nil }
        // Match by name fallback
        if let byName = routes.first(where: { $0.destination.name.localizedCaseInsensitiveContains(campus.name) }) { return byName }
        // or by distance if coordinates present
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
        let arrivalLead = 5 * 60 // arrive 5 min early
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
        // Fetch options for campus route
        if let options = try? await api.nextJourneyOptions(from: route.origin, to: route.destination, results: 5), let selected = findOptionArrivingBefore(options, eventStart: event.startDate) {
            let buffer = bufferForRoute(route) * 60
            let leave = computeLeaveForEvent(using: selected, buffer: buffer, eventStart: event.startDate)
            nextClass = ClassSuggestion(routeName: route.name, eventTitle: event.title, eventStart: event.startDate, leaveInMinutes: leave)
        } else {
            nextClass = nil
        }
    }
}