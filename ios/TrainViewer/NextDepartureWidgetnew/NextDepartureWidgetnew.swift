//
//  NextDepartureWidgetnew.swift
//  NextDepartureWidgetnew
//
//  Created by Sayed Mohamed on 07.09.25.
//

import WidgetKit
import SwiftUI

// MARK: - Journey Details Models (copied for widget access)
public struct JourneyDetails: Codable {
    public let journeyId: String
    public let legs: [JourneyLeg]
    public let totalDuration: Int
    public let totalStops: Int

    public init(journeyId: String, legs: [JourneyLeg], totalDuration: Int, totalStops: Int) {
        self.journeyId = journeyId
        self.legs = legs
        self.totalDuration = totalDuration
        self.totalStops = totalStops
    }
}

public struct JourneyLeg: Codable, Identifiable {
    public let id = UUID()
    public let origin: StopInfo
    public let destination: StopInfo
    public let intermediateStops: [StopInfo]
    public let departure: Date
    public let arrival: Date
    public let lineName: String?
    public let platform: String?
    public let direction: String?
    public let delayMinutes: Int?

    public init(origin: StopInfo, destination: StopInfo, intermediateStops: [StopInfo] = [], departure: Date, arrival: Date, lineName: String? = nil, platform: String? = nil, direction: String? = nil, delayMinutes: Int? = nil) {
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
}

// MARK: - Shared Models (copied for widget access)
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

// MARK: - Shared Store (simplified for widget)
public final class SharedStore {
    public static let shared = SharedStore()
    private init() {}

    private let snapshotKey = "widget_main_snapshot"
    private let widgetRouteKey = "widget.selectedRouteId"
    private let appGroupIdentifier: String = "group.com.trainviewer"

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    public func loadSnapshot() -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    public func loadWidgetRoute() -> UUID? {
        guard let str = defaults?.string(forKey: widgetRouteKey), let id = UUID(uuidString: str) else { return nil }
        return id
    }
}

// MARK: - Route Entry (Timeline Entry)
struct RouteEntry: TimelineEntry {
    let date: Date
    let routeId: UUID?
    let routeName: String
    let leaveInMinutes: Int
    let departure: Date
    let arrival: Date
    let nextDepartures: [DepartureInfo]? // For medium widget
    let walkingTime: Int? // Walking time in minutes

    init(date: Date, routeId: UUID?, routeName: String, leaveInMinutes: Int, departure: Date, arrival: Date, nextDepartures: [DepartureInfo]? = nil, walkingTime: Int? = nil) {
        self.date = date
        self.routeId = routeId
        self.routeName = routeName
        self.leaveInMinutes = leaveInMinutes
        self.departure = departure
        self.arrival = arrival
        self.nextDepartures = nextDepartures
        self.walkingTime = walkingTime
    }
}

struct DepartureInfo: Codable, Identifiable, Hashable {
    let id = UUID()
    let departure: Date
    let arrival: Date
    let duration: Int // in minutes
}

// MARK: - Widget Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> RouteEntry {
        print("🔧 WIDGET: Provider.placeholder() called - Family: \(context.family)")
        let nextDepartures = context.family == .systemMedium ? [
            DepartureInfo(departure: Date().addingTimeInterval(600), arrival: Date().addingTimeInterval(3600), duration: 60),
            DepartureInfo(departure: Date().addingTimeInterval(1800), arrival: Date().addingTimeInterval(5400), duration: 60),
            DepartureInfo(departure: Date().addingTimeInterval(3600), arrival: Date().addingTimeInterval(7200), duration: 60)
        ] : nil

        let entry = RouteEntry(
            date: Date(),
            routeId: nil,
            routeName: "Home → Uni",
            leaveInMinutes: 8,
            departure: Date().addingTimeInterval(600),
            arrival: Date().addingTimeInterval(3600),
            nextDepartures: nextDepartures,
            walkingTime: 5
        )
        print("🔧 WIDGET: Placeholder entry created: \(entry.routeName)")
        return entry
    }

    func getSnapshot(in context: Context, completion: @escaping (RouteEntry) -> ()) {
        print("🔧 WIDGET: Provider.getSnapshot() called - Family: \(context.family)")
        print("🔧 WIDGET: Checking for snapshot in SharedStore...")

        do {
            if let snap = SharedStore.shared.loadSnapshot() {
                print("✅ WIDGET: Found snapshot - Route: \(snap.routeName), Leave in: \(snap.leaveInMinutes)min")

                // Create next departures for medium widget
                let nextDepartures = context.family == .systemMedium ? createNextDepartures(for: snap.departure) : nil

                let entry = RouteEntry(
                    date: Date(),
                    routeId: snap.routeId,
                    routeName: snap.routeName,
                    leaveInMinutes: snap.leaveInMinutes,
                    departure: snap.departure,
                    arrival: snap.arrival,
                    nextDepartures: nextDepartures,
                    walkingTime: snap.walkingTime ?? 5 // Use snapshot walking time or default
                )
                completion(entry)
            } else {
                print("⚠️ WIDGET: No snapshot found, using placeholder")
                completion(placeholder(in: context))
            }
        } catch {
            print("❌ WIDGET: Error accessing SharedStore: \(error.localizedDescription)")
            completion(placeholder(in: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RouteEntry>) -> ()) {
        print("🔧 WIDGET: Provider.getTimeline() called - Family: \(context.family)")

        let entry: RouteEntry
        do {
            if let snap = SharedStore.shared.loadSnapshot() {
                print("✅ WIDGET: Timeline using snapshot - Route: \(snap.routeName)")

                // Create next departures for medium widget
                let nextDepartures = context.family == .systemMedium ? createNextDepartures(for: snap.departure) : nil

                entry = RouteEntry(
                    date: Date(),
                    routeId: snap.routeId,
                    routeName: snap.routeName,
                    leaveInMinutes: snap.leaveInMinutes,
                    departure: snap.departure,
                    arrival: snap.arrival,
                    nextDepartures: nextDepartures,
                    walkingTime: snap.walkingTime ?? 5 // Use snapshot walking time or default
                )
            } else {
                print("⚠️ WIDGET: Timeline using placeholder")
                entry = placeholder(in: context)
            }
        } catch {
            print("❌ WIDGET: Error accessing SharedStore: \(error.localizedDescription)")
            entry = placeholder(in: context)
        }

        // Calculate adaptive refresh interval based on route settings
        let refreshInterval = calculateWidgetRefreshInterval(for: entry)
        let next = Calendar.current.date(byAdding: .second, value: Int(refreshInterval), to: Date())!
        print("🔧 WIDGET: Timeline created - Next update: \(next) (interval: \(refreshInterval)s)")
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func createNextDepartures(for firstDeparture: Date) -> [DepartureInfo] {
        // Create estimated subsequent departures based on typical transit patterns
        // In a real implementation, this could use historical data or API calls
        return [
            DepartureInfo(
                departure: firstDeparture.addingTimeInterval(1800), // +30 min
                arrival: firstDeparture.addingTimeInterval(1800 + 3600), // +30 min + 1 hour
                duration: 60
            ),
            DepartureInfo(
                departure: firstDeparture.addingTimeInterval(3600), // +1 hour
                arrival: firstDeparture.addingTimeInterval(3600 + 3600), // +1 hour + 1 hour
                duration: 60
            ),
            DepartureInfo(
                departure: firstDeparture.addingTimeInterval(5400), // +1.5 hours
                arrival: firstDeparture.addingTimeInterval(5400 + 3600), // +1.5 hours + 1 hour
                duration: 60
            )
        ]
    }

    private func calculateWidgetRefreshInterval(for entry: RouteEntry) -> TimeInterval {
        // Default interval for widgets - keep it simple and battery-friendly
        var interval: TimeInterval = 600 // 10 minutes default

        // For widgets, we use a simple time-based approach
        let now = Date()
        let timeUntilDeparture = entry.departure.timeIntervalSince(now)

        // If departure is within 30 minutes, refresh more frequently
        if timeUntilDeparture <= 1800 && timeUntilDeparture > 0 {
            interval = 300 // 5 minutes
        }
        // If departure is within 2 hours, refresh moderately
        else if timeUntilDeparture <= 7200 && timeUntilDeparture > 0 {
            interval = 600 // 10 minutes
        }
        // If departure is further away, refresh less frequently
        else {
            interval = 1800 // 30 minutes
        }

        print("🔧 WIDGET: Using simple interval: \(interval)s (departure in \(Int(timeUntilDeparture/60))min)")
        return interval
    }
}

// MARK: - Widget View
struct NextDepartureWidgetnewEntryView : View {
    var entry: RouteEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        Group {
            if widgetFamily == .systemMedium {
                mediumWidgetView
            } else {
                smallWidgetView
            }
        }
        .containerBackground(.background, for: .widget)
        .onAppear {
            print("🔧 WIDGET: WidgetEntryView appeared - Route: \(entry.routeName), Leave in: \(entry.leaveInMinutes)min, Family: \(widgetFamily)")
        }
    }

    // MARK: - Small Widget View
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.routeName)
                .font(.headline)
                .foregroundColor(.primary)

            HStack {
                Text(entry.leaveInMinutes <= 0 ? "Leave now" : "Leave in \(entry.leaveInMinutes) min")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(time(entry.departure)) → \(time(entry.arrival))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Medium Widget View (Next Steps)
    private var mediumWidgetView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with route name and walking time
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.routeName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let walkingTime = entry.walkingTime {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 12))
                            Text("\(walkingTime)min walk")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.leaveInMinutes <= 0 ? "Leave now" : "Leave in \(entry.leaveInMinutes) min")
                        .font(.subheadline)
                        .foregroundColor(entry.leaveInMinutes <= 0 ? .red : .blue)

                    Text("Next: \(time(entry.departure))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Next Steps / Upcoming Departures
            VStack(alignment: .leading, spacing: 8) {
                Text("Next Departures")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if let nextDepartures = entry.nextDepartures, !nextDepartures.isEmpty {
                    ForEach(nextDepartures.prefix(3)) { departure in
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(time(departure.departure))
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                Text("Duration: \(departure.duration)min")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("→ \(time(departure.arrival))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(departureTimeDescription(for: departure.departure))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                } else {
                    Text("No additional departures available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
        }
        .padding()
    }

    private func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    private func departureTimeDescription(for date: Date) -> String {
        let now = Date()
        let timeUntilDeparture = date.timeIntervalSince(now)
        let minutes = Int(timeUntilDeparture / 60)

        if minutes <= 0 {
            return "Departing"
        } else if minutes < 60 {
            return "In \(minutes)min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "In \(hours)h \(remainingMinutes)m"
        }
    }
}

// MARK: - Widget Configuration
struct NextDepartureWidgetnew: Widget {
    let kind: String = "NextDepartureWidgetnew"

    init() {
        print("🔧 WIDGET: NextDepartureWidgetnew initialized")
    }

    var body: some WidgetConfiguration {
        print("🔧 WIDGET: Creating widget configuration")
        return StaticConfiguration(kind: kind, provider: Provider()) { entry in
            NextDepartureWidgetnewEntryView(entry: entry)
        }
        .configurationDisplayName("Next Departure")
        .description("Shows the next departure for your favorite route.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    NextDepartureWidgetnew()
} timeline: {
    RouteEntry(date: .now, routeId: nil, routeName: "Home → Uni", leaveInMinutes: 8, departure: Date().addingTimeInterval(600), arrival: Date().addingTimeInterval(3600), walkingTime: 5)
    RouteEntry(date: .now, routeId: nil, routeName: "Work → Home", leaveInMinutes: 15, departure: Date().addingTimeInterval(900), arrival: Date().addingTimeInterval(4200), walkingTime: 8)
}

#Preview(as: .systemMedium) {
    NextDepartureWidgetnew()
} timeline: {
    let nextDepartures = [
        DepartureInfo(departure: Date().addingTimeInterval(1800), arrival: Date().addingTimeInterval(5400), duration: 60),
        DepartureInfo(departure: Date().addingTimeInterval(3600), arrival: Date().addingTimeInterval(7200), duration: 60),
        DepartureInfo(departure: Date().addingTimeInterval(5400), arrival: Date().addingTimeInterval(9000), duration: 60)
    ]

    RouteEntry(
        date: .now,
        routeId: nil,
        routeName: "Home → Uni",
        leaveInMinutes: 8,
        departure: Date().addingTimeInterval(600),
        arrival: Date().addingTimeInterval(3600),
        nextDepartures: nextDepartures,
        walkingTime: 5
    )
}

