import Foundation

public struct WidgetSnapshot: Codable {
    public let routeId: UUID
    public let routeName: String
    public let leaveInMinutes: Int
    public let departure: Date
    public let arrival: Date
    public let walkingTime: Int? // Walking time in minutes

    public init(routeId: UUID, routeName: String, leaveInMinutes: Int, departure: Date, arrival: Date, walkingTime: Int? = nil) {
        self.routeId = routeId
        self.routeName = routeName
        self.leaveInMinutes = leaveInMinutes
        self.departure = departure
        self.arrival = arrival
        self.walkingTime = walkingTime
    }
}

public struct RouteSummary: Codable, Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public init(id: UUID, name: String) { self.id = id; self.name = name }
}

// MARK: - Journey Details with Stops
public struct JourneyDetails: Codable, Identifiable, Hashable, Equatable {
    public let id: String
    public let journeyId: String
    public let legs: [JourneyLeg]
    public let totalDuration: Int // in minutes
    public let totalStops: Int

    public init(id: String = UUID().uuidString, journeyId: String, legs: [JourneyLeg], totalDuration: Int, totalStops: Int) {
        self.id = id
        self.journeyId = journeyId
        self.legs = legs
        self.totalDuration = totalDuration
        self.totalStops = totalStops
    }

    enum CodingKeys: String, CodingKey {
        case id, journeyId, legs, totalDuration, totalStops
    }
}

public struct JourneyLeg: Codable, Identifiable, Hashable, Equatable {
    public let id: UUID
    public let origin: StopInfo
    public let destination: StopInfo
    public let intermediateStops: [StopInfo]
    public let departure: Date
    public let arrival: Date
    public let lineName: String?
    public let platform: String?
    public let direction: String?
    public let delayMinutes: Int?

    public init(id: UUID = UUID(), origin: StopInfo, destination: StopInfo, intermediateStops: [StopInfo] = [], departure: Date, arrival: Date, lineName: String? = nil, platform: String? = nil, direction: String? = nil, delayMinutes: Int? = nil) {
        self.id = id
        self.origin = origin
        self.destination = destination
        self.intermediateStops = intermediateStops
        self.departure = departure
        self.arrival = arrival
        self.lineName = lineName
        self.platform = platform
        self.direction = direction
        self.delayMinutes = delayMinutes
    }

    public var duration: TimeInterval {
        arrival.timeIntervalSince(departure)
    }

    public var allStops: [StopInfo] {
        [origin] + intermediateStops + [destination]
    }

    enum CodingKeys: String, CodingKey {
        case id, origin, destination, intermediateStops, departure, arrival, lineName, platform, direction, delayMinutes
    }
}

public struct StopInfo: Codable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let platform: String?
    public let scheduledArrival: Date?
    public let actualArrival: Date?
    public let scheduledDeparture: Date?
    public let actualDeparture: Date?

    public init(id: String, name: String, platform: String? = nil, scheduledArrival: Date? = nil, actualArrival: Date? = nil, scheduledDeparture: Date? = nil, actualDeparture: Date? = nil) {
        self.id = id
        self.name = name
        self.platform = platform
        self.scheduledArrival = scheduledArrival
        self.actualArrival = actualArrival
        self.scheduledDeparture = scheduledDeparture
        self.actualDeparture = actualDeparture
    }

    public var displayTime: Date? {
        scheduledDeparture ?? scheduledArrival ?? actualDeparture ?? actualArrival
    }

    public var hasDelay: Bool {
        if let scheduled = scheduledDeparture ?? scheduledArrival,
           let actual = actualDeparture ?? actualArrival {
            return actual.timeIntervalSince(scheduled) > 60 // More than 1 minute delay
        }
        return false
    }

    public var delayMinutes: Int? {
        if let scheduled = scheduledDeparture ?? scheduledArrival,
           let actual = actualDeparture ?? actualArrival {
            let delay = actual.timeIntervalSince(scheduled) / 60
            return delay > 0 ? Int(delay) : nil
        }
        return nil
    }
}

// MARK: - Design System Colors (Gen Z Dark Theme)
import SwiftUI

extension Color {
    // Brand Colors - Optimized for Gen Z Dark Theme
    static let brandDark = Color(hex: "#0a0a0a")       // True black background
    static let brandBlue = Color(hex: "#1a73e8")       // Trust/stability blue
    static let accentOrange = Color(hex: "#ff6b35")    // Energy/action orange
    static let accentGreen = Color(hex: "#00d4aa")     // Growth/success green
    static let accentRed = Color(hex: "#ef4444")       // Urgent action red

    // Text Colors
    static let textPrimary = Color.white               // Primary text on dark
    static let textSecondary = Color.gray.opacity(0.7) // Secondary text
    static let textTertiary = Color.gray.opacity(0.5)  // Tertiary text

    // Surface Colors
    static let cardBackground = Color(hex: "#111111")  // Card backgrounds
    static let elevatedBackground = Color(hex: "#1a1a1a") // Elevated surfaces
    static let borderColor = Color.gray.opacity(0.2)   // Subtle borders

    // Status Colors
    static let successColor = Color(hex: "#10b981")    // Success green
    static let warningColor = Color(hex: "#f59e0b")    // Warning orange
    static let errorColor = Color(hex: "#ef4444")      // Error red
    static let infoColor = Color(hex: "#3b82f6")       // Info blue
}

// MARK: - Hex Color Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}