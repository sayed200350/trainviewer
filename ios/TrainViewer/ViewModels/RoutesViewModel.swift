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

    init(store: RouteStore = RouteStore(), api: TransportAPI = DBTransportAPI(), locationService: LocationService = .shared, sharedStore: SharedStore = .shared) {
        self.store = store
        self.api = api
        self.locationService = locationService
        self.sharedStore = sharedStore
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
                    let options = try? await self.api.nextJourneyOptions(from: route.origin, to: route.destination, results: AppConstants.defaultResultsCount)
                    let status = self.computeStatus(for: route, options: options ?? [])
                    return (route.id, status)
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
            let buffer = route.preparationBufferMinutes
            let minutesUntilDeparture = Int(first.departure.timeIntervalSince(now) / 60)
            let minutesToLeave = minutesUntilDeparture - walkingMinutes - buffer
            leaveIn = max(0, minutesToLeave)
        }
        return RouteStatus(options: options, leaveInMinutes: leaveIn, lastUpdated: now)
    }

    private func computeWalkingMinutes(to place: Place) -> Int {
        guard let dest = place.coordinate, let current = locationService.currentLocation else { return 0 }
        let distance = current.distance(from: CLLocation(latitude: dest.latitude, longitude: dest.longitude))
        let seconds = distance / AppConstants.defaultWalkingSpeedMetersPerSecond
        return Int(ceil(seconds / 60.0))
    }
}