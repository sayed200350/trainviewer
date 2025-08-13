import Foundation
import CoreLocation

struct RouteStatus: Hashable {
    let options: [JourneyOption]
    let leaveInMinutes: Int?
    let lastUpdated: Date
}

@MainActor
final class RoutesViewModel: ObservableObject {
    @Published private(set) var routes: [Route] = []
    @Published private(set) var statusByRouteId: [UUID: RouteStatus] = [:]
    @Published var isRefreshing: Bool = false

    private let store: RouteStore
    private let api: TransportAPI
    private let locationService: LocationService
    private let sharedStore: SharedStore
    private let settings: UserSettingsStore

    init(store: RouteStore = RouteStore(), api: TransportAPI = DBTransportAPI(), locationService: LocationService = .shared, sharedStore: SharedStore = .shared, settings: UserSettingsStore = .shared) {
        self.store = store
        self.api = api
        self.locationService = locationService
        self.sharedStore = sharedStore
        self.settings = settings
    }

    func loadRoutes() {
        routes = store.fetchAll()
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
                        // Fallback to offline cache
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
        }
    }

    private func cache(options: [JourneyOption], for route: Route) {
        OfflineCache.shared.save(routeId: route.id, options: options)
    }

    private func publishSnapshotIfAvailable() {
        guard let firstRoute = routes.first, let status = statusByRouteId[firstRoute.id], let firstOption = status.options.first else { return }
        let leave = status.leaveInMinutes ?? 0
        let snapshot = WidgetSnapshot(routeId: firstRoute.id, routeName: firstRoute.name, leaveInMinutes: leave, departure: firstOption.departure, arrival: firstOption.arrival)
        sharedStore.save(snapshot: snapshot)
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
}