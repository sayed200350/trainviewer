import Foundation
import CoreLocation

public struct Place: Identifiable, Codable, Hashable {
    public var id: String { rawId ?? computedId }
    public let rawId: String?
    public let name: String
    public let latitude: Double?
    public let longitude: Double?

    public var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private var computedId: String {
        if let lat = latitude, let lon = longitude {
            return "coord:\(lat),\(lon)\n\(name)"
        }
        return name
    }
    
    public init(rawId: String?, name: String, latitude: Double?, longitude: Double?) {
        self.rawId = rawId
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Transport.rest decoding

public struct DBPlace: Codable {
    public let id: String?
    public let name: String?
    public let type: String?
    public let location: DBLocation?
}

public struct DBLocation: Codable {
    public let type: String?
    public let latitude: Double?
    public let longitude: Double?
}
