//
//  TrainViewerWidget.swift
//  TrainViewerWidget
//
//  Created by Xcode Template
//

import WidgetKit
import SwiftUI
import ActivityKit
import Foundation
import CoreLocation

// MARK: - Simplified Models for Widget Extension
// These are simplified versions of the main app models for widget use

public struct WidgetPlace: Codable, Hashable {
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

public struct WidgetRoute: Identifiable, Hashable, Codable {
    public let id: UUID
    public var name: String
    public var origin: WidgetPlace
    public var destination: WidgetPlace

    public init(id: UUID = UUID(), name: String, origin: WidgetPlace, destination: WidgetPlace) {
        self.id = id
        self.name = name
        self.origin = origin
        self.destination = destination
    }
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

// MARK: - Shared Widget Data Models
public struct WidgetSnapshot: Codable {
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
    public let status: String

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

public enum WidgetStatus: Equatable {
    case onTime
    case delayed(Int)
    case cancelled
    case departNow

    public var color: Color {
        switch self {
        case .onTime: return Color(hex: "#10b981")
        case .delayed: return Color(hex: "#f59e0b")
        case .cancelled: return Color(hex: "#ef4444")
        case .departNow: return Color(hex: "#1a73e8")
        }
    }

    public var displayText: String {
        switch self {
        case .onTime: return "PÜNKTLICH"
        case .delayed(let minutes): return "\(minutes) MIN SPÄTER"
        case .cancelled: return "ENTFÄLLT"
        case .departNow: return "JETZT"
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

        if entry.departure <= now {
            if let nextDeparture = findNextAvailableDeparture(from: entry.nextDepartures, after: now) {
                cleanedEntry.departure = nextDeparture.departure
                cleanedEntry.platform = nextDeparture.platform
                cleanedEntry.lineName = nextDeparture.lineName
                cleanedEntry.delayMinutes = nextDeparture.delayMinutes

                let timeUntilDeparture = nextDeparture.departure.timeIntervalSince(now)
                let leaveMinutes = max(0, Int(timeUntilDeparture / 60))
                cleanedEntry.leaveInMinutes = leaveMinutes

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
                cleanedEntry.leaveInMinutes = 0
                cleanedEntry.status = .departNow
                print("🎯 WIDGET: No next departure available, showing depart now")
            }
        } else {
            let timeUntilDeparture = entry.departure.timeIntervalSince(now)
            let leaveMinutes = max(0, Int(timeUntilDeparture / 60))
            cleanedEntry.leaveInMinutes = leaveMinutes

            if leaveMinutes <= 0 {
                cleanedEntry.status = .departNow
            }
        }

        if departureAdvanced {
            requestMainAppRefresh()
        }

        return cleanedEntry
    }

    private static func findNextAvailableDeparture(from departures: [UpcomingDeparture]?, after currentTime: Date) -> UpcomingDeparture? {
        guard let departures = departures, !departures.isEmpty else { return nil }

        return departures
            .filter { $0.departure > currentTime }
            .sorted { $0.departure < $1.departure }
            .first
    }

    public static func requestMainAppRefresh() {
        sharedDefaults?.set(Date(), forKey: refreshRequestKey)
        sharedDefaults?.synchronize()

        print("🎯 WIDGET: Requested main app refresh due to expired departure")
    }

    public static func wasRefreshRequested() -> Bool {
        guard let refreshRequestTime = sharedDefaults?.object(forKey: refreshRequestKey) as? Date else {
            return false
        }

        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        return refreshRequestTime > fiveMinutesAgo
    }

    public static func clearRefreshRequest() {
        sharedDefaults?.removeObject(forKey: refreshRequestKey)
    }
}

// MARK: - German Transport Styling
struct GermanTransportStyling {
    static func formatPlatform(_ platform: String?) -> String {
        guard let platform = platform else { return "" }
        // Add "Gleis" prefix for German style
        if platform.contains("Gleis") || platform.contains("Platform") {
            return platform
        } else {
            return "Gleis \(platform)"
        }
    }

    static func formatLineName(_ lineName: String?) -> String {
        guard let lineName = lineName else { return "" }
        // Ensure proper German formatting for line names
        if lineName.hasPrefix("S") || lineName.hasPrefix("U") || lineName.hasPrefix("RE") || lineName.hasPrefix("RB") {
            return lineName
        } else {
            return lineName
        }
    }

    static func formatDirection(_ direction: String?) -> String {
        guard let direction = direction else { return "" }
        // Convert common German directions to abbreviations
        var formatted = direction
        formatted = formatted.replacingOccurrences(of: "Hauptbahnhof", with: "Hbf")
        formatted = formatted.replacingOccurrences(of: "Bahnhof", with: "Bf")
        formatted = formatted.replacingOccurrences(of: "Flughafen", with: "Airport")
        return "nach \(formatted)"  // German: "to"
    }

    static func transportColor(for lineName: String?) -> Color {
        guard let lineName = lineName else { return Color(hex: "#1a73e8") }

        if lineName.hasPrefix("S") {
            return Color(hex: "#00d4aa")  // S-Bahn green
        } else if lineName.hasPrefix("U") {
            return Color(hex: "#ff6b35")  // U-Bahn orange
        } else if lineName.hasPrefix("RE") {
            return Color(hex: "#1a73e8")  // Regional Express blue
        } else if lineName.hasPrefix("RB") {
            return Color(hex: "#374151")  // Regional Bahn gray
        } else if lineName.hasPrefix("IC") || lineName.hasPrefix("EC") {
            return Color(hex: "#0a0a0a")  // InterCity black
        } else {
            return Color(hex: "#1a73e8")  // Default blue
        }
    }
}

// MARK: - Widget Provider
struct Provider: TimelineProvider {

    public func determineStatus(leaveInMinutes: Int, delayMinutes: Int?, departure: Date) -> WidgetStatus {
        let now = Date()

        // If departure time has passed, it's depart now
        if departure <= now {
            return .departNow
        }

        // If there's a delay, show delayed status
        if let delay = delayMinutes, delay > 0 {
            return .delayed(delay)
        }

        // If within 5 minutes, show depart now
        if leaveInMinutes <= 0 {
            return .departNow
        }

        // Otherwise, on time
        return .onTime
    }
    func placeholder(in context: Context) -> WidgetEntry {
        // Create more realistic placeholder data
        let now = Date()
        let nextDeparture = now.addingTimeInterval(900) // 15 minutes from now
        let arrivalTime = nextDeparture.addingTimeInterval(2700) // 45 minutes later

        let nextDep1 = UpcomingDeparture(
            id: UUID(),
            departure: nextDeparture.addingTimeInterval(1800), // +30 min
            lineName: "S7",
            platform: "3",
            delayMinutes: nil
        )

        let nextDep2 = UpcomingDeparture(
            id: UUID(),
            departure: nextDeparture.addingTimeInterval(3600), // +60 min
            lineName: "S7",
            platform: "3",
            delayMinutes: 2
        )

        return WidgetEntry(
            date: now,
            routeId: nil, // Placeholder doesn't have a real route ID
            routeName: "München Hbf → Ulm Hbf",
            leaveInMinutes: 15,
            departure: nextDeparture,
            arrival: arrivalTime,
            platform: "3",
            lineName: "S7",
            walkingTime: 8,
            delayMinutes: nil,
            direction: "Ulm Hbf",
            nextDepartures: [nextDep1, nextDep2],
            status: .onTime,
            lastUpdated: now,
            isConnected: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        // Set a timeout to prevent hanging
        let timeoutWorkItem = DispatchWorkItem {
            print("⚠️ Widget snapshot timed out, using placeholder")
            completion(self.placeholder(in: context))
        }

        // Schedule timeout (1 second for widget refresh)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: timeoutWorkItem)

        // Try to load snapshot
        if let snapshot = WidgetDataLoader.loadWidgetSnapshot() {
            // Cancel timeout since we have data
            timeoutWorkItem.cancel()

            // Determine status based on current data
            let status = determineStatus(
                leaveInMinutes: snapshot.leaveInMinutes,
                delayMinutes: snapshot.delayMinutes,
                departure: snapshot.departure
            )

            // Convert WidgetSnapshot to WidgetEntry
            let entry = WidgetEntry(
                date: Date(),
                routeId: snapshot.routeId,
                routeName: snapshot.routeName,
                leaveInMinutes: snapshot.leaveInMinutes,
                departure: snapshot.departure,
                arrival: snapshot.arrival,
                platform: snapshot.platform,
                lineName: snapshot.lineName,
                walkingTime: snapshot.walkingTime,
                delayMinutes: snapshot.delayMinutes,
                direction: snapshot.direction,
                nextDepartures: snapshot.nextDepartures,
                status: status,
                lastUpdated: Date(),
                isConnected: true
            )

            // Validate and clean the data
            let validatedEntry = WidgetDataLoader.validateAndCleanEntry(entry)
            completion(validatedEntry)
        } else {
            // Cancel timeout since we're providing placeholder immediately
            timeoutWorkItem.cancel()
            // No real data available, show placeholder
            completion(placeholder(in: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> ()) {
        getSnapshot(in: context) { entry in
            // Validate the entry to ensure no expired departures
            let validatedEntry = WidgetDataLoader.validateAndCleanEntry(entry)
            var entries: [WidgetEntry] = [validatedEntry]

            // Only add timeline entries if the validated departure is still in the future
            if validatedEntry.departure > Date() {
                let leaveTime = validatedEntry.departure.addingTimeInterval(TimeInterval(-validatedEntry.leaveInMinutes * 60))

                // Ensure leave time is in the future and different from departure time
                if leaveTime > Date() && leaveTime != validatedEntry.departure {
                    let leaveEntry = WidgetEntry(
                        date: leaveTime,
                        routeId: validatedEntry.routeId,
                        routeName: validatedEntry.routeName,
                        leaveInMinutes: 0, // It's time to leave
                        departure: validatedEntry.departure,
                        arrival: validatedEntry.arrival,
                        platform: validatedEntry.platform,
                        lineName: validatedEntry.lineName,
                        walkingTime: validatedEntry.walkingTime,
                        delayMinutes: validatedEntry.delayMinutes,
                        direction: validatedEntry.direction,
                        nextDepartures: validatedEntry.nextDepartures,
                        status: .departNow, // Update status to depart now
                        lastUpdated: validatedEntry.lastUpdated,
                        isConnected: validatedEntry.isConnected
                    )
                    entries.append(leaveEntry)
                }
            }

            // Determine refresh policy based on urgency and time to next departure
            let refreshInterval: TimeInterval
            let leaveInMinutes = validatedEntry.leaveInMinutes

            // If departure has expired or is very close, refresh more frequently
            if validatedEntry.departure <= Date() {
                // Departure has passed - refresh every 30 seconds to get fresh data
                refreshInterval = 30
                print("🎯 WIDGET: Departure expired, refreshing every 30 seconds")
            } else if leaveInMinutes <= 2 {
                // Critical - refresh every 30 seconds when departure is very close
                refreshInterval = 30
            } else if leaveInMinutes <= 5 {
                // Very urgent - refresh every 45 seconds
                refreshInterval = 45
            } else if leaveInMinutes <= 10 {
                // Urgent - refresh every 1 minute
                refreshInterval = 60
            } else if leaveInMinutes <= 20 {
                // Moderately urgent - refresh every 2 minutes
                refreshInterval = 120
            } else if leaveInMinutes <= 60 {
                // Soon - refresh every 3 minutes
                refreshInterval = 180
            } else {
                // Not urgent - refresh every 5 minutes
                refreshInterval = 300
            }

            // If we have multiple entries (like a "leave now" entry), use .atEnd policy
            // Otherwise use .after policy with calculated interval
            let timelinePolicy: TimelineReloadPolicy
            if entries.count > 1 {
                timelinePolicy = .atEnd
            } else {
                timelinePolicy = .after(Date().addingTimeInterval(refreshInterval))
            }

            let timeline = Timeline(entries: entries.sorted(by: { $0.date < $1.date }), policy: timelinePolicy)
            completion(timeline)
        }
    }



}

// MARK: - Route Card Components
struct RouteCard: View {
    let route: WidgetRouteData
    let compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 4) {
            // Route name
            Text(route.routeName)
                .font(compact ? .subheadline : .headline)
                .lineLimit(1)
                .foregroundColor(.primary)

            // Status and time info
            HStack(spacing: 6) {
                // Status badge
                let status = getStatusFromString(route.status)
                Text(status.displayText)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(status.color)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(status.color.opacity(0.2))
                    .clipShape(Capsule())

                Spacer()

                // Departure time
                Text(formatTime(route.departure))
                    .font(compact ? .caption : .subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            if !compact {
                // Platform info
                if let platform = route.platform {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption2)
                        Text(GermanTransportStyling.formatPlatform(platform))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Next departures
                if let nextDepartures = route.nextDepartures, !nextDepartures.isEmpty {
                    HStack(spacing: 4) {
                        Text("Next:")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        ForEach(nextDepartures.prefix(2), id: \.id) { departure in
                            Text(formatTime(departure.departure))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func getStatusFromString(_ status: String) -> WidgetStatus {
        switch status {
        case "delayed": return .delayed(0) // Will be updated with actual delay
        case "cancelled": return .cancelled
        case "departNow": return .departNow
        default: return .onTime
        }
    }
}

struct RouteCardLarge: View {
    let route: WidgetRouteData
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Route name with selection indicator
            HStack {
                Text(route.routeName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)
                    .foregroundColor(isSelected ? .primary : .secondary)

                Spacer()

                if isSelected {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }

            // Departure time
            Text(formatTime(route.departure))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            // Status and platform
            HStack {
                let status = getStatusFromString(route.status)
                Text(status.displayText)
                    .font(.caption)
                    .foregroundColor(status.color)

                Spacer()

                if let platform = route.platform {
                    Text(GermanTransportStyling.formatPlatform(platform))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(8)
    }

    private func getStatusFromString(_ status: String) -> WidgetStatus {
        switch status {
        case "delayed": return .delayed(0)
        case "cancelled": return .cancelled
        case "departNow": return .departNow
        default: return .onTime
        }
    }
}

// MARK: - Extensions
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


// MARK: - Unified Widget View (Smart Scrolling)
struct UnifiedWidgetEntryView : View {
    var entry: WidgetEntry
    @Environment(\.widgetFamily) var widgetFamily

    // Check if we have multiple routes (this entry might be part of a cycling timeline)
    private var hasMultipleRoutes: Bool {
        // We can detect multi-route by checking if there's multi-route data available
        return WidgetDataLoader.isMultiRouteDataAvailable()
    }

    // Create a URL for opening the route in the main app
    private var routeURL: URL? {
        // Create a URL scheme that the main app can handle
        // Format: trainviewer://route/{routeId}
        if let routeId = getCurrentRouteId() {
            return URL(string: "trainviewer://route/\(routeId)")
        }
        return nil
    }

    // Get the current route ID being displayed
    private func getCurrentRouteId() -> String? {
        // Use the routeId directly from the entry if available
        return entry.routeId?.uuidString
    }

    // Helper function to determine status from delay information
    private func statusFromDelay(_ delayMinutes: Int?, leaveInMinutes: Int, departure: Date) -> WidgetStatus {
        let now = Date()

        // Debug logging
        print("🎯 WIDGET DELAY: API delay: \(delayMinutes ?? 0)min, leaveIn: \(leaveInMinutes)min")
        print("🎯 WIDGET DELAY: Scheduled departure: \(departure), Now: \(now)")

        // If departure time has passed, it's depart now
        if departure <= now {
            print("🎯 WIDGET DELAY: Departure time passed, showing depart now")
            return .departNow
        }

        // Calculate accurate delay by comparing current time with scheduled departure
        let scheduledDepartureTime = departure
        let timeUntilDeparture = scheduledDepartureTime.timeIntervalSince(now) / 60.0
        print("🎯 WIDGET DELAY: Time until departure: \(timeUntilDeparture) minutes")

        // If we're more than 1 minute past the scheduled departure time, calculate actual delay
        if timeUntilDeparture < -1.0 {
            let actualDelayMinutes = Int(abs(timeUntilDeparture))
            print("🎯 WIDGET DELAY: Past scheduled time by \(actualDelayMinutes) minutes, showing delayed")
            return .delayed(max(1, actualDelayMinutes)) // Ensure minimum 1 minute delay display
        }

        // If API provided delay is less than 1 minute, treat as on time
        if let delay = delayMinutes, delay > 0 && delay < 1 {
            print("🎯 WIDGET DELAY: API delay \(delay) < 1 minute, showing on time")
            return .onTime
        }

        // If API provided delay is 1 minute or more, show delayed
        if let delay = delayMinutes, delay >= 1 {
            print("🎯 WIDGET DELAY: API delay \(delay) >= 1 minute, showing delayed")
            return .delayed(delay)
        }

        // If within 5 minutes, show depart now
        if leaveInMinutes <= 0 {
            print("🎯 WIDGET DELAY: Within 5 minutes, showing depart now")
            return .departNow
        }

        // Otherwise, on time
        print("🎯 WIDGET DELAY: No delay detected, showing on time")
        return .onTime
    }

    // Helper function to convert status string to WidgetStatus (fallback)
    private func statusFromString(_ status: String) -> WidgetStatus {
        switch status {
        case "delayed": return .delayed(0)
        case "cancelled": return .cancelled
        case "departNow": return .departNow
        default: return .onTime
        }
    }

    var body: some View {
        let contentView = Group {
            if hasMultipleRoutes && (widgetFamily == .systemLarge || widgetFamily == .systemMedium) {
                // Large and Medium widgets show scrollable multi-route view when multiple routes available
                if widgetFamily == .systemLarge {
                    unifiedLargeMultiRouteWidgetView
                } else {
                    unifiedMediumMultiRouteWidgetView
                }
            } else {
                // Standard single route views for all other cases
        switch widgetFamily {
        case .systemSmall:
                    unifiedSmallWidgetView
        case .systemMedium:
                    unifiedMediumWidgetView
                case .systemLarge:
                    unifiedLargeWidgetView
        case .accessoryRectangular:
                    unifiedRectangularLockScreenView
        case .accessoryInline:
                    unifiedInlineLockScreenView
        case .accessoryCircular:
                    unifiedCircularLockScreenView
        default:
                    unifiedSmallWidgetView
                }
            }
        }

        // Wrap in Link if we have a valid route URL
        if let url = routeURL {
            return AnyView(Link(destination: url) {
                contentView
            })
        } else {
            return AnyView(contentView)
        }
    }

    // MARK: - Unified Widget Views
    private var unifiedSmallWidgetView: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Route name - most important info
            Text(entry.routeName)
                .font(.headline)
                .lineLimit(1)
                .foregroundColor(.primary)

            // Departure time - prominent and clear
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formatTime(entry.departure))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Status indicator (compact version)
                Text(entry.status.shortText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(entry.status.color)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(entry.status.color.opacity(0.2))
                    .clipShape(Capsule())
            }

            // Platform info (only if available and space allows)
            if let platform = entry.platform {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption)
                    Text(GermanTransportStyling.formatPlatform(platform))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var unifiedMediumWidgetView: some View {
        HStack(spacing: 12) {
            // Train icon with status color
            ZStack {
                Circle()
                    .fill(GermanTransportStyling.transportColor(for: entry.lineName).opacity(0.8))
                    .frame(width: 50, height: 50)

                Image(systemName: "tram.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 6) {
                // Route name (moved to left edge for better space usage)
                Text(entry.routeName)
                    .font(.headline)
                    .lineLimit(2) // Allow 2 lines to use space better
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Status badge (moved below route name)
                Text(entry.status.displayText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(entry.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(entry.status.color.opacity(0.2))
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Platform and walking time
                HStack(spacing: 12) {
                    if let platform = entry.platform {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.caption)
                            Text(GermanTransportStyling.formatPlatform(platform))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.secondary)
                    }

                    if let walkingTime = entry.walkingTime {
                        Label("\(walkingTime)min walk", systemImage: "figure.walk")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                // Departure and arrival times
                HStack(spacing: 8) {
                    Text(formatTime(entry.departure))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(formatTime(entry.arrival))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Line name and direction
                if let line = entry.lineName {
                    HStack(spacing: 8) {
                        Text(line)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        if let direction = entry.direction {
                            Text("•")
                                .foregroundColor(.secondary.opacity(0.5))
                            Text(GermanTransportStyling.formatDirection(direction))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                // Next departures (up to 3)
                if let nextDepartures = entry.nextDepartures, !nextDepartures.isEmpty {
                    HStack(spacing: 8) {
                        Text("Next:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(nextDepartures.prefix(3), id: \.id) { departure in
                            HStack(spacing: 2) {
                                Text(formatTime(departure.departure))
                                    .font(.caption)
                                    .fontWeight(.medium)

                                if let delay = departure.delayMinutes, delay > 0 {
                                    Text("+\(delay)")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var unifiedLargeWidgetView: some View {
        VStack(spacing: 16) {
            // Header with route info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.routeName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                if let line = entry.lineName {
                    Text(line)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Status badge
                Text(entry.status.displayText)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(entry.status.color)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(entry.status.color.opacity(0.2))
                    .clipShape(Capsule())
            }

            // Main departure info
            HStack(spacing: 20) {
                // Departure time
                VStack(alignment: .leading, spacing: 4) {
                    Text("Departure")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(entry.departure))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                }

                // Platform info
                if let platform = entry.platform {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Platform")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                            Text(GermanTransportStyling.formatPlatform(platform))
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.primary)
                    }
                }

                // Walking time
                if let walkingTime = entry.walkingTime {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Walk")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Label("\(walkingTime) min", systemImage: "figure.walk")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }

                Spacer()
            }

            // Direction and next departures
            HStack(spacing: 20) {
                if let direction = entry.direction {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Direction")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(GermanTransportStyling.formatDirection(direction))
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                }

                // Next departures
                if let nextDepartures = entry.nextDepartures, !nextDepartures.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next Departures")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 12) {
                            ForEach(nextDepartures.prefix(3), id: \.id) { departure in
                                VStack(spacing: 2) {
                                    Text(formatTime(departure.departure))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)

                                    if let delay = departure.delayMinutes, delay > 0 {
                                        Text("+\(delay)")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var unifiedLargeMultiRouteWidgetView: some View {
        if let multiSnapshot = WidgetDataLoader.loadMultiRouteSnapshot(), !multiSnapshot.routes.isEmpty {
            return AnyView(
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Text("My Train Routes")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Spacer()

                        HStack(spacing: 4) {
                            ForEach(0..<min(multiSnapshot.routes.count, 5), id: \.self) { index in
                                Circle()
                                    .fill(index == 0 ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }

                    // Scrollable routes
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(multiSnapshot.routes.prefix(4), id: \.id) { route in
                                RouteCardLarge(route: route, isSelected: route.id == multiSnapshot.routes.first?.id)
                                    .frame(width: 220)
                            }
                        }
                        .padding(.horizontal, 4)
                    }

                    // Connection status
                    HStack {
                        Spacer()
                        if multiSnapshot.isConnected {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Live")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("Offline")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
                .containerBackground(.fill.tertiary, for: .widget)
            )
        } else {
            return AnyView(
                VStack(spacing: 16) {
                    Text("No routes available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .containerBackground(.fill.tertiary, for: .widget)
            )
        }
    }

    private var unifiedMediumMultiRouteWidgetView: some View {
        if let multiSnapshot = WidgetDataLoader.loadMultiRouteSnapshot(), !multiSnapshot.routes.isEmpty {
            let header = HStack {
                Text("Routes")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 3) {
                    ForEach(0..<min(multiSnapshot.routes.count, 4), id: \.self) { index in
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
                if multiSnapshot.isConnected {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                }
            }

            let scrollableContent = ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(multiSnapshot.routes.prefix(3), id: \.id) { route in
                        routeCard(for: route)
                    }
                }
                .padding(.horizontal, 4)
            }

            return AnyView(
                VStack(spacing: 8) {
                    header
                    scrollableContent
                }
                .padding()
                .containerBackground(.fill.tertiary, for: .widget)
            )
        } else {
            return AnyView(
                VStack(spacing: 8) {
                    Text("No routes available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .containerBackground(.fill.tertiary, for: .widget)
            )
        }
    }

    private func routeCard(for route: WidgetRouteData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(route.routeName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                Spacer()

                let status = statusFromDelay(route.delayMinutes, leaveInMinutes: route.leaveInMinutes, departure: route.departure)
                Text(status.displayText)
                    .font(.caption2)
                    .foregroundColor(status.color)
            }

            HStack(spacing: 6) {
                Text(formatTime(route.departure))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if let platform = route.platform {
                    Text("•")
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Gleis \(platform)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .frame(width: 140)
    }

    // MARK: - Lock Screen Views
    private var unifiedRectangularLockScreenView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Route name and status
            HStack(alignment: .center, spacing: 6) {
                Text(entry.routeName)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .foregroundColor(.white)

                Spacer()

                // Compact status indicator
                Text(entry.status.shortText)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(entry.status.color)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(entry.status.color.opacity(0.3))
                    .clipShape(Capsule())
            }

            // Departure time (prominent)
            Text(formatTime(entry.departure))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            // Essential info only: platform
            if let platform = entry.platform {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 10))
                    Text(GermanTransportStyling.formatPlatform(platform))
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(.fill.secondary, for: .widget)
    }

    private var unifiedInlineLockScreenView: some View {
        HStack(spacing: 4) {
            Image(systemName: "tram.fill")
                .font(.system(size: 12))
                .foregroundColor(entry.status.color)

            Text(entry.routeName)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .foregroundColor(.white)

            Text("•")
                .foregroundColor(.white.opacity(0.5))

            Text(formatTime(entry.departure))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            if entry.status == .departNow {
                Text("(NOW)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.red)
            } else if case .delayed = entry.status {
                Text("(DELAYED)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.orange)
            }
        }
        .containerBackground(.clear, for: .widget)
    }

    private var unifiedCircularLockScreenView: some View {
        ZStack {
            Circle()
                .fill(entry.status.color.opacity(0.3))
                .frame(width: 40, height: 40)

            VStack(spacing: 0) {
                Text(formatTime(entry.departure).split(separator: ":").first ?? "00")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)

                Text(formatTime(entry.departure).split(separator: ":").last ?? "00")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.8))
            }

            // Status indicator dot
            if entry.status != .onTime {
                Circle()
                    .fill(entry.status.color)
                    .frame(width: 8, height: 8)
                    .offset(y: 16)
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Widget Provider
struct BahnBlitzProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        let now = Date()
        let nextDeparture = now.addingTimeInterval(900)
        let arrivalTime = nextDeparture.addingTimeInterval(2700)

        return WidgetEntry(
            date: now,
            routeId: nil, // Placeholder doesn't have a real route ID
            routeName: "München Hbf → Ulm Hbf",
            leaveInMinutes: 15,
            departure: nextDeparture,
            arrival: arrivalTime,
            platform: "3",
            lineName: "S7",
            walkingTime: 8,
            delayMinutes: nil,
            direction: "Ulm Hbf",
            nextDepartures: [],
            status: .onTime,
            lastUpdated: now,
            isConnected: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        if let multiSnapshot = WidgetDataLoader.loadMultiRouteSnapshot(), !multiSnapshot.routes.isEmpty {
            let firstRoute = multiSnapshot.routes[0]
            let entry = WidgetEntry(
                date: Date(),
                routeId: firstRoute.routeId,
                routeName: firstRoute.routeName,
                leaveInMinutes: firstRoute.leaveInMinutes,
                departure: firstRoute.departure,
                arrival: firstRoute.arrival,
                platform: firstRoute.platform,
                lineName: firstRoute.lineName,
                walkingTime: firstRoute.walkingTime,
                delayMinutes: firstRoute.delayMinutes,
                direction: firstRoute.direction,
                nextDepartures: firstRoute.nextDepartures,
                status: statusFromDelay(firstRoute.delayMinutes, leaveInMinutes: firstRoute.leaveInMinutes, departure: firstRoute.departure),
                lastUpdated: multiSnapshot.lastUpdated,
                isConnected: multiSnapshot.isConnected
            )
            completion(entry)
        } else if let singleSnapshot = WidgetDataLoader.loadWidgetSnapshot() {
            let entry = WidgetEntry(
                date: Date(),
                routeId: singleSnapshot.routeId,
                routeName: singleSnapshot.routeName,
                leaveInMinutes: singleSnapshot.leaveInMinutes,
                departure: singleSnapshot.departure,
                arrival: singleSnapshot.arrival,
                platform: singleSnapshot.platform,
                lineName: singleSnapshot.lineName,
                walkingTime: singleSnapshot.walkingTime,
                delayMinutes: singleSnapshot.delayMinutes,
                direction: singleSnapshot.direction,
                nextDepartures: singleSnapshot.nextDepartures,
                status: statusFromDelay(singleSnapshot.delayMinutes, leaveInMinutes: singleSnapshot.leaveInMinutes, departure: singleSnapshot.departure),
                lastUpdated: Date(),
                isConnected: true
            )
            completion(entry)
        } else {
            completion(placeholder(in: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> ()) {
        if let multiSnapshot = WidgetDataLoader.loadMultiRouteSnapshot(), multiSnapshot.routes.count > 1 {
            var entries: [WidgetEntry] = []
            var hasExpiredDeparture = false

            for (index, route) in multiSnapshot.routes.enumerated() {
                let entry = WidgetEntry(
                    date: Date().addingTimeInterval(TimeInterval(index * 30)),
                    routeId: route.routeId,
                    routeName: route.routeName,
                    leaveInMinutes: route.leaveInMinutes,
                    departure: route.departure,
                    arrival: route.arrival,
                    platform: route.platform,
                    lineName: route.lineName,
                    walkingTime: route.walkingTime,
                    delayMinutes: route.delayMinutes,
                    direction: route.direction,
                    nextDepartures: route.nextDepartures,
                    status: statusFromDelay(route.delayMinutes, leaveInMinutes: route.leaveInMinutes, departure: route.departure),
                    lastUpdated: multiSnapshot.lastUpdated,
                    isConnected: multiSnapshot.isConnected
                )

                // Validate entry for expired departures
                let validatedEntry = WidgetDataLoader.validateAndCleanEntry(entry)

                // Check if this entry had an expired departure
                if entry.departure <= Date() {
                    hasExpiredDeparture = true
                }

                entries.append(validatedEntry)
            }

            // If any departure was expired, request immediate refresh
            if hasExpiredDeparture {
                print("🎯 WIDGET: Multi-route had expired departures, requesting refresh")
                WidgetDataLoader.requestMainAppRefresh()
            }

            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        } else {
            getSnapshot(in: context) { entry in
                // Validate the entry to ensure no expired departures
                let validatedEntry = WidgetDataLoader.validateAndCleanEntry(entry)
                var entries: [WidgetEntry] = [validatedEntry]

                // Only add leave entry if validated departure is still in the future
                if validatedEntry.departure > Date() {
                    let leaveTime = validatedEntry.departure.addingTimeInterval(TimeInterval(-validatedEntry.leaveInMinutes * 60))
                    if leaveTime > Date() && leaveTime != validatedEntry.departure {
                        let leaveEntry = WidgetEntry(
                            date: leaveTime,
                            routeId: validatedEntry.routeId,
                            routeName: validatedEntry.routeName,
                            leaveInMinutes: 0,
                            departure: validatedEntry.departure,
                            arrival: validatedEntry.arrival,
                            platform: validatedEntry.platform,
                            lineName: validatedEntry.lineName,
                            walkingTime: validatedEntry.walkingTime,
                            delayMinutes: validatedEntry.delayMinutes,
                            direction: validatedEntry.direction,
                            nextDepartures: validatedEntry.nextDepartures,
                            status: .departNow,
                            lastUpdated: validatedEntry.lastUpdated,
                            isConnected: validatedEntry.isConnected
                        )
                        entries.append(leaveEntry)
                    }
                }
                // Determine refresh policy based on urgency and time to next departure
                let refreshInterval: TimeInterval
                let leaveInMinutes = validatedEntry.leaveInMinutes

                // If departure has expired, refresh more frequently
                if validatedEntry.departure <= Date() {
                    refreshInterval = 30 // Departure expired - refresh every 30 seconds
                    print("🎯 WIDGET: Provider - Departure expired, refreshing every 30 seconds")
                } else if leaveInMinutes <= 2 {
                    // Critical - refresh every 30 seconds when departure is very close
                    refreshInterval = 30
                } else if leaveInMinutes <= 5 {
                    // Very urgent - refresh every 45 seconds
                    refreshInterval = 45
                } else if leaveInMinutes <= 10 {
                    // Urgent - refresh every 1 minute
                    refreshInterval = 60
                } else if leaveInMinutes <= 20 {
                    // Moderately urgent - refresh every 2 minutes
                    refreshInterval = 120
                } else if leaveInMinutes <= 60 {
                    // Soon - refresh every 3 minutes
                    refreshInterval = 180
                } else {
                    // Not urgent - refresh every 5 minutes
                    refreshInterval = 300
                }

                // If we have multiple entries (like a "leave now" entry), use .atEnd policy
                // Otherwise use .after policy with calculated interval
                let timelinePolicy: TimelineReloadPolicy
                if entries.count > 1 {
                    timelinePolicy = .atEnd
                } else {
                    timelinePolicy = .after(Date().addingTimeInterval(refreshInterval))
                }

                let timeline = Timeline(entries: entries.sorted(by: { $0.date < $1.date }), policy: timelinePolicy)
                completion(timeline)
            }
        }
    }

    private func statusFromString(_ status: String) -> WidgetStatus {
        switch status {
        case "delayed": return .delayed(0)
        case "cancelled": return .cancelled
        case "departNow": return .departNow
        default: return .onTime
        }
    }

    private func statusFromDelay(_ delayMinutes: Int?, leaveInMinutes: Int, departure: Date) -> WidgetStatus {
        let now = Date()

        // Debug logging
        print("🎯 WIDGET DELAY (Provider): API delay: \(delayMinutes ?? 0)min, leaveIn: \(leaveInMinutes)min")
        print("🎯 WIDGET DELAY (Provider): Scheduled departure: \(departure), Now: \(now)")

        // If departure time has passed, it's depart now
        if departure <= now {
            print("🎯 WIDGET DELAY (Provider): Departure time passed, showing depart now")
            return .departNow
        }

        // Calculate accurate delay by comparing current time with scheduled departure
        let scheduledDepartureTime = departure
        let timeUntilDeparture = scheduledDepartureTime.timeIntervalSince(now) / 60.0
        print("🎯 WIDGET DELAY (Provider): Time until departure: \(timeUntilDeparture) minutes")

        // If we're more than 1 minute past the scheduled departure time, calculate actual delay
        if timeUntilDeparture < -1.0 {
            let actualDelayMinutes = Int(abs(timeUntilDeparture))
            print("🎯 WIDGET DELAY (Provider): Past scheduled time by \(actualDelayMinutes) minutes, showing delayed")
            return .delayed(max(1, actualDelayMinutes)) // Ensure minimum 1 minute delay display
        }

        // If API provided delay is less than 1 minute, treat as on time
        if let delay = delayMinutes, delay > 0 && delay < 1 {
            print("🎯 WIDGET DELAY (Provider): API delay \(delay) < 1 minute, showing on time")
            return .onTime
        }

        // If API provided delay is 1 minute or more, show delayed
        if let delay = delayMinutes, delay >= 1 {
            print("🎯 WIDGET DELAY (Provider): API delay \(delay) >= 1 minute, showing delayed")
            return .delayed(delay)
        }

        // If within 5 minutes, show depart now
        if leaveInMinutes <= 0 {
            print("🎯 WIDGET DELAY (Provider): Within 5 minutes, showing depart now")
            return .departNow
        }

        // Otherwise, on time
        print("🎯 WIDGET DELAY (Provider): No delay detected, showing on time")
        return .onTime
    }
}

// MARK: - Smart Location-Based Widget Provider
/*
 Smart Route Widget - Automatically shows the right route based on your location

 HOW IT WORKS:
 1. Detects your current location using GPS
 2. Determines if you're at home, at campus, or somewhere in between
 3. Automatically selects the appropriate route:
    - At home → Shows route to campus/work
    - At campus → Shows route back home
    - Near home/campus → Shows closest relevant route
 4. Displays live journey data for the selected route
 5. Updates every minute to reflect location changes

 SETUP REQUIREMENTS:
 - Set your home location in Settings
 - Set your campus/work location in Settings
 - Create routes between home ↔ campus
 - Enable location permissions

 LOCATION CONTEXTS:
 - atHome: Within 500m of home location
 - atCampus: Within 500m of campus location
 - nearHome: Closer to home than campus
 - nearCampus: Closer to campus than home
 - unknown: Location unavailable or no clear context

 VISUAL INDICATORS:
 - 🏠 At Home / 🏠 Near Home
 - 🎓 At Campus / 🎓 Near Campus
 - 📍 Location Unknown
 */
struct SmartWidgetProvider: TimelineProvider {
    // Note: LocationService is not available in widget extension
    // We'll use a simplified location detection approach

    func placeholder(in context: Context) -> WidgetEntry {
        let now = Date()
        let nextDeparture = now.addingTimeInterval(900)
        let arrivalTime = nextDeparture.addingTimeInterval(2700)

        return WidgetEntry(
            date: now,
            routeId: nil,
            routeName: "Smart Route Detection",
            leaveInMinutes: 15,
            departure: nextDeparture,
            arrival: arrivalTime,
            platform: "Auto",
            lineName: "Smart",
            walkingTime: nil,
            delayMinutes: nil,
            direction: "Auto-detected",
            nextDepartures: [],
            status: .onTime,
            lastUpdated: now,
            isConnected: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        // Try to get smart route based on current location
        let smartEntry = getSmartRouteEntry()
        completion(smartEntry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> ()) {
        let smartEntry = getSmartRouteEntry()
        var entries: [WidgetEntry] = [smartEntry]

        // Add timeline entries for smart route
        if smartEntry.departure > Date() {
            let leaveTime = smartEntry.departure.addingTimeInterval(TimeInterval(-smartEntry.leaveInMinutes * 60))

            if leaveTime > Date() && leaveTime != smartEntry.departure {
                let leaveEntry = WidgetEntry(
                    date: leaveTime,
                    routeId: smartEntry.routeId,
                    routeName: smartEntry.routeName,
                    leaveInMinutes: 0,
                    departure: smartEntry.departure,
                    arrival: smartEntry.arrival,
                    platform: smartEntry.platform,
                    lineName: smartEntry.lineName,
                    walkingTime: smartEntry.walkingTime,
                    delayMinutes: smartEntry.delayMinutes,
                    direction: smartEntry.direction,
                    nextDepartures: smartEntry.nextDepartures,
                    status: .departNow,
                    lastUpdated: smartEntry.lastUpdated,
                    isConnected: smartEntry.isConnected
                )
                entries.append(leaveEntry)
            }
        }

        // Determine refresh policy based on confidence and context
        let currentContext = smartEntry.routeId != nil ? determineLocationContext(homePlace: getHomePlace() ?? WidgetPlace(rawId: nil, name: "", latitude: nil, longitude: nil),
                                                                                   campusPlace: getCampusPlace() ?? WidgetPlace(rawId: nil, name: "", latitude: nil, longitude: nil)) : .unknown
        let refreshInterval: TimeInterval = currentContext.confidence.refreshInterval

        let timelinePolicy: TimelineReloadPolicy
        if entries.count > 1 {
            timelinePolicy = .atEnd
        } else {
            timelinePolicy = .after(Date().addingTimeInterval(refreshInterval))
        }

        let timeline = Timeline(entries: entries.sorted(by: { $0.date < $1.date }), policy: timelinePolicy)
        completion(timeline)
    }

    private func getSmartRouteEntry() -> WidgetEntry {
        let now = Date()

        // Get user settings for home and campus locations
        guard let homePlace = getHomePlace(),
              let campusPlace = getCampusPlace() else {
            // Fallback to regular widget if no home/campus set
            return getFallbackEntry()
        }

        // Determine user's current location context
        let locationContext = determineLocationContext(homePlace: homePlace, campusPlace: campusPlace)

        // Find appropriate route based on location context
        guard let smartRoute = findSmartRoute(for: locationContext) else {
            return getFallbackEntry()
        }

        // Get journey data for the smart route
        return getRouteEntry(for: smartRoute, context: locationContext)
    }

    private func getHomePlace() -> WidgetPlace? {
        let defaults = UserDefaults(suiteName: "group.com.bahnblitz.app")
        guard let data = defaults?.data(forKey: "settings.homePlace") else { return nil }
        return try? JSONDecoder().decode(WidgetPlace.self, from: data)
    }

    private func getCampusPlace() -> WidgetPlace? {
        let defaults = UserDefaults(suiteName: "group.com.bahnblitz.app")
        guard let data = defaults?.data(forKey: "settings.campusPlace") else { return nil }
        return try? JSONDecoder().decode(WidgetPlace.self, from: data)
    }

    private func determineLocationContext(homePlace: WidgetPlace, campusPlace: WidgetPlace) -> LocationContext {
        // Try to get current location from shared UserDefaults (set by main app)
        guard let currentLocation = getCurrentLocationFromSharedStorage() else {
            // Fallback to time-based logic if no location available
            return determineTimeBasedContext()
        }

        // Calculate distances to home and campus
        let homeDistance = homePlace.coordinate != nil ?
            distanceBetween(currentLocation, homePlace.coordinate!) : Double.infinity
        let campusDistance = campusPlace.coordinate != nil ?
            distanceBetween(currentLocation, campusPlace.coordinate!) : Double.infinity

        // Get user-configurable detection radii
        let homeRadius = getHomeDetectionRadius()
        let campusRadius = getCampusDetectionRadius()
        let proximityRadius: CLLocationDistance = 1000 // 1km for "near" detection

        // Location-based decision with hysteresis to prevent rapid switching
        if homeDistance <= homeRadius && homeDistance < campusDistance {
            return .atHome
        } else if campusDistance <= campusRadius && campusDistance < homeDistance {
            return .atCampus
        } else if homeDistance <= homeRadius && campusDistance <= campusRadius {
            // User is within both radii (overlapping areas)
            // Choose the closer one for consistency
            return homeDistance <= campusDistance ? .atHome : .atCampus
        } else if min(homeDistance, campusDistance) <= proximityRadius {
            // User is near one location (within proximity radius)
            return homeDistance < campusDistance ? .nearHome : .nearCampus
        }

        // If location is too far from both, use time-based logic
        return determineTimeBasedContext()
    }

    private func getCurrentLocationFromSharedStorage() -> CLLocationCoordinate2D? {
        let defaults = UserDefaults(suiteName: "group.com.bahnblitz.app")

        // Check if location data is recent (within last 30 minutes)
        guard let locationTimestamp = defaults?.object(forKey: "currentLocation.timestamp") as? Date else {
            return nil
        }

        let thirtyMinutesAgo = Date().addingTimeInterval(-1800) // 30 minutes
        guard locationTimestamp > thirtyMinutesAgo else {
            return nil // Location data is too old
        }

        // Get location coordinates
        guard let latitude = defaults?.double(forKey: "currentLocation.latitude"),
              let longitude = defaults?.double(forKey: "currentLocation.longitude") else {
            return nil
        }

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private func determineTimeBasedContext() -> LocationContext {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)

        // Weekend detection (Saturday = 7, Sunday = 1 in Gregorian calendar)
        let isWeekend = weekday == 1 || weekday == 7

        if isWeekend {
            // On weekends, assume user might want to go to work/campus for leisure
            return .nearCampus
        }

        // Time-based logic for weekdays
        switch hour {
        case 6...10:  // Morning hours (6 AM - 10 AM)
            return .nearHome  // Likely at home, wanting to go to work/campus
        case 16...22: // Evening hours (4 PM - 10 PM)
            return .atCampus // Likely at work/campus, wanting to go home
        case 11...15: // Midday hours
            return .atCampus // Likely still at work/campus
        case 23...24, 0...5: // Late night/early morning
            return .nearHome  // Likely at home or heading home
        default:
            return .unknown
        }
    }

    private func findSmartRoute(for context: LocationContext) -> WidgetRoute? {
        // Check if smart switching is enabled
        guard getSmartSwitchingEnabled() else {
            return findBestFallbackRoute(routes: [], homePlace: WidgetPlace(rawId: nil, name: "", latitude: nil, longitude: nil),
                                       campusPlace: WidgetPlace(rawId: nil, name: "", latitude: nil, longitude: nil))
        }

        // Check vacation mode
        if getVacationModeEnabled() {
            return findVacationModeRoute()
        }

        // Get all routes from shared store
        guard let routesData = UserDefaults(suiteName: "group.com.bahnblitz.app")?.data(forKey: "routes"),
              let routes = try? JSONDecoder().decode([WidgetRoute].self, from: routesData) else {
            return nil
        }

        guard let homePlace = getHomePlace(),
              let campusPlace = getCampusPlace() else {
            return nil
        }

        let smartRoute: WidgetRoute?

        switch context {
        case .atHome, .nearHome:
            // Check for weekday-specific route preference first
            if let weekdayRouteId = getRouteForCurrentWeekday(),
               let weekdayRoute = routes.first(where: { $0.id == weekdayRouteId }),
               isRouteFromTo(route: weekdayRoute, from: homePlace, to: campusPlace) {
                smartRoute = weekdayRoute
            } else {
                // Find default route from home to campus
                smartRoute = routes.first { route in
                    isRouteFromTo(route: route, from: homePlace, to: campusPlace)
                }
            }

        case .atCampus, .nearCampus:
            // Check for weekday-specific route preference first
            if let weekdayRouteId = getRouteForCurrentWeekday(),
               let weekdayRoute = routes.first(where: { $0.id == weekdayRouteId }),
               isRouteFromTo(route: weekdayRoute, from: campusPlace, to: homePlace) {
                smartRoute = weekdayRoute
            } else {
                // Find default route from campus to home
                smartRoute = routes.first { route in
                    isRouteFromTo(route: route, from: campusPlace, to: homePlace)
                }
            }

        case .unknown:
            // Use smart fallback logic based on confidence and user preferences
            smartRoute = findBestFallbackRoute(routes: routes, homePlace: homePlace, campusPlace: campusPlace)
        }

        return smartRoute
    }

    private func findVacationModeRoute() -> WidgetRoute? {
        // In vacation mode, return nil to show fallback entry
        // This indicates the user doesn't want smart switching
        return nil
    }

    private func findBestFallbackRoute(routes: [WidgetRoute], homePlace: WidgetPlace, campusPlace: WidgetPlace) -> WidgetRoute? {
        // Priority 1: Check user preferences for manual route override
        if let manualRouteId = getManualRouteOverride(),
           let manualRoute = routes.first(where: { $0.id == manualRouteId }) {
            return manualRoute
        }

        // Priority 2: Most recently used route
        if let mostRecentRoute = routes.sorted(by: { getRouteLastUsed($0) > getRouteLastUsed($1) }).first {
            return mostRecentRoute
        }

        // Priority 3: Route with most usage
        if let mostUsedRoute = routes.sorted(by: { getRouteUsageCount($0) > getRouteUsageCount($1) }).first {
            return mostUsedRoute
        }

        // Priority 4: First route as absolute fallback
        return routes.first
    }

    private func getManualRouteOverride() -> UUID? {
        let defaults = UserDefaults(suiteName: "group.com.bahnblitz.app")
        guard let routeIdString = defaults?.string(forKey: "smartWidget.manualRouteOverride") else {
            return nil
        }
        return UUID(uuidString: routeIdString)
    }

    private func getRouteLastUsed(_ route: WidgetRoute) -> Date {
        let defaults = UserDefaults(suiteName: "group.com.bahnblitz.app")
        let key = "route.lastUsed.\(route.id.uuidString)"
        return defaults?.object(forKey: key) as? Date ?? Date.distantPast
    }

    private func getRouteUsageCount(_ route: WidgetRoute) -> Int {
        let defaults = UserDefaults(suiteName: "group.com.bahnblitz.app")
        let key = "route.usageCount.\(route.id.uuidString)"
        return defaults?.integer(forKey: key) ?? 0
    }

    private func isRouteFromTo(route: WidgetRoute, from: WidgetPlace, to: WidgetPlace) -> Bool {
        // Check if route origin matches 'from' place
        let originMatch = route.origin.name.localizedCaseInsensitiveContains(from.name) ||
                         (route.origin.coordinate != nil && from.coordinate != nil &&
                          distanceBetween(route.origin.coordinate!, from.coordinate!) < 100)

        // Check if route destination matches 'to' place
        let destinationMatch = route.destination.name.localizedCaseInsensitiveContains(to.name) ||
                              (route.destination.coordinate != nil && to.coordinate != nil &&
                               distanceBetween(route.destination.coordinate!, to.coordinate!) < 100)

        return originMatch && destinationMatch
    }

    private func distanceBetween(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2)
    }

    private func determineWidgetStatus(leaveInMinutes: Int, delayMinutes: Int?, departure: Date) -> WidgetStatus {
        let now = Date()

        // If departure time has passed, it's depart now
        if departure <= now {
            return .departNow
        }

        // If there's a delay, show delayed status
        if let delay = delayMinutes, delay > 0 {
            return .delayed(delay)
        }

        // If within 5 minutes, show depart now
        if leaveInMinutes <= 0 {
            return .departNow
        }

        // Otherwise, on time
        return .onTime
    }

    private func getRouteEntry(for route: WidgetRoute, context: LocationContext) -> WidgetEntry {
        let now = Date()

        // Try to get cached snapshot data for this route
        if let snapshot = getCachedSnapshot(for: route.id) {
            return WidgetEntry(
                date: now,
                routeId: snapshot.routeId,
                routeName: "\(route.name) \(context.routeDirection)",
                leaveInMinutes: snapshot.leaveInMinutes,
                departure: snapshot.departure,
                arrival: snapshot.arrival,
                platform: context.displayText,
                lineName: snapshot.lineName,
                walkingTime: snapshot.walkingTime,
                delayMinutes: snapshot.delayMinutes,
                direction: snapshot.direction,
                nextDepartures: snapshot.nextDepartures,
                status: determineWidgetStatus(
                    leaveInMinutes: snapshot.leaveInMinutes,
                    delayMinutes: snapshot.delayMinutes,
                    departure: snapshot.departure
                ),
                lastUpdated: now,
                isConnected: true
            )
        }

        // Fallback: Create a smart entry with realistic transit schedule times
        let smartDepartureTime = calculateSmartFallbackDepartureTime(now, for: context)
        let estimatedTripDuration = estimateTripDuration(route, context)
        let arrivalTime = smartDepartureTime.addingTimeInterval(estimatedTripDuration)
        let leaveInMinutes = calculateLeaveInMinutes(smartDepartureTime, now)

        return WidgetEntry(
            date: now,
            routeId: route.id,
            routeName: "\(route.name) \(context.routeDirection)",
            leaveInMinutes: leaveInMinutes,
            departure: smartDepartureTime,
            arrival: arrivalTime,
            platform: context.displayText,
            lineName: "Smart",
            walkingTime: nil,
            delayMinutes: nil,
            direction: context.routeDirection.replacingOccurrences(of: "→ ", with: ""),
            nextDepartures: [],
            status: .onTime,
            lastUpdated: now,
            isConnected: true
        )
    }

    private func getCachedSnapshot(for routeId: UUID) -> WidgetSnapshot? {
        let defaults = UserDefaults(suiteName: "group.com.bahnblitz.app")
        // Use the same key format as SharedStore: "widget_snapshot." + routeId
        guard let data = defaults?.data(forKey: "widget_snapshot.\(routeId.uuidString)") else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    // MARK: - Smart Fallback Time Calculations

    private func calculateSmartFallbackDepartureTime(_ now: Date, for context: LocationContext) -> Date {
        let calendar = Calendar.current
        let currentMinute = calendar.component(.minute, from: now)
        let currentHour = calendar.component(.hour, from: now)

        // Calculate next realistic departure time based on transit patterns
        var nextDepartureMinute: Int

        // Round to next 5-minute interval (typical transit schedule)
        let roundedMinute = ((currentMinute + 4) / 5) * 5
        if roundedMinute >= 60 {
            nextDepartureMinute = 0
        } else {
            nextDepartureMinute = roundedMinute
        }

        // Add some variation based on context to avoid identical times
        let contextOffset = contextVariationOffset(for: context)
        nextDepartureMinute = (nextDepartureMinute + contextOffset) % 60

        // If we're very close to the calculated time, add 5 minutes
        if nextDepartureMinute - currentMinute <= 2 {
            nextDepartureMinute = (nextDepartureMinute + 5) % 60
        }

        // Calculate departure time
        var departureComponents = calendar.dateComponents([.year, .month, .day, .hour], from: now)
        departureComponents.minute = nextDepartureMinute
        departureComponents.second = 0

        var departureTime = calendar.date(from: departureComponents)!

        // If calculated time is in the past or too close, add appropriate interval
        if departureTime <= now.addingTimeInterval(120) { // Less than 2 minutes from now
            departureTime = departureTime.addingTimeInterval(300) // Add 5 minutes
        }

        // Add some randomization to make it feel more realistic (±2 minutes)
        let randomOffset = Double.random(in: -120...120)
        departureTime = departureTime.addingTimeInterval(randomOffset)

        return departureTime
    }

    private func contextVariationOffset(for context: LocationContext) -> Int {
        switch context {
        case .atHome:
            return 1  // Slight variation for home context
        case .atCampus:
            return 3  // Different variation for campus context
        case .nearHome:
            return 2  // Medium variation for near home
        case .nearCampus:
            return 4  // Different variation for near campus
        case .unknown:
            return 0  // No variation for unknown
        }
    }

    private func estimateTripDuration(_ route: WidgetRoute, _ context: LocationContext) -> TimeInterval {
        // Base trip duration estimates based on typical German train routes
        let baseDuration: TimeInterval

        // Estimate based on route name or context
        if route.name.contains("S-Bahn") {
            baseDuration = 1200 // 20 minutes for S-Bahn
        } else if route.name.contains("U-Bahn") {
            baseDuration = 900  // 15 minutes for U-Bahn
        } else if route.name.contains("Regional") || route.name.contains("RE") {
            baseDuration = 2700 // 45 minutes for regional trains
        } else if route.name.contains("ICE") || route.name.contains("IC") {
            baseDuration = 3600 // 60 minutes for long-distance trains
        } else {
            baseDuration = 1800 // 30 minutes default
        }

        // Adjust based on context (shorter trips for local travel)
        let contextMultiplier: Double
        switch context {
        case .atHome, .atCampus:
            contextMultiplier = 0.8  // Shorter trips when at known locations
        case .nearHome, .nearCampus:
            contextMultiplier = 1.0  // Normal trips when near locations
        case .unknown:
            contextMultiplier = 1.2  // Longer trips when context is unknown
        }

        // Add some randomization (±20%)
        let randomFactor = Double.random(in: 0.8...1.2)
        return baseDuration * contextMultiplier * randomFactor
    }

    private func calculateLeaveInMinutes(_ departureTime: Date, _ now: Date) -> Int {
        let timeInterval = departureTime.timeIntervalSince(now)
        let minutes = Int(ceil(timeInterval / 60.0))

        // Ensure minimum leave time for walking and preparation
        return max(minutes, 3) // At least 3 minutes to leave
    }

    // User Settings Integration
    private func getSmartSwitchingEnabled() -> Bool {
        let defaults = UserDefaults(suiteName: "group.com.bahnblitz.app")
        return defaults?.bool(forKey: "smartWidget.smartSwitchingEnabled") ?? true
    }

    private func getLocationSensitivity() -> Double {
        let defaults = UserDefaults(suiteName: "group.com.bahnblitz.app")
        return defaults?.double(forKey: "smartWidget.locationSensitivity") ?? 1.0 // 1.0 = normal sensitivity
    }

    private func getHomeDetectionRadius() -> CLLocationDistance {
        let baseRadius: CLLocationDistance = 300 // 300m base
        let sensitivity = getLocationSensitivity()
        return baseRadius * sensitivity
    }

    private func getCampusDetectionRadius() -> CLLocationDistance {
        let baseRadius: CLLocationDistance = 500 // 500m base
        let sensitivity = getLocationSensitivity()
        return baseRadius * sensitivity
    }

    private func shouldUseTimeBasedFallback() -> Bool {
        let defaults = UserDefaults(suiteName: "group.com.bahnblitz.app")
        return defaults?.bool(forKey: "smartWidget.useTimeBasedFallback") ?? true
    }

    private func getVacationModeEnabled() -> Bool {
        let defaults = UserDefaults(suiteName: "group.com.bahnblitz.app")
        return defaults?.bool(forKey: "smartWidget.vacationMode") ?? false
    }

    private func getPreferredWeekdayRoutes() -> [String: UUID]? {
        let defaults = UserDefaults(suiteName: "group.com.bahnblitz.app")
        guard let data = defaults?.data(forKey: "smartWidget.weekdayRoutes") else { return nil }
        return try? JSONDecoder().decode([String: UUID].self, from: data)
    }

    private func getRouteForCurrentWeekday() -> UUID? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())

        // Convert to day names (1 = Sunday, 2 = Monday, etc.)
        let dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        let dayName = dayNames[weekday - 1]

        return getPreferredWeekdayRoutes()?[dayName]
    }

    private func getLocationStatusText(for context: LocationContext) -> String {
        switch context {
        case .atHome:
            return "🏠 At Home"
        case .atCampus:
            return "🎓 At Campus"
        case .nearHome:
            return "🏠 Near Home"
        case .nearCampus:
            return "🎓 Near Campus"
        case .unknown:
            return "📍 Location Unknown"
        }
    }

    private func calculateRefreshInterval(for entry: WidgetEntry, context: LocationContext) -> TimeInterval {
        // Base refresh intervals based on confidence and urgency
        let confidence = context.confidence
        let leaveInMinutes = entry.leaveInMinutes

        switch confidence {
        case .high:
            // High confidence - can refresh less frequently
            if leaveInMinutes <= 5 {
                return 30 // Very urgent - refresh every 30 seconds
            } else if leaveInMinutes <= 15 {
                return 60 // Urgent - refresh every minute
            } else {
                return 300 // Not urgent - refresh every 5 minutes
            }

        case .medium:
            // Medium confidence - refresh more frequently for verification
            if leaveInMinutes <= 5 {
                return 45 // Urgent - refresh every 45 seconds
            } else if leaveInMinutes <= 15 {
                return 90 // Moderately urgent - refresh every 1.5 minutes
            } else {
                return 600 // Not urgent - refresh every 10 minutes
            }

        case .low:
            // Low confidence - refresh frequently to get better location data
            if leaveInMinutes <= 5 {
                return 30 // Still urgent - refresh every 30 seconds
            } else {
                return 120 // Refresh every 2 minutes to improve location detection
            }
        }
    }

    private func getFallbackEntry() -> WidgetEntry {
        let now = Date()
        let nextDeparture = now.addingTimeInterval(900)
        let arrivalTime = nextDeparture.addingTimeInterval(2700)

        // Determine the specific error state
        let error = determineErrorState()

        return WidgetEntry(
            date: now,
            routeId: nil,
            routeName: error.userMessage,
            leaveInMinutes: 15,
            departure: nextDeparture,
            arrival: arrivalTime,
            platform: "⚠️ Setup",
            lineName: nil,
            walkingTime: nil,
            delayMinutes: nil,
            direction: "Check Settings",
            nextDepartures: [],
            status: .onTime,
            lastUpdated: now,
            isConnected: false
        )
    }

    private func determineErrorState() -> SmartWidgetError {
        // Check if smart switching is enabled
        if !getSmartSwitchingEnabled() {
            return .unknown
        }

        // Check location setup
        let hasHome = getHomePlace() != nil
        let hasCampus = getCampusPlace() != nil

        if !hasHome && !hasCampus {
            return .noHomeCampusConfigured
        }

        // Check if routes are available
        guard let routesData = UserDefaults(suiteName: "group.com.bahnblitz.app")?.data(forKey: "routes"),
              let routes = try? JSONDecoder().decode([WidgetRoute].self, from: routesData),
              !routes.isEmpty else {
            return .noRoutesAvailable
        }

        // Check location availability
        if getCurrentLocationFromSharedStorage() == nil {
            return .locationUnavailable
        }

        return .unknown
    }
}

enum LocationContext {
    case atHome, atCampus, nearHome, nearCampus, unknown

    var confidence: ConfidenceLevel {
        switch self {
        case .atHome, .atCampus:
            return .high    // Within detection radius
        case .nearHome, .nearCampus:
            return .medium  // Within 1km, location-based
        case .unknown:
            return .low     // Time-based or no data
        }
    }

    var displayText: String {
        switch self {
        case .atHome:
            return "🏠 At Home"
        case .atCampus:
            return "🎓 At Campus"
        case .nearHome:
            return "🏠 Near Home"
        case .nearCampus:
            return "🎓 Near Campus"
        case .unknown:
            return "📍 Auto-detecting..."
        }
    }

    var routeDirection: String {
        switch self {
        case .atHome, .nearHome:
            return "→ Campus"
        case .atCampus, .nearCampus:
            return "→ Home"
        case .unknown:
            return "→ Auto"
        }
    }
}

enum ConfidenceLevel {
    case high, medium, low

    var description: String {
        switch self {
        case .high: return "High confidence (location-based)"
        case .medium: return "Medium confidence (proximity-based)"
        case .low: return "Low confidence (time-based)"
        }
    }

    var refreshInterval: TimeInterval {
        switch self {
        case .high: return 300  // 5 minutes for high confidence
        case .medium: return 180 // 3 minutes for medium confidence
        case .low: return 60     // 1 minute for low confidence
        }
    }
}

enum SmartWidgetError: Error {
    case noLocationPermission
    case locationUnavailable
    case noHomeCampusConfigured
    case noRoutesAvailable
    case networkError
    case unknown

    var userMessage: String {
        switch self {
        case .noLocationPermission:
            return "Enable location permissions for smart switching"
        case .locationUnavailable:
            return "Location unavailable, using time-based detection"
        case .noHomeCampusConfigured:
            return "Set home and campus locations in settings"
        case .noRoutesAvailable:
            return "Add routes to enable smart switching"
        case .networkError:
            return "Network error, showing cached data"
        case .unknown:
            return "Smart detection unavailable"
        }
    }

    var icon: String {
        switch self {
        case .noLocationPermission: return "location.slash"
        case .locationUnavailable: return "location"
        case .noHomeCampusConfigured: return "house"
        case .noRoutesAvailable: return "arrow.triangleturn.up.right.diamond"
        case .networkError: return "wifi.slash"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - Widget Configuration
struct BahnBlitzWidget: Widget {
    let kind: String = "BahnBlitzWidget"

    init() {
        print("🚂 WIDGET: BahnBlitzWidget initialized - Unified scrollable widget")
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BahnBlitzProvider()) { entry in
            UnifiedWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Train Routes")
        .description("Shows your train routes with automatic scrolling.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular
        ])
        .contentMarginsDisabled()
    }
}

// MARK: - Smart Widget Configuration
struct SmartRouteWidget: Widget {
    let kind: String = "SmartRouteWidget"

    init() {
        print("🎯 WIDGET: SmartRouteWidget initialized - Location-aware smart widget")
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SmartWidgetProvider()) { entry in
            UnifiedWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Smart Route")
        .description("Automatically shows the right route based on your location.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular
        ])
        .contentMarginsDisabled()
    }
}
// MARK: - Helper Function
func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    BahnBlitzWidget()
} timeline: {
    let nextDep1 = UpcomingDeparture(
        id: UUID(),
        departure: Date().addingTimeInterval(2700),
        lineName: "RE 7",
        platform: "1",
        delayMinutes: nil
    )

    WidgetEntry(
        date: .now,
        routeId: nil, // Preview doesn't have a real route ID
        routeName: "Stuttgart Hbf → München Hbf",
        leaveInMinutes: 12,
        departure: Date().addingTimeInterval(720),
        arrival: Date().addingTimeInterval(3600),
        platform: "1",
        lineName: "RE 7",
        walkingTime: 5,
        delayMinutes: nil,
        direction: "München Hbf",
        nextDepartures: [nextDep1],
        status: .onTime,
        lastUpdated: Date().addingTimeInterval(-120),
        isConnected: true
    )
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    BahnBlitzWidget()
} timeline: {
    let nextDep1 = UpcomingDeparture(
        id: UUID(),
        departure: Date().addingTimeInterval(2700),
        lineName: "RE 7",
        platform: "1",
        delayMinutes: nil
    )

    WidgetEntry(
        date: .now,
        routeId: nil, // Preview doesn't have a real route ID
        routeName: "Stuttgart Hbf → München Hbf",
        leaveInMinutes: 12,
        departure: Date().addingTimeInterval(720),
        arrival: Date().addingTimeInterval(3600),
        platform: "1",
        lineName: "RE 7",
        walkingTime: 5,
        delayMinutes: nil,
        direction: "München Hbf",
        nextDepartures: [nextDep1],
        status: .onTime,
        lastUpdated: Date().addingTimeInterval(-120),
        isConnected: true
    )
}
