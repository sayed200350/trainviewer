import Foundation
import MapKit
import CoreLocation
import Combine
import SwiftUI

@MainActor
final class MapViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var region: MKCoordinateRegion
    @Published var nearbyStations: [TransitStation] = []
    @Published var selectedRoute: Route?
    @Published var showingRouteOverlay: Bool = false
    @Published var userLocation: CLLocation?
    @Published var isLoadingStations: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let locationService: LocationService
    private let transportAPI: TransportAPI
    private let routeStore: RouteStore
    private var cancellables = Set<AnyCancellable>()
    
    // Map configuration constants
    private let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    private let nearbyStationsRadius: Double = 1000.0 // 1km radius
    private let maxNearbyStations: Int = 10
    
    // MARK: - Initialization
    init(locationService: LocationService = LocationService.shared,
         transportAPI: TransportAPI = TransportAPIFactory.createAPI(),
         routeStore: RouteStore = RouteStore()) {
        
        self.locationService = locationService
        self.transportAPI = transportAPI
        self.routeStore = routeStore
        
        // Initialize with default region (Berlin center as fallback)
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
            span: defaultSpan
        )
        
        setupLocationObserver()
        setupInitialLocation()
    }
    
    // MARK: - Setup Methods
    private func setupLocationObserver() {
        // Observe location changes
        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.userLocation = location
                self?.updateRegionForUserLocation(location)
                self?.loadNearbyStations(around: location.coordinate)
            }
            .store(in: &cancellables)
    }
    
    private func setupInitialLocation() {
        // Try to get last known location or request permission
        if let currentLocation = locationService.currentLocation {
            userLocation = currentLocation
            updateRegionForUserLocation(currentLocation)
            loadNearbyStations(around: currentLocation.coordinate)
        } else {
            locationService.requestAuthorization()
        }
    }
    
    // MARK: - Public Methods
    
    /// Centers the map on user's current location
    func centerOnUserLocation() {
        guard let location = userLocation ?? locationService.currentLocation else {
            locationService.requestAuthorization()
            return
        }
        
        updateRegionForUserLocation(location)
        loadNearbyStations(around: location.coordinate)
    }
    
    /// Selects a route and shows its overlay on the map
    func selectRoute(_ route: Route) {
        selectedRoute = route
        showingRouteOverlay = true
        updateRegionForRoute(route)
    }
    
    /// Clears the selected route and hides overlay
    func clearSelectedRoute() {
        selectedRoute = nil
        showingRouteOverlay = false
    }
    
    /// Updates the route overlay display
    func updateRouteOverlay() {
        guard let route = selectedRoute else {
            showingRouteOverlay = false
            return
        }
        
        showingRouteOverlay = true
        updateRegionForRoute(route)
    }
    
    /// Loads nearby transit stations around a coordinate
    func loadNearbyStations(around coordinate: CLLocationCoordinate2D) {
        isLoadingStations = true
        errorMessage = nil
        
        Task {
            do {
                let stations = try await fetchNearbyStations(coordinate: coordinate)
                await MainActor.run {
                    self.nearbyStations = stations
                    self.isLoadingStations = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load nearby stations: \(error.localizedDescription)"
                    self.isLoadingStations = false
                }
            }
        }
    }
    
    /// Updates map region to show a specific route
    func updateRegionForRoute(_ route: Route) {
        guard let originCoord = route.origin.coordinate,
              let destCoord = route.destination.coordinate else {
            return
        }
        
        // Calculate region that encompasses both origin and destination
        let minLat = min(originCoord.latitude, destCoord.latitude)
        let maxLat = max(originCoord.latitude, destCoord.latitude)
        let minLon = min(originCoord.longitude, destCoord.longitude)
        let maxLon = max(originCoord.longitude, destCoord.longitude)
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.005) * 1.2, // Add 20% padding
            longitudeDelta: max(maxLon - minLon, 0.005) * 1.2
        )
        
        region = MKCoordinateRegion(center: center, span: span)
    }
    
    /// Gets all saved routes for display on map
    func getAllRoutes() -> [Route] {
        return routeStore.fetchAll()
    }
    
    /// Gets favorite routes for priority display
    func getFavoriteRoutes() -> [Route] {
        return routeStore.fetchAll().filter { $0.isFavorite }
    }
    
    // MARK: - Private Methods
    
    private func updateRegionForUserLocation(_ location: CLLocation) {
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: defaultSpan
        )
    }
    
    private func fetchNearbyStations(coordinate: CLLocationCoordinate2D) async throws -> [TransitStation] {
        // Create a Place object for the coordinate to use with transport API
        let searchPlace = Place(
            rawId: nil,
            name: "Current Location",
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        
        // Use the transport API to find nearby stations
        // This is a simplified implementation - in a real app, you'd use a dedicated nearby stations API
        let nearbyPlaces = try await searchNearbyStations(around: searchPlace)
        
        // Convert places to transit stations with mock departure data
        let stations = nearbyPlaces.prefix(maxNearbyStations).map { place in
            TransitStation(
                id: place.id,
                name: place.name,
                coordinate: place.coordinate ?? coordinate,
                type: determineStationType(from: place.name),
                nextDepartures: [], // Would be populated with real API call
                distance: calculateDistance(from: coordinate, to: place.coordinate ?? coordinate)
            )
        }
        
        return Array(stations)
    }
    
    private func searchNearbyStations(around place: Place) async throws -> [Place] {
        // This is a simplified implementation
        // In a real app, you would use a dedicated nearby stations API endpoint
        // For now, we'll return mock data based on the location
        
        guard let coordinate = place.coordinate else {
            return []
        }
        
        // Mock nearby stations - in production, this would be an API call
        return generateMockNearbyStations(around: coordinate)
    }
    
    private func generateMockNearbyStations(around coordinate: CLLocationCoordinate2D) -> [Place] {
        // Generate some mock stations around the coordinate
        let offsets: [(Double, Double, String, String)] = [
            (0.002, 0.001, "Hauptbahnhof", "8011160"),
            (-0.001, 0.003, "Alexanderplatz", "8010255"),
            (0.003, -0.002, "Potsdamer Platz", "8010255"),
            (-0.002, -0.001, "Friedrichstraße", "8011306"),
            (0.001, 0.002, "Hackescher Markt", "8010255")
        ]
        
        return offsets.map { (latOffset, lonOffset, name, id) in
            Place(
                rawId: id,
                name: name,
                latitude: coordinate.latitude + latOffset,
                longitude: coordinate.longitude + lonOffset
            )
        }
    }
    
    private func determineStationType(from stationName: String) -> StationType {
        let name = stationName.lowercased()
        
        if name.contains("hauptbahnhof") || name.contains("bahnhof") {
            return .train
        } else if name.contains("u-") || name.contains("u ") {
            return .subway
        } else if name.contains("bus") {
            return .bus
        } else if name.contains("tram") || name.contains("str") {
            return .tram
        } else {
            return .train // Default to train
        }
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
}

// MARK: - Route Overlay Support
extension MapViewModel {
    /// Creates a polyline for the selected route
    func createRoutePolyline() -> MKPolyline? {
        guard let route = selectedRoute,
              let originCoord = route.origin.coordinate,
              let destCoord = route.destination.coordinate else {
            return nil
        }
        
        let coordinates = [originCoord, destCoord]
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
    
    /// Gets the color for the route overlay
    func getRouteOverlayColor() -> Color {
        return selectedRoute?.color.color ?? .blue
    }
}

// MARK: - Map Annotations Support
extension MapViewModel {
    /// Creates map annotations for all saved routes
    func createRouteAnnotations() -> [RouteAnnotation] {
        let routes = getAllRoutes()
        var annotations: [RouteAnnotation] = []
        
        for route in routes {
            if let originCoord = route.origin.coordinate {
                annotations.append(RouteAnnotation(
                    coordinate: originCoord,
                    title: route.origin.name,
                    subtitle: "Origin: \(route.name)",
                    route: route,
                    type: .origin
                ))
            }
            
            if let destCoord = route.destination.coordinate {
                annotations.append(RouteAnnotation(
                    coordinate: destCoord,
                    title: route.destination.name,
                    subtitle: "Destination: \(route.name)",
                    route: route,
                    type: .destination
                ))
            }
        }
        
        return annotations
    }
    
    /// Creates map annotations for nearby transit stations
    func createStationAnnotations() -> [StationAnnotation] {
        return nearbyStations.map { station in
            StationAnnotation(
                coordinate: station.coordinate,
                title: station.name,
                subtitle: station.type.displayName,
                station: station
            )
        }
    }
}

// MARK: - Map Annotation Types
struct RouteAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String
    let route: Route
    let type: RoutePointType
}

enum RoutePointType {
    case origin, destination
}

struct StationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String
    let station: TransitStation
}