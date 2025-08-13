import Foundation

@MainActor
final class AddRouteViewModel: ObservableObject {
    @Published var routeName: String = ""
    @Published var fromQuery: String = ""
    @Published var toQuery: String = ""

    @Published var fromResults: [Place] = []
    @Published var toResults: [Place] = []

    @Published var selectedFrom: Place?
    @Published var selectedTo: Place?

    private let api: TransportAPI
    private let store: RouteStore

    init(api: TransportAPI = TransportAPIFactory.shared.make(), store: RouteStore = RouteStore()) {
        self.api = api
        self.store = store
    }

    func searchFrom() async {
        guard !fromQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { fromResults = []; return }
        fromResults = (try? await api.searchLocations(query: fromQuery, limit: 8)) ?? []
    }

    func searchTo() async {
        guard !toQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { toResults = []; return }
        toResults = (try? await api.searchLocations(query: toQuery, limit: 8)) ?? []
    }

    func saveRoute() {
        guard let from = selectedFrom, let to = selectedTo else { return }
        let name = routeName.isEmpty ? "\(from.name) → \(to.name)" : routeName
        let route = Route(name: name, origin: from, destination: to)
        store.add(route: route)
    }
}