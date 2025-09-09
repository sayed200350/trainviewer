import SwiftUI
import CoreLocation

struct LocationInfoView: View {
    let route: Route
    @ObservedObject var locationService: LocationService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Walking time information
            if locationService.currentLocation != nil {
                walkingTimeSection
                proximitySection
            } else {
                Text("Waiting for location...")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
    
    @ViewBuilder
    private var walkingTimeSection: some View {
        let walkingTimes = locationService.calculateWalkingTimeForRoute(route)
        
        VStack(alignment: .leading, spacing: 4) {
            Label("Walking Times", systemImage: "figure.walk")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("To Origin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatWalkingTime(walkingTimes.toOrigin))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("To Destination")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatWalkingTime(walkingTimes.toDestination))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
    }
    
    @ViewBuilder
    private var proximitySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Check if user is near this route's locations
            let isNearOrigin = locationService.isNearPlace(route.origin, threshold: 200.0)
            let isNearDestination = locationService.isNearPlace(route.destination, threshold: 200.0)
            
            if isNearOrigin || isNearDestination {
                Label("Proximity Alert", systemImage: "location.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                
                if isNearOrigin {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("You're near \(route.origin.name)")
                            .font(.caption)
                    }
                }
                
                if isNearDestination {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("You're near \(route.destination.name)")
                            .font(.caption)
                    }
                }
            }
            
            // Show distance information
            if let originDistance = locationService.distanceToPlace(route.origin) {
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.blue)
                    Text("Origin: \(formatDistance(originDistance))")
                        .font(.caption)
                }
            }
            
            if let destDistance = locationService.distanceToPlace(route.destination) {
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.blue)
                    Text("Destination: \(formatDistance(destDistance))")
                        .font(.caption)
                }
            }
        }
    }
    
    private func formatWalkingTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        if minutes < 1 {
            return "< 1 min"
        } else if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m away"
        } else {
            let km = distance / 1000
            return String(format: "%.1fkm away", km)
        }
    }
}

#Preview {
    let sampleRoute = Route(
        name: "Home to Work",
        origin: Place(rawId: "1", name: "Berlin Hauptbahnhof", latitude: 52.5251, longitude: 13.3694),
        destination: Place(rawId: "2", name: "Potsdamer Platz", latitude: 52.5096, longitude: 13.3765)
    )
    
    return LocationInfoView(route: sampleRoute, locationService: LocationService.shared)
        .padding()
}