import Foundation

@MainActor
final class RouteDetailViewModel: ObservableObject {
    @Published private(set) var options: [JourneyOption] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let api: TransportAPI
    private let route: Route

    init(route: Route, api: TransportAPI = DBTransportAPI()) {
        self.route = route
        self.api = api
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let res = try await api.nextJourneyOptions(from: route.origin, to: route.destination, results: 5)
            options = res
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}