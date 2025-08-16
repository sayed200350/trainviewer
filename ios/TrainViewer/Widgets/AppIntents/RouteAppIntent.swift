import AppIntents
import WidgetKit
import SwiftUI

struct RouteChoice: AppEntity, Identifiable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Route")

    static var defaultQuery = RouteQuery()

    var id: UUID
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: .init(stringLiteral: name))
    }
}

struct RouteQuery: EntityQuery {
    func entities(for identifiers: [UUID]) throws -> [RouteChoice] {
        let summaries = SharedStore.shared.loadRouteSummaries()
        return summaries.filter { identifiers.contains($0.id) }.map { RouteChoice(id: $0.id, name: $0.name) }
    }

    func suggestedEntities() throws -> [RouteChoice] {
        SharedStore.shared.loadRouteSummaries().map { RouteChoice(id: $0.id, name: $0.name) }
    }

    func defaultResult() -> RouteChoice? {
        SharedStore.shared.loadRouteSummaries().first.map { RouteChoice(id: $0.id, name: $0.name) }
    }
}

struct SelectRouteIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Route"
    static var description = IntentDescription("Choose a favorite route for the widget")

    @Parameter(title: "Route")
    var route: RouteChoice

    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$route)")
    }
}

struct RouteIntentProvider: AppIntentTimelineProvider {
    typealias Entry = RouteEntry
    typealias Intent = SelectRouteIntent

    func placeholder(in context: Context) -> RouteEntry {
        RouteEntry(date: Date(), routeId: nil, routeName: "Home → Uni", leaveInMinutes: 8, departure: Date().addingTimeInterval(600), arrival: Date().addingTimeInterval(3600))
    }

    func snapshot(for configuration: SelectRouteIntent, in context: Context) async -> RouteEntry {
        let snap = SharedStore.shared.loadSnapshot(for: configuration.route.id)
        return RouteEntry(date: Date(), routeId: configuration.route.id, routeName: snap?.routeName ?? configuration.route.name, leaveInMinutes: snap?.leaveInMinutes ?? 8, departure: snap?.departure ?? Date().addingTimeInterval(600), arrival: snap?.arrival ?? Date().addingTimeInterval(3600))
    }

    func timeline(for configuration: SelectRouteIntent, in context: Context) async -> Timeline<RouteEntry> {
        let entry = await snapshot(for: configuration, in: context)
        let next = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!
        return Timeline(entries: [entry], policy: .after(next))
    }
}

struct TrainViewerRouteEntryView : View {
    var entry: RouteEntry

    var body: some View {
        Link(destination: URL(string: "trainviewer://route?id=\(entry.routeId?.uuidString ?? UUID().uuidString)")!) {
            VStack(alignment: .leading) {
                Text(entry.routeName).font(.headline)
                Text(entry.leaveInMinutes <= 0 ? "Leave now" : "Leave in \(entry.leaveInMinutes) min")
                    .font(.subheadline)
                Text("\(time(entry.departure)) → \(time(entry.arrival))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }.padding()
        }
    }

    private func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}

struct TrainViewerRouteWidget: Widget {
    let kind: String = "TrainViewerRouteWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectRouteIntent.self, provider: RouteIntentProvider()) { entry in
            TrainViewerRouteEntryView(entry: entry)
                .widgetURL(URL(string: "trainviewer://route?id=\(entry.routeId?.uuidString ?? UUID().uuidString)"))
        }
        .configurationDisplayName("Route Departure")
        .description("Next departure for a specific favorite route.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}