import WidgetKit
import SwiftUI
import AppIntents
import Foundation

// Shared types within the widget target to avoid separate target wiring
enum WidgetShared {
    static let suiteName = "group.com.trainviewer"

    struct RouteSummary: Codable, Identifiable, Equatable {
        let id: String
        let name: String
        let originName: String
        let destName: String
    }

    struct WidgetDeparturePayload: Codable {
        let routeId: String
        let routeName: String
        let firstDeparture: Date
        let firstArrival: Date
        let platform: String?
        let walkBufferMins: Int
        let updatedAt: Date
    }
}

struct RouteShort: AppEntity, Identifiable, Hashable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Route")
    static var defaultQuery = RoutesQuery()

    let id: String
    let name: String

    static let defaultValue = RouteShort(id: "", name: "Latest used")

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: name))
    }
}

struct RoutesQuery: EntityQuery {
    func entities(for identifiers: [RouteShort.ID]) async throws -> [RouteShort] {
        let all = try await suggestedEntities()
        return all.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [RouteShort] {
        let defaults = UserDefaults(suiteName: WidgetShared.suiteName)
        guard
            let data = defaults?.data(forKey: "routesList"),
            let routes = try? JSONDecoder().decode([WidgetShared.RouteSummary].self, from: data)
        else { return [] }
        return routes.map { RouteShort(id: $0.id, name: $0.name) }
    }
}

struct SelectRouteIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Route"

    @Parameter(title: "Route")
    var route: RouteShort?

    static var parameterSummary: some ParameterSummary {
        Summary("Route: \(\SelectRouteIntent.$route)")
    }
}

struct DepartureEntry: TimelineEntry {
    let date: Date
    let routeName: String
    let leaveInMinutes: Int
    let nextWindow: String
    let routeId: String?
}

struct Provider: AppIntentTimelineProvider {
    typealias Intent = SelectRouteIntent

    func placeholder(in context: Context) -> DepartureEntry {
        DepartureEntry(date: Date(), routeName: "Home → Uni", leaveInMinutes: 8, nextWindow: "12:45 → 13:22", routeId: nil)
    }

    func snapshot(for configuration: SelectRouteIntent, in context: Context) async -> DepartureEntry {
        (await loadEntry(configuration: configuration))
            ?? placeholder(in: context)
    }

    func timeline(for configuration: SelectRouteIntent, in context: Context) async -> Timeline<DepartureEntry> {
        let entry = await loadEntry(configuration: configuration) ?? placeholder(in: context)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 20, to: Date()) ?? Date().addingTimeInterval(1200)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func loadEntry(configuration: SelectRouteIntent) async -> DepartureEntry? {
        let defaults = UserDefaults(suiteName: WidgetShared.suiteName)

        var selectedRouteId: String?
        if let route = configuration.route { selectedRouteId = route.id }
        if selectedRouteId == nil {
            selectedRouteId = defaults?.string(forKey: "lastUsedRouteId")
        }

        guard let routeId = selectedRouteId,
              let data = defaults?.data(forKey: "departures_" + routeId),
              let payload = try? JSONDecoder().decode(WidgetShared.WidgetDeparturePayload.self, from: data)
        else {
            return DepartureEntry(date: Date(), routeName: "Choose a route", leaveInMinutes: 0, nextWindow: "Open app to set", routeId: nil)
        }

        let buffer = payload.walkBufferMins
        let minutes = max(0, Int(payload.firstDeparture.timeIntervalSinceNow / 60) - buffer)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let window = "\(formatter.string(from: payload.firstDeparture)) → \(formatter.string(from: payload.firstArrival))"

        return DepartureEntry(date: payload.updatedAt, routeName: payload.routeName, leaveInMinutes: minutes, nextWindow: window, routeId: payload.routeId)
    }
}

struct NextDepartureWidgetEntryView : View {
    @Environment(\.widgetFamily) private var family
    var entry: Provider.Entry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                mediumLayout
            default:
                smallLayout
            }
        }
        .widgetURL(deeplinkURL())
        .modifier(WidgetBackgroundIfAvailable())
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.routeName)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .truncationMode(.tail)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("🚇")
                    .font(.title3)
                Text("\(entry.leaveInMinutes)m")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }

            Text(entry.nextWindow)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding()
    }

    private var mediumLayout: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.routeName)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .truncationMode(.tail)

                Text(entry.nextWindow)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text("Leave in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(entry.leaveInMinutes) min")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
        }
        .padding()
    }

    private func deeplinkURL() -> URL? {
        guard let id = entry.routeId else { return URL(string: "trainviewer://") }
        return URL(string: "trainviewer://route/\(id)")
    }
}

@available(iOS 16.0, *)
private struct WidgetBackgroundIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .containerBackground(for: .widget) { Color.clear }
        } else {
            content
        }
    }
}

@main
struct NextDepartureWidget: Widget {
    let kind: String = "NextDepartureWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectRouteIntent.self, provider: Provider()) { entry in
            NextDepartureWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Departure")
        .description("Shows the next departure for a favorite route.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

