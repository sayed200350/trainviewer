import Foundation
import CoreLocation

struct Place: Identifiable, Codable, Hashable {
    var id: String { rawId ?? computedId }
    let rawId: String?
    let name: String
    let latitude: Double?
    let longitude: Double?

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private var computedId: String {
        if let lat = latitude, let lon = longitude {
            return "coord:\(lat),\(lon)\n\(name)"
        }
        return name
    }
}

// MARK: - Transport.rest decoding

struct DBPlace: Codable {
    let id: String?
    let name: String?
    let type: String?
    let location: DBLocation?
}

struct DBLocation: Codable {
    let type: String?
    let latitude: Double?
    let longitude: Double?
}