import Foundation

/// Represents a journey option with departure, arrival, and transport details
public struct JourneyOption: Identifiable, Codable, Hashable {
    public let id: UUID
    public let departure: Date
    public let arrival: Date
    public let lineName: String?
    public let platform: String?
    public let delayMinutes: Int?
    public let totalMinutes: Int
    public let warnings: [String]?
    public let refreshToken: String?

    // Add detailed journey information
    public let legs: [JourneyLeg]?
    
    public init(
        id: UUID = UUID(),
        departure: Date,
        arrival: Date,
        lineName: String? = nil,
        platform: String? = nil,
        delayMinutes: Int? = nil,
        totalMinutes: Int,
        warnings: [String]? = nil,
        refreshToken: String? = nil,
        legs: [JourneyLeg]? = nil
    ) {
        self.id = id
        self.departure = departure
        self.arrival = arrival
        self.lineName = lineName
        self.platform = platform
        self.delayMinutes = delayMinutes
        self.totalMinutes = totalMinutes
        self.warnings = warnings
        self.refreshToken = refreshToken
        self.legs = legs
    }
    
    /// Whether this journey can be refreshed with real-time data
    public var canRefresh: Bool {
        refreshToken != nil && departure.timeIntervalSinceNow > -3600 // Not more than 1 hour old
    }
    
    /// Duration of the journey
    public var duration: TimeInterval {
        arrival.timeIntervalSince(departure)
    }
    
    /// Whether the journey has any delays
    public var hasDelay: Bool {
        (delayMinutes ?? 0) > 0
    }
    
    /// Whether the journey has warnings
    public var hasWarnings: Bool {
        !(warnings?.isEmpty ?? true)
    }
}

// MARK: - Coding Keys
extension JourneyOption {
    enum CodingKeys: String, CodingKey {
        case id, departure, arrival, lineName, platform, delayMinutes, totalMinutes, warnings, refreshToken, legs
    }
}