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
        do {
            let summaries = SharedStore.shared.loadRouteSummaries()
            return summaries.filter { identifiers.contains($0.id) }.map { RouteChoice(id: $0.id, name: $0.name) }
        } catch {
            print("❌ WIDGET: Error loading route summaries: \(error.localizedDescription)")
            return []
        }
    }

    func suggestedEntities() throws -> [RouteChoice] {
        do {
            return SharedStore.shared.loadRouteSummaries().map { RouteChoice(id: $0.id, name: $0.name) }
        } catch {
            print("❌ WIDGET: Error loading suggested entities: \(error.localizedDescription)")
            return []
        }
    }

    func defaultResult() -> RouteChoice? {
        do {
            return SharedStore.shared.loadRouteSummaries().first.map { RouteChoice(id: $0.id, name: $0.name) }
        } catch {
            print("❌ WIDGET: Error loading default result: \(error.localizedDescription)")
            return nil
        }
    }
}

struct SelectRouteIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Route"
    static var description = IntentDescription("Choose a favorite route for the widget")

    @Parameter(title: "Route")
    var route: RouteChoice?

    static var parameterSummary: some ParameterSummary {
        Summary("Show route")
    }
}

struct RouteIntentProvider: AppIntentTimelineProvider {
    typealias Entry = RouteEntry
    typealias Intent = SelectRouteIntent

    func placeholder(in context: Context) -> RouteEntry {
        RouteEntry(date: Date(), routeId: nil, routeName: "Home → Uni", leaveInMinutes: 8, departure: Date().addingTimeInterval(600), arrival: Date().addingTimeInterval(3600))
    }

    func snapshot(for configuration: SelectRouteIntent, in context: Context) async -> RouteEntry {
        guard let route = configuration.route else {
            return RouteEntry(date: Date(), routeId: nil, routeName: "Select a Route", leaveInMinutes: 0, departure: Date(), arrival: Date())
        }

        do {
            let snap = SharedStore.shared.loadSnapshot(for: route.id)
            return RouteEntry(date: Date(), routeId: route.id, routeName: snap?.routeName ?? route.name, leaveInMinutes: snap?.leaveInMinutes ?? 8, departure: snap?.departure ?? Date().addingTimeInterval(600), arrival: snap?.arrival ?? Date().addingTimeInterval(3600))
        } catch {
            print("❌ WIDGET: Error loading snapshot for route \(route.name): \(error.localizedDescription)")
            return RouteEntry(date: Date(), routeId: route.id, routeName: route.name, leaveInMinutes: 8, departure: Date().addingTimeInterval(600), arrival: Date().addingTimeInterval(3600))
        }
    }

    func timeline(for configuration: SelectRouteIntent, in context: Context) async -> Timeline<RouteEntry> {
        do {
            let entry = await snapshot(for: configuration, in: context)
            let next = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!
            return Timeline(entries: [entry], policy: .after(next))
        } catch {
            print("❌ WIDGET: Error creating timeline: \(error.localizedDescription)")
            let fallbackEntry = RouteEntry(date: Date(), routeId: configuration.route?.id, routeName: configuration.route?.name ?? "Select a Route", leaveInMinutes: 8, departure: Date().addingTimeInterval(600), arrival: Date().addingTimeInterval(3600))
            let next = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!
            return Timeline(entries: [fallbackEntry], policy: .after(next))
        }
    }
}

struct TrainViewerRouteEntryView : View {
    var entry: RouteEntry

    var body: some View {
        if let url = URL(string: "trainviewer://route?id=\(entry.routeId?.uuidString ?? UUID().uuidString)") {
            Link(destination: url) {
                VStack(alignment: .leading) {
                    Text(entry.routeName).font(.headline)
                    Text(entry.leaveInMinutes <= 0 ? "Leave now" : "Leave in \(entry.leaveInMinutes) min")
                        .font(.subheadline)
                    Text("\(time(entry.departure)) → \(time(entry.arrival))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }.padding()
            }
        } else {
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
            if let widgetUrl = URL(string: "trainviewer://route?id=\(entry.routeId?.uuidString ?? UUID().uuidString)") {
                TrainViewerRouteEntryView(entry: entry)
                    .widgetURL(widgetUrl)
            } else {
                TrainViewerRouteEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Route Departure")
        .description("Next departure for a specific favorite route.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}