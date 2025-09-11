import Foundation
import WidgetKit

public struct WidgetSnapshot: Codable {
    public let routeId: UUID
    public let routeName: String
    public let leaveInMinutes: Int
    public let departure: Date
    public let arrival: Date
    public let walkingTime: Int? // Walking time in minutes

    // Enhanced fields for better widget experience
    public let platform: String?
    public let lineName: String?
    public let delayMinutes: Int?
    public let direction: String?
    public let nextDepartures: [UpcomingDeparture]?

    public init(
        routeId: UUID,
        routeName: String,
        leaveInMinutes: Int,
        departure: Date,
        arrival: Date,
        walkingTime: Int? = nil,
        platform: String? = nil,
        lineName: String? = nil,
        delayMinutes: Int? = nil,
        direction: String? = nil,
        nextDepartures: [UpcomingDeparture]? = nil
    ) {
        self.routeId = routeId
        self.routeName = routeName
        self.leaveInMinutes = leaveInMinutes
        self.departure = departure
        self.arrival = arrival
        self.walkingTime = walkingTime
        self.platform = platform
        self.lineName = lineName
        self.delayMinutes = delayMinutes
        self.direction = direction
        self.nextDepartures = nextDepartures
    }
}

public struct UpcomingDeparture: Codable, Identifiable {
    public let id: UUID
    public let departure: Date
    public let lineName: String?
    public let platform: String?
    public let delayMinutes: Int?

    public init(id: UUID = UUID(), departure: Date, lineName: String? = nil, platform: String? = nil, delayMinutes: Int? = nil) {
        self.id = id
        self.departure = departure
        self.lineName = lineName
        self.platform = platform
        self.delayMinutes = delayMinutes
    }
}

// MARK: - Enhanced Widget Data for Multiple Routes
public struct WidgetRouteData: Codable, Identifiable {
    public let id: UUID
    public let routeId: UUID
    public let routeName: String
    public let leaveInMinutes: Int
    public let departure: Date
    public let arrival: Date
    public let walkingTime: Int?
    public let platform: String?
    public let lineName: String?
    public let delayMinutes: Int?
    public let direction: String?
    public let nextDepartures: [UpcomingDeparture]?
    public let status: String // "onTime", "delayed", "cancelled", "departNow"

    public init(
        routeId: UUID,
        routeName: String,
        leaveInMinutes: Int,
        departure: Date,
        arrival: Date,
        walkingTime: Int? = nil,
        platform: String? = nil,
        lineName: String? = nil,
        delayMinutes: Int? = nil,
        direction: String? = nil,
        nextDepartures: [UpcomingDeparture]? = nil,
        status: String = "onTime"
    ) {
        self.id = routeId
        self.routeId = routeId
        self.routeName = routeName
        self.leaveInMinutes = leaveInMinutes
        self.departure = departure
        self.arrival = arrival
        self.walkingTime = walkingTime
        self.platform = platform
        self.lineName = lineName
        self.delayMinutes = delayMinutes
        self.direction = direction
        self.nextDepartures = nextDepartures
        self.status = status
    }
}

public struct WidgetMultiRouteSnapshot: Codable {
    public let routes: [WidgetRouteData]
    public let lastUpdated: Date
    public let isConnected: Bool

    public init(routes: [WidgetRouteData], lastUpdated: Date = Date(), isConnected: Bool = true) {
        self.routes = routes
        self.lastUpdated = lastUpdated
        self.isConnected = isConnected
    }
}

public struct RouteSummary: Codable, Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let fromName: String
    public let toName: String
    public let toLat: Double
    public let toLon: Double

    public init(id: UUID, name: String, fromName: String, toName: String, toLat: Double, toLon: Double) {
        self.id = id
        self.name = name
        self.fromName = fromName
        self.toName = toName
        self.toLat = toLat
        self.toLon = toLon
    }
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

// MARK: - Widget Data Loader (Shared between main app and widget)
public class WidgetDataLoader {
    private static let snapshotKey = "widget_main_snapshot"
    private static let multiRouteSnapshotKey = "widget_multi_route_snapshot"
    private static let refreshRequestKey = "widget_refresh_requested"
    private static let appGroupIdentifier = "group.com.bahnblitz.app"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    public static func loadWidgetSnapshot() -> WidgetSnapshot? {
        guard let data = sharedDefaults?.data(forKey: snapshotKey) else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    public static func loadMultiRouteSnapshot() -> WidgetMultiRouteSnapshot? {
        guard let data = sharedDefaults?.data(forKey: multiRouteSnapshotKey) else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetMultiRouteSnapshot.self, from: data)
    }

    public static func saveMultiRouteSnapshot(_ snapshot: WidgetMultiRouteSnapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            sharedDefaults?.set(data, forKey: multiRouteSnapshotKey)
        }
    }

    public static func isDataAvailable() -> Bool {
        return sharedDefaults?.data(forKey: snapshotKey) != nil
    }

    public static func isMultiRouteDataAvailable() -> Bool {
        return sharedDefaults?.data(forKey: multiRouteSnapshotKey) != nil
    }

    public static func validateAndCleanEntry(_ entry: WidgetEntry) -> WidgetEntry {
        let now = Date()
        var cleanedEntry = entry
        var departureAdvanced = false

        // If departure time has passed, try to advance to next available departure
        if entry.departure <= now {
            // Try to find next departure from nextDepartures array
            if let nextDeparture = findNextAvailableDeparture(from: entry.nextDepartures, after: now) {
                cleanedEntry.departure = nextDeparture.departure
                cleanedEntry.platform = nextDeparture.platform
                cleanedEntry.lineName = nextDeparture.lineName
                cleanedEntry.delayMinutes = nextDeparture.delayMinutes

                // Recalculate leave time for the new departure
                let timeUntilDeparture = nextDeparture.departure.timeIntervalSince(now)
                let leaveMinutes = max(0, Int(timeUntilDeparture / 60))
                cleanedEntry.leaveInMinutes = leaveMinutes

                // Update status for new departure
                if leaveMinutes <= 0 {
                    cleanedEntry.status = .departNow
                } else if let delay = nextDeparture.delayMinutes, delay > 0 {
                    cleanedEntry.status = .delayed(delay)
                } else {
                    cleanedEntry.status = .onTime
                }

                departureAdvanced = true
                print("🎯 WIDGET: Advanced to next departure: \(nextDeparture.departure)")
            } else {
                // No next departure available, show depart now for current
                cleanedEntry.leaveInMinutes = 0
                cleanedEntry.status = .departNow
                print("🎯 WIDGET: No next departure available, showing depart now")
            }
        } else {
            // Recalculate leave time based on current time
            let timeUntilDeparture = entry.departure.timeIntervalSince(now)
            let leaveMinutes = max(0, Int(timeUntilDeparture / 60))
            cleanedEntry.leaveInMinutes = leaveMinutes

            // Update status based on new leave time
            if leaveMinutes <= 0 {
                cleanedEntry.status = .departNow
            }
        }

        // If we advanced to a new departure, trigger a refresh request
        if departureAdvanced {
            requestMainAppRefresh()
        }

        return cleanedEntry
    }

    // Helper function to find the next available departure after a given time
    private static func findNextAvailableDeparture(from departures: [UpcomingDeparture]?, after currentTime: Date) -> UpcomingDeparture? {
        guard let departures = departures, !departures.isEmpty else { return nil }

        // Find the first departure that is after the current time
        return departures
            .filter { $0.departure > currentTime }
            .sorted { $0.departure < $1.departure }
            .first
    }

    // Request main app to refresh widget data
    private static func requestMainAppRefresh() {
        // Set a flag in shared defaults that the main app can check
        sharedDefaults?.set(Date(), forKey: refreshRequestKey)
        sharedDefaults?.synchronize()

        print("🎯 WIDGET: Requested main app refresh due to expired departure")
    }

    // Check if widget refresh was requested
    public static func wasRefreshRequested() -> Bool {
        guard let refreshRequestTime = sharedDefaults?.object(forKey: refreshRequestKey) as? Date else {
            return false
        }

        // Only consider refresh request valid if it's within the last 5 minutes
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        return refreshRequestTime > fiveMinutesAgo
    }

    // Clear refresh request flag
    public static func clearRefreshRequest() {
        sharedDefaults?.removeObject(forKey: refreshRequestKey)
    }
}

// MARK: - Widget Entry (Shared)
public struct WidgetEntry: TimelineEntry {
    public let date: Date
    public let routeId: UUID?
    public let routeName: String
    public var leaveInMinutes: Int
    public var departure: Date
    public let arrival: Date
    public var platform: String?
    public var lineName: String?
    public let walkingTime: Int?
    public var delayMinutes: Int?
    public let direction: String?
    public let nextDepartures: [UpcomingDeparture]?
    public var status: WidgetStatus
    public let lastUpdated: Date?
    public let isConnected: Bool

    public init(
        date: Date,
        routeId: UUID?,
        routeName: String,
        leaveInMinutes: Int,
        departure: Date,
        arrival: Date,
        platform: String? = nil,
        lineName: String? = nil,
        walkingTime: Int? = nil,
        delayMinutes: Int? = nil,
        direction: String? = nil,
        nextDepartures: [UpcomingDeparture]? = nil,
        status: WidgetStatus = .onTime,
        lastUpdated: Date? = nil,
        isConnected: Bool = true
    ) {
        self.date = date
        self.routeId = routeId
        self.routeName = routeName
        self.leaveInMinutes = leaveInMinutes
        self.departure = departure
        self.arrival = arrival
        self.platform = platform
        self.lineName = lineName
        self.walkingTime = walkingTime
        self.delayMinutes = delayMinutes
        self.direction = direction
        self.nextDepartures = nextDepartures
        self.status = status
        self.lastUpdated = lastUpdated
        self.isConnected = isConnected
    }
}

// MARK: - Multi-Route Widget Entry
public struct MultiRouteWidgetEntry: TimelineEntry {
    public let date: Date
    public let routes: [WidgetRouteData]
    public let lastUpdated: Date
    public let isConnected: Bool
    public let currentRouteIndex: Int

    public init(date: Date, routes: [WidgetRouteData], lastUpdated: Date, isConnected: Bool, currentRouteIndex: Int = 0) {
        self.date = date
        self.routes = routes
        self.lastUpdated = lastUpdated
        self.isConnected = isConnected
        self.currentRouteIndex = currentRouteIndex
    }
}

// MARK: - Widget Status
public enum WidgetStatus: Equatable {
    case onTime
    case delayed(Int)
    case cancelled
    case departNow

    public var color: Color {
        switch self {
        case .onTime: return Color(hex: "#10b981")     // Green for on time
        case .delayed: return Color(hex: "#f59e0b")     // Orange for delayed
        case .cancelled: return Color(hex: "#ef4444")   // Red for cancelled
        case .departNow: return Color(hex: "#1a73e8")   // Blue for depart now
        }
    }

    public var displayText: String {
        switch self {
        case .onTime: return "PÜNKTLICH"      // German: "ON TIME"
        case .delayed(let minutes): return "\(minutes) MIN SPÄTER"  // German: "MIN LATE"
        case .cancelled: return "ENTFÄLLT"     // German: "CANCELLED"
        case .departNow: return "JETZT"  // German: "DEPART NOW"
        }
    }

    public var shortText: String {
        switch self {
        case .onTime: return "OK"
        case .delayed(let minutes): return "+\(minutes)"
        case .cancelled: return "X"
        case .departNow: return "JETZT"
        }
    }
}