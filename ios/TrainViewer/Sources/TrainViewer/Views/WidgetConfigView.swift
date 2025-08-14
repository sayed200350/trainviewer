import SwiftUI
import CoreData
import WidgetKit

private enum UpdateFrequency: String, CaseIterable, Identifiable {
    case realtime
    case every5min
    var id: String { rawValue }
    var label: String { self == .realtime ? "Real-time" : "Every 5 min" }
}

struct WidgetConfigView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \RouteEntity.createdAt, ascending: false)],
        animation: .default
    ) private var routes: FetchedResults<RouteEntity>

    private let suiteName = "group.com.trainviewer"
    @State private var selectedRouteId: String = ""
    @State private var showWalkingTime = true
    @State private var showPlatform = true
    @State private var use24h = true
    @State private var frequency: UpdateFrequency = .realtime
    @State private var timeRangeHours: Int = 2
    @State private var saved = false

    var body: some View {
        Form {
            Section("Route") {
                if routes.isEmpty {
                    Text("No saved routes yet. Add one first.")
                        .foregroundColor(.secondary)
                } else {
                    Picker("Widget Route", selection: $selectedRouteId) {
                        Text("Latest used").tag("")
                        ForEach(routes) { r in
                            Text(r.name).tag(r.id)
                        }
                    }
                }
            }

            Section("Display") {
                Toggle("Show walking time", isOn: $showWalkingTime)
                Toggle("Show platform numbers", isOn: $showPlatform)
                Toggle("Use 24-hour time", isOn: $use24h)
            }

            Section("Refresh") {
                Picker("Update frequency", selection: $frequency) {
                    ForEach(UpdateFrequency.allCases) { f in Text(f.label).tag(f) }
                }
                Stepper("Time range: \(timeRangeHours)h", value: $timeRangeHours, in: 1...12)
            }

            Section {
                Button("Apply to Widgets") { save() }
                if saved { Text("Saved. Widgets will refresh shortly.").foregroundColor(.green) }
            }
        }
        .navigationTitle("Widget Settings")
        .onAppear(perform: load)
    }

    private func load() {
        let defaults = UserDefaults(suiteName: suiteName)
        selectedRouteId = defaults?.string(forKey: "widgetRouteId") ?? ""
        showWalkingTime = defaults?.object(forKey: "widgetShowWalkingTime") as? Bool ?? true
        showPlatform = defaults?.object(forKey: "widgetShowPlatform") as? Bool ?? true
        use24h = defaults?.object(forKey: "widgetUse24h") as? Bool ?? true
        let freqRaw = defaults?.string(forKey: "widgetUpdateFrequency") ?? UpdateFrequency.realtime.rawValue
        frequency = UpdateFrequency(rawValue: freqRaw) ?? .realtime
        timeRangeHours = defaults?.integer(forKey: "widgetTimeRangeHours") ?? 2
    }

    private func save() {
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.set(selectedRouteId, forKey: "widgetRouteId")
        defaults?.set(showWalkingTime, forKey: "widgetShowWalkingTime")
        defaults?.set(showPlatform, forKey: "widgetShowPlatform")
        defaults?.set(use24h, forKey: "widgetUse24h")
        defaults?.set(frequency.rawValue, forKey: "widgetUpdateFrequency")
        defaults?.set(timeRangeHours, forKey: "widgetTimeRangeHours")
        WidgetCenter.shared.reloadAllTimelines()
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { saved = false } }
    }
}


