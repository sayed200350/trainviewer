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

    @Published var isSearchingFrom: Bool = false
    @Published var isSearchingTo: Bool = false

    @Published var showRecentFrom: Bool = false
    @Published var showRecentTo: Bool = false

    @Published var recentFromLocations: [Place] = []
    @Published var recentToLocations: [Place] = []

    private let api: TransportAPI
    private let store: RouteStore
    private let locationService: LocationService?

    private var searchFromTask: Task<Void, Never>?
    private var searchToTask: Task<Void, Never>?

    init(api: TransportAPI = TransportAPIFactory.shared.make(), store: RouteStore = RouteStore(), locationService: LocationService? = nil) {
        self.api = api
        self.store = store
        self.locationService = locationService

        // Load recent locations
        loadRecentLocations()
    }

    func searchFrom() async {
        // Cancel previous search
        searchFromTask?.cancel()

        let query = fromQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            fromResults = []
            isSearchingFrom = false
            return
        }

        isSearchingFrom = true
        showRecentFrom = false

        searchFromTask = Task {
            do {
                let results = try await api.searchLocations(query: query, limit: 8)
                if !Task.isCancelled {
                    fromResults = results
                    isSearchingFrom = false
                }
            } catch {
                if !Task.isCancelled {
                    fromResults = []
                    isSearchingFrom = false
                }
            }
        }

        await searchFromTask?.value
    }

    func searchTo() async {
        // Cancel previous search
        searchToTask?.cancel()

        let query = toQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            toResults = []
            isSearchingTo = false
            return
        }

        isSearchingTo = true
        showRecentTo = false

        searchToTask = Task {
            do {
                let results = try await api.searchLocations(query: query, limit: 8)
                if !Task.isCancelled {
                    toResults = results
                    isSearchingTo = false
                }
            } catch {
                if !Task.isCancelled {
                    toResults = []
                    isSearchingTo = false
                }
            }
        }

        await searchToTask?.value
    }

    func useCurrentLocationForFrom() {
        // This would require location permissions and service
        // For now, we'll show a placeholder
        let currentLocation = Place(
            rawId: "current_location",
            name: "Current Location",
            latitude: nil,
            longitude: nil
        )
        selectedFrom = currentLocation
        fromQuery = currentLocation.name
        showRecentFrom = false
        fromResults = []
    }

    func useCurrentLocationForTo() {
        let currentLocation = Place(
            rawId: "current_location",
            name: "Current Location",
            latitude: nil,
            longitude: nil
        )
        selectedTo = currentLocation
        toQuery = currentLocation.name
        showRecentTo = false
        toResults = []
    }

    func saveRoute() {
        guard let from = selectedFrom, let to = selectedTo else { return }

        // Auto-generate route name if empty
        var routeName = self.routeName
        if routeName.isEmpty {
            routeName = generateSmartRouteName(from: from, to: to)
        }

        let route = Route(name: routeName, origin: from, destination: to)
        store.add(route: route)

        // Save to recent locations
        saveToRecentLocations(from: from, to: to)
    }

    private func generateSmartRouteName(from: Place, to: Place) -> String {
        let fromName = from.name.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? from.name
        let toName = to.name.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? to.name

        // Try to make it more readable
        let commonPatterns = ["Station", "Railway", "Train", "Bahnhof", "Gare", "Stazione"]
        var shortFrom = fromName
        var shortTo = toName

        for pattern in commonPatterns {
            shortFrom = shortFrom.replacingOccurrences(of: pattern, with: "").trimmingCharacters(in: .whitespaces)
            shortTo = shortTo.replacingOccurrences(of: pattern, with: "").trimmingCharacters(in: .whitespaces)
        }

        return "\(shortFrom) → \(shortTo)"
    }

    private func loadRecentLocations() {
        // Load recent locations from UserDefaults
        loadRecentLocationsFromStorage()

        // If no recent locations exist, start with empty arrays
        // This will be populated as users search and select locations
        if recentFromLocations.isEmpty && recentToLocations.isEmpty {
            // No hardcoded locations - users will build their own recent list
            recentFromLocations = []
            recentToLocations = []
        }
    }

    private func loadRecentLocationsFromStorage() {
        let defaults = UserDefaults.standard
        let maxRecentLocations = 5

        // Load recent "from" locations
        if let fromData = defaults.data(forKey: "recentFromLocations"),
           let fromLocations = try? JSONDecoder().decode([Place].self, from: fromData) {
            recentFromLocations = Array(fromLocations.prefix(maxRecentLocations))
        } else {
            recentFromLocations = []
        }

        // Load recent "to" locations
        if let toData = defaults.data(forKey: "recentToLocations"),
           let toLocations = try? JSONDecoder().decode([Place].self, from: toData) {
            recentToLocations = Array(toLocations.prefix(maxRecentLocations))
        } else {
            recentToLocations = []
        }
    }

    private func saveRecentLocationsToStorage() {
        let defaults = UserDefaults.standard

        // Save recent "from" locations
        if let fromData = try? JSONEncoder().encode(recentFromLocations) {
            defaults.set(fromData, forKey: "recentFromLocations")
        }

        // Save recent "to" locations
        if let toData = try? JSONEncoder().encode(recentToLocations) {
            defaults.set(toData, forKey: "recentToLocations")
        }

        defaults.synchronize()
    }

    private func saveToRecentLocations(from: Place, to: Place) {
        // Add to recent locations if not already there
        if !recentFromLocations.contains(where: { $0.id == from.id }) {
            recentFromLocations.insert(from, at: 0)
            if recentFromLocations.count > 5 {
                recentFromLocations = Array(recentFromLocations.prefix(5))
            }
        }

        if !recentToLocations.contains(where: { $0.id == to.id }) {
            recentToLocations.insert(to, at: 0)
            if recentToLocations.count > 5 {
                recentToLocations = Array(recentToLocations.prefix(5))
            }
        }

        // Save to persistent storage
        saveRecentLocationsToStorage()
    }

    deinit {
        searchFromTask?.cancel()
        searchToTask?.cancel()
    }
}