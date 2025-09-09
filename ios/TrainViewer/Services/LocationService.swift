import Foundation
import CoreLocation
import Combine

// MARK: - Protocol for RouteStore Dependency Injection

protocol RouteStoreProtocol {
    func fetchAll() -> [Route]
    func add(route: Route)
    func update(route: Route)
    func delete(routeId: UUID)
}

extension RouteStore: RouteStoreProtocol {}

final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var isNearSavedLocation: Bool = false
    @Published private(set) var nearestSavedLocation: Place?
    @Published private(set) var nearbyRoutes: [Route] = []

    private let manager = CLLocationManager()
    private let routeStore: RouteStoreProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Proximity detection constants
    private let proximityThresholdMeters: Double = 200.0 // 200 meters
    private let locationUpdateInterval: TimeInterval = 30.0 // 30 seconds
    private var lastProximityCheck: Date = Date.distantPast

    init(routeStore: RouteStoreProtocol = RouteStore()) {
        self.routeStore = routeStore
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 50.0 // Only update when moved 50+ meters
        
        setupLocationUpdates()
    }
    
    private func setupLocationUpdates() {
        // Monitor location changes for proximity detection
        $currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.checkProximityToSavedLocations(from: location)
            }
            .store(in: &cancellables)
    }

    func requestAuthorization() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Handle denied permission - could show alert to go to settings
            break
        case .authorizedAlways, .authorizedWhenInUse:
            startUpdates()
        @unknown default:
            break
        }
    }
    
    func requestPermissionWithUserFriendlyMessage() -> String {
        switch authorizationStatus {
        case .notDetermined:
            requestAuthorization()
            return "Location access will help us automatically detect when you're near your saved routes and provide walking time estimates."
        case .denied:
            return "Location access is required for automatic route detection and walking time calculations. Please enable it in Settings > Privacy & Security > Location Services."
        case .restricted:
            return "Location access is restricted on this device. Some features may not be available."
        case .authorizedAlways, .authorizedWhenInUse:
            return "Location access is enabled. We'll automatically detect when you're near your saved routes."
        @unknown default:
            return "Unknown location permission status."
        }
    }

    func startUpdates() {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            return
        }
        manager.startUpdatingLocation()
    }

    func stopUpdates() {
        manager.stopUpdatingLocation()
    }
    
    // MARK: - Proximity Detection
    
    private func checkProximityToSavedLocations(from currentLocation: CLLocation) {
        // Throttle proximity checks to avoid excessive computation
        let now = Date()
        guard now.timeIntervalSince(lastProximityCheck) >= locationUpdateInterval else {
            return
        }
        lastProximityCheck = now
        
        let allRoutes = routeStore.fetchAll()
        var nearbyRoutes: [Route] = []
        var nearestLocation: Place?
        var shortestDistance: Double = Double.infinity
        
        for route in allRoutes {
            // Check proximity to origin
            if let originCoord = route.origin.coordinate {
                let originLocation = CLLocation(latitude: originCoord.latitude, longitude: originCoord.longitude)
                let distanceToOrigin = currentLocation.distance(from: originLocation)
                
                if distanceToOrigin <= proximityThresholdMeters {
                    nearbyRoutes.append(route)
                    if distanceToOrigin < shortestDistance {
                        shortestDistance = distanceToOrigin
                        nearestLocation = route.origin
                    }
                }
            }
            
            // Check proximity to destination
            if let destCoord = route.destination.coordinate {
                let destLocation = CLLocation(latitude: destCoord.latitude, longitude: destCoord.longitude)
                let distanceToDestination = currentLocation.distance(from: destLocation)
                
                if distanceToDestination <= proximityThresholdMeters {
                    if !nearbyRoutes.contains(where: { $0.id == route.id }) {
                        nearbyRoutes.append(route)
                    }
                    if distanceToDestination < shortestDistance {
                        shortestDistance = distanceToDestination
                        nearestLocation = route.destination
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            self.nearbyRoutes = nearbyRoutes
            self.isNearSavedLocation = !nearbyRoutes.isEmpty
            self.nearestSavedLocation = nearestLocation
        }
    }
    
    // MARK: - Walking Time Calculations
    
    func calculateWalkingTime(to destination: CLLocation, walkingSpeed: Double = AppConstants.defaultWalkingSpeedMetersPerSecond) -> TimeInterval {
        guard let currentLocation = currentLocation else {
            return 0
        }
        
        let distance = currentLocation.distance(from: destination)
        return distance / walkingSpeed
    }
    
    func calculateWalkingTime(to place: Place, walkingSpeed: Double = AppConstants.defaultWalkingSpeedMetersPerSecond) -> TimeInterval {
        guard let coordinate = place.coordinate else {
            return 0
        }
        
        let destination = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return calculateWalkingTime(to: destination, walkingSpeed: walkingSpeed)
    }
    
    func calculateWalkingTimeForRoute(_ route: Route) -> (toOrigin: TimeInterval, toDestination: TimeInterval) {
        let toOrigin = calculateWalkingTime(to: route.origin, walkingSpeed: route.walkingSpeedMetersPerSecond)
        let toDestination = calculateWalkingTime(to: route.destination, walkingSpeed: route.walkingSpeedMetersPerSecond)
        return (toOrigin: toOrigin, toDestination: toDestination)
    }
    
    // MARK: - Utility Methods
    
    func distanceToPlace(_ place: Place) -> Double? {
        guard let currentLocation = currentLocation,
              let coordinate = place.coordinate else {
            return nil
        }
        
        let placeLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return currentLocation.distance(from: placeLocation)
    }
    
    func isNearPlace(_ place: Place, threshold: Double = 200.0) -> Bool {
        guard let distance = distanceToPlace(place) else {
            return false
        }
        return distance <= threshold
    }
    
    // Get routes where user is currently near the origin (useful for departure suggestions)
    func getRoutesNearOrigin() -> [Route] {
        return nearbyRoutes.filter { route in
            guard let coordinate = route.origin.coordinate else { return false }
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            return calculateWalkingTime(to: location) <= 300 // Within 5 minutes walk
        }
    }
    
    // Get routes where user is currently near the destination (useful for return journey suggestions)
    func getRoutesNearDestination() -> [Route] {
        return nearbyRoutes.filter { route in
            guard let coordinate = route.destination.coordinate else { return false }
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            return calculateWalkingTime(to: location) <= 300 // Within 5 minutes walk
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
        
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            startUpdates()
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.isNearSavedLocation = false
                self.nearestSavedLocation = nil
                self.nearbyRoutes = []
            }
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        // Filter out old or inaccurate locations
        let locationAge = newLocation.timestamp.timeIntervalSinceNow
        if abs(locationAge) > 30.0 { // Ignore locations older than 30 seconds
            return
        }
        
        if newLocation.horizontalAccuracy > 100.0 { // Ignore locations with poor accuracy
            return
        }
        
        DispatchQueue.main.async {
            self.currentLocation = newLocation
        }
        
        // Save location to shared store
        SharedStore.shared.saveLastLocation(latitude: newLocation.coordinate.latitude, longitude: newLocation.coordinate.longitude)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle location errors gracefully
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                DispatchQueue.main.async {
                    self.authorizationStatus = .denied
                }
            case .locationUnknown:
                // Temporary error, keep trying
                break
            case .network:
                // Network error, could retry later
                break
            default:
                print("Location error: \(error.localizedDescription)")
            }
        }
    }
}