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

// MARK: - Widget Data Models (matching SharedModels)
struct WidgetSnapshot: Codable {
    let routeId: UUID
    let routeName: String
    let leaveInMinutes: Int
    let departure: Date
    let arrival: Date
    let walkingTime: Int?
}

// MARK: - Widget Data Loader
class WidgetDataLoader {
    private static let snapshotKey = "widget_main_snapshot"
    private static let appGroupIdentifier = "group.com.trainviewer"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    static func loadWidgetSnapshot() -> WidgetSnapshot? {
        guard let data = sharedDefaults?.data(forKey: snapshotKey) else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    static func isDataAvailable() -> Bool {
        return sharedDefaults?.data(forKey: snapshotKey) != nil
    }

    static func validateAndCleanEntry(_ entry: WidgetEntry) -> WidgetEntry {
        let now = Date()
        var cleanedEntry = entry

        // If departure time has passed, try to show next available departure
        // For now, we'll just update the leave time calculation
        if entry.departure <= now {
            cleanedEntry.leaveInMinutes = 0
        } else {
            // Recalculate leave time based on current time
            let timeUntilDeparture = entry.departure.timeIntervalSince(now)
            let leaveMinutes = max(0, Int(timeUntilDeparture / 60))
            cleanedEntry.leaveInMinutes = leaveMinutes
        }

        return cleanedEntry
    }
}

// MARK: - Widget Entry
struct WidgetEntry: TimelineEntry {
    let date: Date
    let routeName: String
    var leaveInMinutes: Int
    let departure: Date
    let arrival: Date
    let platform: String?
    let lineName: String?
    let walkingTime: Int?
}

// MARK: - Widget Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        // Create more realistic placeholder data
        let now = Date()
        let nextDeparture = now.addingTimeInterval(900) // 15 minutes from now
        let arrivalTime = nextDeparture.addingTimeInterval(2700) // 45 minutes later

        return WidgetEntry(
            date: now,
            routeName: "Add a route in app",
            leaveInMinutes: 15,
            departure: nextDeparture,
            arrival: arrivalTime,
            platform: nil,
            lineName: nil,
            walkingTime: nil
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

            // Convert WidgetSnapshot to WidgetEntry
            let entry = WidgetEntry(
                date: Date(),
                routeName: snapshot.routeName,
                leaveInMinutes: snapshot.leaveInMinutes,
                departure: snapshot.departure,
                arrival: snapshot.arrival,
                platform: nil, // Platform info not in WidgetSnapshot
                lineName: nil, // Line info not in WidgetSnapshot
                walkingTime: snapshot.walkingTime
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
            var entries: [WidgetEntry] = [entry]

            // If departure is in the future, add an updated entry for when it's time to leave
            if entry.departure > Date() {
                let leaveTime = entry.departure.addingTimeInterval(TimeInterval(-entry.leaveInMinutes * 60))

                if leaveTime > Date() && leaveTime != entry.departure {
                    let leaveEntry = WidgetEntry(
                        date: leaveTime,
                        routeName: entry.routeName,
                        leaveInMinutes: 0, // It's time to leave
                        departure: entry.departure,
                        arrival: entry.arrival,
                        platform: entry.platform,
                        lineName: entry.lineName,
                        walkingTime: entry.walkingTime
                    )
                    entries.append(leaveEntry)
                }
            }

            // Determine refresh policy based on urgency
            let refreshInterval: TimeInterval
            if entry.leaveInMinutes <= 5 {
                // Very urgent - refresh every minute
                refreshInterval = 60
            } else if entry.leaveInMinutes <= 15 {
                // Moderately urgent - refresh every 2 minutes
                refreshInterval = 120
            } else {
                // Not urgent - refresh every 5 minutes
                refreshInterval = 300
            }

            let timeline = Timeline(entries: entries.sorted(by: { $0.date < $1.date }), policy: .after(Date().addingTimeInterval(refreshInterval)))
            completion(timeline)
        }
    }
}

// MARK: - Widget View
struct TrainViewerWidgetEntryView : View {
    var entry: WidgetEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        case .accessoryRectangular:
            rectangularLockScreenView
        case .accessoryInline:
            inlineLockScreenView
        case .accessoryCircular:
            circularLockScreenView
        default:
            smallWidgetView
        }
    }

    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.routeName)
                .font(.headline)
                .lineLimit(1)

            HStack {
                Text(entry.leaveInMinutes <= 0 ? "Leave now" : "Leave in \(entry.leaveInMinutes)min")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                if let platform = entry.platform {
                    Text(platform)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(formatTime(entry.departure))
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var mediumWidgetView: some View {
        HStack(spacing: 12) {
            // Train icon
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 50, height: 50)

                Image(systemName: "tram.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.routeName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(entry.leaveInMinutes <= 0 ? "DEPART NOW" : "Leave in \(entry.leaveInMinutes) min")
                        .font(.subheadline)
                        .foregroundColor(entry.leaveInMinutes <= 0 ? .red : .blue)

                    Spacer()

                    if let walkingTime = entry.walkingTime {
                        Label("\(walkingTime)min", systemImage: "figure.walk")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    Text(formatTime(entry.departure))
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("→ \(formatTime(entry.arrival))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let platform = entry.platform {
                        Text(platform)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let line = entry.lineName {
                    Text(line)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Lock Screen Widget Views

    private var rectangularLockScreenView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Route name
            Text(entry.routeName)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .foregroundColor(.white)

            // Departure time (prominent)
            Text(formatTime(entry.departure))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            // Status and additional info
            HStack(spacing: 6) {
                if entry.leaveInMinutes <= 0 {
                    Text("DEPART NOW")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red)
                } else {
                    Text("Leave in \(entry.leaveInMinutes)min")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                }

                if let platform = entry.platform {
                    Text(platform)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            // Walking time if available
            if let walkingTime = entry.walkingTime {
                Label("\(walkingTime)min walk", systemImage: "figure.walk")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(.fill.secondary, for: .widget)
    }

    private var inlineLockScreenView: some View {
        HStack(spacing: 4) {
            Image(systemName: "tram.fill")
                .font(.system(size: 12))
                .foregroundColor(.blue)

            Text(entry.routeName)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .foregroundColor(.white)

            Text("•")
                .foregroundColor(.white.opacity(0.5))

            Text(formatTime(entry.departure))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            if entry.leaveInMinutes <= 0 {
                Text("(NOW)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.red)
            }
        }
        .containerBackground(.clear, for: .widget)
    }

    private var circularLockScreenView: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)

            VStack(spacing: 0) {
                Text(formatTime(entry.departure).split(separator: ":").first ?? "00")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)

                Text(formatTime(entry.departure).split(separator: ":").last ?? "00")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .containerBackground(.clear, for: .widget)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Widget Configuration
struct TrainViewerWidget: Widget {
    let kind: String = "TrainViewerWidget"

    init() {
        print("🚂 WIDGET: TrainViewerWidget initialized")
        print("🚂 WIDGET: Supported families: systemSmall, systemMedium, accessoryRectangular, accessoryInline, accessoryCircular")
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TrainViewerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Train Departure")
        .description("Shows your next train departure time.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular
        ])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    TrainViewerWidget()
} timeline: {
    WidgetEntry(
        date: .now,
        routeName: "Home → Work",
        leaveInMinutes: 12,
        departure: Date().addingTimeInterval(720),
        arrival: Date().addingTimeInterval(3600),
        platform: nil, // Real data may not have platform/line info
        lineName: nil,
        walkingTime: 8
    )
}

#Preview(as: .systemMedium) {
    TrainViewerWidget()
} timeline: {
    WidgetEntry(
        date: .now,
        routeName: "Work → Home",
        leaveInMinutes: 5,
        departure: Date().addingTimeInterval(300),
        arrival: Date().addingTimeInterval(2700),
        platform: nil,
        lineName: nil,
        walkingTime: 3
    )
}

// MARK: - Lock Screen Widget Previews

#Preview(as: .accessoryRectangular) {
    TrainViewerWidget()
} timeline: {
    WidgetEntry(
        date: .now,
        routeName: "Home → University",
        leaveInMinutes: 12,
        departure: Date().addingTimeInterval(720),
        arrival: Date().addingTimeInterval(3600),
        platform: nil,
        lineName: nil,
        walkingTime: 8
    )
}

#Preview(as: .accessoryInline) {
    TrainViewerWidget()
} timeline: {
    WidgetEntry(
        date: .now,
        routeName: "Work → Home",
        leaveInMinutes: 5,
        departure: Date().addingTimeInterval(300),
        arrival: Date().addingTimeInterval(2700),
        platform: nil,
        lineName: nil,
        walkingTime: 3
    )
}

#Preview(as: .accessoryCircular) {
    TrainViewerWidget()
} timeline: {
    WidgetEntry(
        date: .now,
        routeName: "Home → Work",
        leaveInMinutes: 15,
        departure: Date().addingTimeInterval(900),
        arrival: Date().addingTimeInterval(3600),
        platform: nil,
        lineName: nil,
        walkingTime: 5
    )
}
