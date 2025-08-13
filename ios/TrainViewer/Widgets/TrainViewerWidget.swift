import WidgetKit
import SwiftUI

struct RouteEntry: TimelineEntry {
    let date: Date
    let routeName: String
    let leaveInMinutes: Int
    let departure: Date
    let arrival: Date
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> RouteEntry {
        RouteEntry(date: Date(), routeName: "Home → Uni", leaveInMinutes: 8, departure: Date().addingTimeInterval(600), arrival: Date().addingTimeInterval(3600))
    }

    func getSnapshot(in context: Context, completion: @escaping (RouteEntry) -> ()) {
        if let snap = SharedStore.shared.loadSnapshot() {
            completion(RouteEntry(date: Date(), routeName: snap.routeName, leaveInMinutes: snap.leaveInMinutes, departure: snap.departure, arrival: snap.arrival))
        } else {
            completion(placeholder(in: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RouteEntry>) -> ()) {
        let entry: RouteEntry
        if let snap = SharedStore.shared.loadSnapshot() {
            entry = RouteEntry(date: Date(), routeName: snap.routeName, leaveInMinutes: snap.leaveInMinutes, departure: snap.departure, arrival: snap.arrival)
        } else {
            entry = placeholder(in: context)
        }
        let next = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!
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
        }.padding()
    }

    private func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}

@main
struct TrainViewerWidget: Widget {
    let kind: String = "TrainViewerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TrainViewerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Departure")
        .description("Shows the next departure for a favorite route.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}