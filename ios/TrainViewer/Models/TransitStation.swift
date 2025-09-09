import Foundation
import CoreLocation

public struct TransitStation: Identifiable, Hashable, Codable {
    public let id: String
    public let name: String
    public let coordinate: CLLocationCoordinate2D
    public let type: StationType
    public let nextDepartures: [JourneyOption]
    public let distance: Double? // Distance from user location in meters
    
    public init(id: String, name: String, coordinate: CLLocationCoordinate2D, type: StationType, nextDepartures: [JourneyOption] = [], distance: Double? = nil) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.type = type
        self.nextDepartures = nextDepartures
        self.distance = distance
    }
}

public enum StationType: String, CaseIterable, Codable {
    case train = "train"
    case bus = "bus"
    case tram = "tram"
    case subway = "subway"
    case ferry = "ferry"
    
    public var displayName: String {
        switch self {
        case .train: return "Train"
        case .bus: return "Bus"
        case .tram: return "Tram"
        case .subway: return "Subway"
        case .ferry: return "Ferry"
        }
    }
    
    public var iconName: String {
        switch self {
        case .train: return "train.side.front.car"
        case .bus: return "bus"
        case .tram: return "tram"
        case .subway: return "train.side.middle.car"
        case .ferry: return "ferry"
        }
    }
}

// MARK: - CLLocationCoordinate2D Codable Support
extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}

// MARK: - CLLocationCoordinate2D Hashable Support
extension CLLocationCoordinate2D: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
    
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}