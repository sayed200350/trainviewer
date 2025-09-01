import WidgetKit
import SwiftUI

struct RouteEntry: TimelineEntry {
    let date: Date
    let routeId: UUID?
    let routeName: String
    let leaveInMinutes: Int
    let departure: Date
    let arrival: Date
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> RouteEntry {
        print("🔧 WIDGET: Provider.placeholder() called - Family: \(context.family)")
        let entry = RouteEntry(date: Date(), routeId: nil, routeName: "Home → Uni", leaveInMinutes: 8, departure: Date().addingTimeInterval(600), arrival: Date().addingTimeInterval(3600))
        print("🔧 WIDGET: Placeholder entry created: \(entry.routeName)")
        return entry
    }

    func getSnapshot(in context: Context, completion: @escaping (RouteEntry) -> ()) {
        print("🔧 WIDGET: Provider.getSnapshot() called - Family: \(context.family)")
        print("🔧 WIDGET: Checking for snapshot in SharedStore...")

        if let snap = SharedStore.shared.loadSnapshot() {
            print("✅ WIDGET: Found snapshot - Route: \(snap.routeName), Leave in: \(snap.leaveInMinutes)min")
            let entry = RouteEntry(date: Date(), routeId: snap.routeId, routeName: snap.routeName, leaveInMinutes: snap.leaveInMinutes, departure: snap.departure, arrival: snap.arrival)
            completion(entry)
        } else {
            print("⚠️ WIDGET: No snapshot found, using placeholder")
            completion(placeholder(in: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RouteEntry>) -> ()) {
        print("🔧 WIDGET: Provider.getTimeline() called - Family: \(context.family)")

        let entry: RouteEntry
        if let snap = SharedStore.shared.loadSnapshot() {
            print("✅ WIDGET: Timeline using snapshot - Route: \(snap.routeName)")
            entry = RouteEntry(date: Date(), routeId: snap.routeId, routeName: snap.routeName, leaveInMinutes: snap.leaveInMinutes, departure: snap.departure, arrival: snap.arrival)
        } else {
            print("⚠️ WIDGET: Timeline using placeholder - No snapshot data available")
            print("🔧 WIDGET: Make sure to add routes in the main app first")
            entry = placeholder(in: context)
        }

        let next = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!
        print("🔧 WIDGET: Timeline created - Next update: \(next)")
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct TrainViewerWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.routeName).font(.headline)
            Text(entry.leaveInMinutes <= 0 ? "Leave now" : "Leave in \(entry.leaveInMinutes) min")
                .font(.subheadline)
            Text("\(time(entry.departure)) → \(time(entry.arrival))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .onAppear {
            print("🔧 WIDGET: WidgetEntryView appeared - Route: \(entry.routeName), Leave in: \(entry.leaveInMinutes)min")
        }
    }

    private func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}

struct TrainViewerWidget: Widget {
    let kind: String = "TrainViewerWidget"

    init() {
        print("🔧 WIDGET: TrainViewerWidget initialized")
    }

    var body: some WidgetConfiguration {
        print("🔧 WIDGET: Creating widget configuration")
        return StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TrainViewerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Departure")
        .description("Shows the next departure for a favorite route.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}