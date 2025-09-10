import AppIntents
import Foundation

// MARK: - App Shortcuts Provider
struct TrainViewerShortcutsProvider: AppShortcutsProvider {
    @available(iOS 16.0, *)
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: NextTrainIntent(),
                phrases: [
                    "When's the next train",
                    "What's the next train departure",
                    "When does the next train leave",
                    "Next train time",
                    "When's my train",
                    "Train departure time",
                    "Show me next train",
                    "Next departure",
                    "When is my train"
                ],
                shortTitle: "Next Train",
                systemImageName: "train.side.front.car"
            ),

            AppShortcut(
                intent: NextToCampusIntent(),
                phrases: [
                    "Next train to campus",
                    "When's the train to school",
                    "Train to university",
                    "Campus departure time",
                    "Train to school",
                    "Next campus train",
                    "When's school train"
                ],
                shortTitle: "Train to Campus",
                systemImageName: "graduationcap.fill"
            ),

            AppShortcut(
                intent: NextHomeIntent(),
                phrases: [
                    "Next train home",
                    "When's the train home",
                    "Train departure home",
                    "Go home train time",
                    "Home train",
                    "Train to home",
                    "When's home train"
                ],
                shortTitle: "Train Home",
                systemImageName: "house.fill"
            ),

            AppShortcut(
                intent: SiriDebugIntent(),
                phrases: [
                    "Debug Siri",
                    "Check Siri setup",
                    "Siri status"
                ],
                shortTitle: "Debug Siri",
                systemImageName: "ladybug.fill"
            )
        ]
    }
}

// MARK: - App Intents Configuration
struct TrainViewerAppIntentsExtension: AppIntentsPackage {
    static var includedPackages: [AppIntentsPackage.Type] = []

    static var includedIntents: [any AppIntent.Type] = [
        NextToCampusIntent.self,
        NextHomeIntent.self,
        NextTrainIntent.self,
        SiriDebugIntent.self
    ]

    static var suggestedEntities: [any AppEntity.Type] = []

    init() {}
}

// MARK: - Debug Intent for Troubleshooting
struct SiriDebugIntent: AppIntent {
    static var title: LocalizedStringResource = "Debug Siri"
    static var description = IntentDescription("Get debug information for Siri integration")

    static var suggestedPhrases: [LocalizedStringResource] = [
        "Debug Siri",
        "Check Siri setup",
        "Siri status",
        "Debug train app"
    ]

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Check location
        let locationStatus = SharedStore.shared.loadLastLocation() != nil ? "✅ Location available" : "❌ No location data"

        // Check routes
        let routeSummaries = SharedStore.shared.loadRouteSummaries()
        let routesStatus = routeSummaries.isEmpty ? "❌ No routes saved" : "✅ \(routeSummaries.count) routes available"

        // Check settings
        let (campus, home) = SharedStore.shared.loadSettings()
        let campusStatus = campus != nil ? "✅ Campus set" : "❌ No campus set"
        let homeStatus = home != nil ? "✅ Home set" : "❌ No home set"

        let debugInfo = """
        Siri Debug Info:
        \(locationStatus)
        \(routesStatus)
        \(campusStatus)
        \(homeStatus)

        Routes: \(routeSummaries.map { $0.name }.joined(separator: ", "))
        """

        print("Siri Debug: \(debugInfo)")
        return .result(dialog: "Debug info logged to console. Check Xcode for details.")
    }
}

struct NextToCampusIntent: AppIntent {
    static var title: LocalizedStringResource = "Next to campus"
    static var description = IntentDescription("Get the next departure to your campus")

    static var suggestedPhrases: [LocalizedStringResource] = [
        "Next train to campus",
        "When's the train to school",
        "Train to university",
        "Campus departure time"
    ]

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let (campus, _) = SharedStore.shared.loadSettings()
        guard let campus = campus else {
            return .result(dialog: "Please set your campus location in the TrainViewer app Settings first.")
        }
        guard let last = SharedStore.shared.loadLastLocation() else {
            return .result(dialog: "Please open the TrainViewer app at least once to enable location services.")
        }
        let from = Place(rawId: nil, name: "Current Location", latitude: last.lat, longitude: last.lon)
        let api = TransportAPIFactory.shared.make()

        do {
            let options = try await api.nextJourneyOptions(from: from, to: campus, results: 1)
            if let option = options.first {
                let mins = max(0, Int(option.departure.timeIntervalSince(Date()) / 60))
                if mins == 0 {
                    return .result(dialog: "Your train to \(campus.name) is departing now!")
                } else if mins <= 5 {
                    return .result(dialog: "Hurry! Your train to \(campus.name) departs in \(mins) minutes.")
                } else {
                    return .result(dialog: "Your next train to \(campus.name) departs in \(mins) minutes.")
                }
            } else {
                return .result(dialog: "No trains found to \(campus.name) at this time.")
            }
        } catch {
            print("Siri NextToCampusIntent error: \(error.localizedDescription)")
            return .result(dialog: "Unable to fetch train information. Please check your internet connection and try again.")
        }
    }
}

struct NextHomeIntent: AppIntent {
    static var title: LocalizedStringResource = "Next home"
    static var description = IntentDescription("Get the next departure to go home")

    static var suggestedPhrases: [LocalizedStringResource] = [
        "Next train home",
        "When's the train home",
        "Train departure home",
        "Go home train time"
    ]

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let (_, home) = SharedStore.shared.loadSettings()
        guard let home = home else {
            return .result(dialog: "Please set your home location in the TrainViewer app Settings first.")
        }
        guard let last = SharedStore.shared.loadLastLocation() else {
            return .result(dialog: "Please open the TrainViewer app at least once to enable location services.")
        }
        let from = Place(rawId: nil, name: "Current Location", latitude: last.lat, longitude: last.lon)
        let api = TransportAPIFactory.shared.make()

        do {
            let options = try await api.nextJourneyOptions(from: from, to: home, results: 1)
            if let option = options.first {
                let mins = max(0, Int(option.departure.timeIntervalSince(Date()) / 60))
                if mins == 0 {
                    return .result(dialog: "Your train home is departing now!")
                } else if mins <= 5 {
                    return .result(dialog: "Hurry! Your train home departs in \(mins) minutes.")
                } else {
                    return .result(dialog: "Your next train home departs in \(mins) minutes.")
                }
            } else {
                return .result(dialog: "No trains found heading home at this time.")
            }
        } catch {
            print("Siri NextHomeIntent error: \(error.localizedDescription)")
            return .result(dialog: "Unable to fetch train information. Please check your internet connection and try again.")
        }
    }
}

struct NextTrainIntent: AppIntent {
    static var title: LocalizedStringResource = "Next train"
    static var description = IntentDescription("Get the next train departure for your saved routes")

    @Parameter(title: "Route")
    var routeName: String?

    static var suggestedPhrases: [LocalizedStringResource] = [
        "When's the next train",
        "What's the next train departure",
        "When does the next train leave",
        "Next train time",
        "When's my train",
        "Train departure time"
    ]

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // First try to get from current location to a saved route
        guard let last = SharedStore.shared.loadLastLocation() else {
            print("Siri NextTrainIntent: No location found")
            return .result(dialog: "Please open the TrainViewer app at least once to enable location services.")
        }

        let from = Place(rawId: nil, name: "Current Location", latitude: last.lat, longitude: last.lon)
        let api = TransportAPIFactory.shared.make()

        // Load saved routes from SharedStore
        let routeSummaries = SharedStore.shared.loadRouteSummaries()
        print("Siri NextTrainIntent: Found \(routeSummaries.count) saved routes")

        if routeSummaries.isEmpty {
            return .result(dialog: "Please add some routes in the TrainViewer app first.")
        }

        // If user specified a route name, try to find it
        if let routeName = routeName {
            print("Siri NextTrainIntent: Searching for route: \(routeName)")
            let matchingRoute = routeSummaries.first { summary in
                summary.fromName.localizedCaseInsensitiveContains(routeName) ||
                summary.toName.localizedCaseInsensitiveContains(routeName) ||
                summary.name.localizedCaseInsensitiveContains(routeName)
            }

            if let route = matchingRoute {
                let to = Place(rawId: nil, name: route.toName, latitude: route.toLat, longitude: route.toLon)
                print("Siri NextTrainIntent: Found matching route to \(route.toName)")

                do {
                    let options = try await api.nextJourneyOptions(from: from, to: to, results: 1)
                    if let option = options.first {
                        let mins = max(0, Int(option.departure.timeIntervalSince(Date()) / 60))
                        let timeFormatter = DateFormatter()
                        timeFormatter.timeStyle = .short
                        timeFormatter.dateStyle = .none
                        let departureTime = timeFormatter.string(from: option.departure)

                        if mins == 0 {
                            return .result(dialog: "Your train to \(route.toName) is departing now!")
                        } else if mins <= 5 {
                            return .result(dialog: "Hurry! Your train to \(route.toName) departs in \(mins) minutes at \(departureTime).")
                        } else {
                            return .result(dialog: "Next train to \(route.toName) departs in \(mins) minutes at \(departureTime).")
                        }
                    } else {
                        return .result(dialog: "No trains found to \(route.toName) at this time.")
                    }
                } catch {
                    print("Siri NextTrainIntent error for route \(route.toName): \(error.localizedDescription)")
                    return .result(dialog: "Unable to fetch train information for \(route.toName). Please check your internet connection.")
                }
            }
            return .result(dialog: "Couldn't find a route matching '\(routeName)'. Available routes: \(routeSummaries.map { $0.name }.joined(separator: ", "))")
        }

        // No specific route requested - find the next departure from any saved route
        print("Siri NextTrainIntent: Finding next departure from any route")
        var nextDeparture: (route: RouteSummary, option: JourneyOption, minutes: Int)?

        for route in routeSummaries {
            let to = Place(rawId: nil, name: route.toName, latitude: route.toLat, longitude: route.toLon)

            do {
                let options = try await api.nextJourneyOptions(from: from, to: to, results: 1)
                if let option = options.first {
                    let mins = max(0, Int(option.departure.timeIntervalSince(Date()) / 60))
                    if nextDeparture == nil || mins < nextDeparture!.minutes {
                        nextDeparture = (route, option, mins)
                    }
                }
            } catch {
                print("Siri NextTrainIntent error checking route \(route.toName): \(error.localizedDescription)")
                // Continue to next route instead of failing completely
            }
        }

        if let next = nextDeparture {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            timeFormatter.dateStyle = .none
            let departureTime = timeFormatter.string(from: next.option.departure)

            if next.minutes == 0 {
                return .result(dialog: "Your next train to \(next.route.toName) is leaving now!")
            } else if next.minutes <= 5 {
                return .result(dialog: "Hurry! Your next train to \(next.route.toName) leaves in \(next.minutes) minutes at \(departureTime).")
            } else {
                return .result(dialog: "Your next train to \(next.route.toName) leaves in \(next.minutes) minutes at \(departureTime).")
            }
        }

        print("Siri NextTrainIntent: No upcoming trains found")
        return .result(dialog: "No upcoming trains found for your saved routes. Please check your routes in the TrainViewer app.")
    }
}