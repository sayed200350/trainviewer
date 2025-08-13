import Foundation

@MainActor
final class EditRouteViewModel: ObservableObject {
    @Published var routeName: String
    @Published var fromQuery: String
    @Published var toQuery: String

    @Published var fromResults: [Place] = []
    @Published var toResults: [Place] = []

    @Published var selectedFrom: Place
    @Published var selectedTo: Place
    @Published var bufferMinutes: Int

    private let api: TransportAPI
    private let store: RouteStore
    private let originalId: UUID

    init(route: Route, api: TransportAPI = DBTransportAPI(), store: RouteStore = RouteStore()) {
        self.api = api
        self.store = store
        self.originalId = route.id
        self.routeName = route.name
        self.selectedFrom = route.origin
        self.selectedTo = route.destination
        self.bufferMinutes = route.preparationBufferMinutes
        self.fromQuery = route.origin.name
        self.toQuery = route.destination.name
    }

    func searchFrom() async {
        guard !fromQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { fromResults = []; return }
        fromResults = (try? await api.searchLocations(query: fromQuery, limit: 8)) ?? []
    }

    func searchTo() async {
        guard !toQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { toResults = []; return }
        toResults = (try? await api.searchLocations(query: toQuery, limit: 8)) ?? []
    }

    func saveChanges() {
        let name = routeName.isEmpty ? "\(selectedFrom.name) → \(selectedTo.name)" : routeName
        var updated = Route(id: originalId, name: name, origin: selectedFrom, destination: selectedTo)
        updated.preparationBufferMinutes = bufferMinutes
        store.update(route: updated)
    }
}