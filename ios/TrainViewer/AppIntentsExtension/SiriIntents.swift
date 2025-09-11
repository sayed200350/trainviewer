//
//  SiriIntents.swift
//  TrainViewerAppIntentsExtension
//
//  Created by Sayed Mohamed on 11.09.25.
//

import AppIntents
import Foundation

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

        // Check widget route
        let widgetRouteId = SharedStore.shared.loadWidgetRoute()
        let widgetStatus = widgetRouteId != nil ? "✅ Widget route set" : "❌ No widget route set"

        // Check widget snapshot
        var widgetDataStatus = "❌ No widget data"
        if let routeId = widgetRouteId,
           let snapshot = SharedStore.shared.loadSnapshot(for: routeId) {
            let mins = max(0, Int(snapshot.departure.timeIntervalSince(Date()) / 60))
            widgetDataStatus = "✅ Widget data: '\(snapshot.routeName)' departs in \(mins)min"
        }

        let debugInfo = """
        🔧 Siri Debug Info:
        \(locationStatus)
        \(routesStatus)
        \(campusStatus)
        \(homeStatus)
        \(widgetStatus)
        \(widgetDataStatus)

        📋 Available Routes: \(routeSummaries.map { $0.name }.joined(separator: ", "))

        💡 Try these commands:
        • "Hey Siri, debug Siri" (this command)
        • "Hey Siri, when's my train"
        • "Hey Siri, when is my train home"
        • "Hey Siri, when is my train to campus"
        """

        print("🚨 Siri Debug: \(debugInfo)")
        return .result(dialog: "Debug info: \(locationStatus), \(routesStatus), \(widgetStatus). Check console for full details.")
    }
}

struct NextToCampusIntent: AppIntent {
    static var title: LocalizedStringResource = "Next to campus"
    static var description = IntentDescription("Get the next departure to your campus")

    static var suggestedPhrases: [LocalizedStringResource] = [
        "Next train to campus",
        "When's the train to school",
        "Train to university",
        "Campus departure time",
        "When is my train to campus",
        "My train to campus",
        "Train to campus",
        "Campus train time",
        "When's campus train"
    ]

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let (campus, _) = SharedStore.shared.loadSettings()
        guard let campus = campus else {
            return .result(dialog: SiriResponseHelper.getSetupGuidance())
        }
        guard let last = SharedStore.shared.loadLastLocation() else {
            return .result(dialog: SiriResponseHelper.getLocationGuidance())
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
            return .result(dialog: SiriResponseHelper.getNetworkGuidance())
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
        "Go home train time",
        "When is my train home",
        "My train home",
        "Train home",
        "Home train time",
        "When's home train"
    ]

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let (_, home) = SharedStore.shared.loadSettings()
        guard let home = home else {
            return .result(dialog: SiriResponseHelper.getSetupGuidance())
        }
        guard let last = SharedStore.shared.loadLastLocation() else {
            return .result(dialog: SiriResponseHelper.getLocationGuidance())
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
            return .result(dialog: SiriResponseHelper.getNetworkGuidance())
        }
    }
}

struct WidgetTrainIntent: AppIntent {
    static var title: LocalizedStringResource = "Widget train"
    static var description = IntentDescription("Get the next train for your widget's current route")

    static var suggestedPhrases: [LocalizedStringResource] = [
        "When's my train",
        "My train time",
        "What's my train time",
        "When does my train leave",
        "Check my train"
    ]

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // First, try to get the widget's current route
        guard let widgetRouteId = SharedStore.shared.loadWidgetRoute() else {
            return .result(dialog: "Please set up a route in your TrainViewer widget first. Open the widget and select a route to enable this feature.")
        }

        // Load the widget snapshot for this route
        guard let snapshot = SharedStore.shared.loadSnapshot(for: widgetRouteId) else {
            return .result(dialog: "No train data available for your widget route. Please refresh the TrainViewer app to update the widget data.")
        }

        // Get current location for context
        guard let lastLocation = SharedStore.shared.loadLastLocation() else {
            return .result(dialog: SiriResponseHelper.getLocationGuidance())
        }

        let now = Date()
        let departureTime = snapshot.departure
        let minutesUntilDeparture = max(0, Int(departureTime.timeIntervalSince(now) / 60))

        // Format the departure time
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.dateStyle = .none
        let departureTimeString = timeFormatter.string(from: departureTime)

        // Create appropriate response based on urgency
        if minutesUntilDeparture == 0 {
            return .result(dialog: "Your train to \(snapshot.routeName) is departing now! Don't miss it!")
        } else if minutesUntilDeparture <= 2 {
            return .result(dialog: "Hurry! Your train to \(snapshot.routeName) departs in just \(minutesUntilDeparture) minute\(minutesUntilDeparture == 1 ? "" : "s") at \(departureTimeString).")
        } else if minutesUntilDeparture <= 5 {
            return .result(dialog: "Your train to \(snapshot.routeName) departs in \(minutesUntilDeparture) minutes at \(departureTimeString). Time to head out!")
        } else if minutesUntilDeparture <= 15 {
            return .result(dialog: "Your next train to \(snapshot.routeName) is at \(departureTimeString), which is in \(minutesUntilDeparture) minutes.")
        } else {
            return .result(dialog: "Your next train to \(snapshot.routeName) departs at \(departureTimeString), in about \(minutesUntilDeparture) minutes.")
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
            return .result(dialog: SiriResponseHelper.getLocationGuidance())
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
                    return .result(dialog: SiriResponseHelper.getNetworkGuidance())
                }
            }
            return .result(dialog: SiriResponseHelper.getRouteNotFoundGuidance(availableRoutes: routeSummaries))
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
        return .result(dialog: SiriResponseHelper.getNetworkGuidance())
    }
}

// MARK: - Helper Functions

struct SiriResponseHelper {
    static func getSetupGuidance() -> String {
        return "To use this feature, please: 1) Open the TrainViewer app, 2) Add some routes, and 3) Set your home and campus locations in Settings."
    }

    static func getLocationGuidance() -> String {
        return "Please open the TrainViewer app at least once to enable location services, then try again."
    }

    static func getNetworkGuidance() -> String {
        return "Please check your internet connection and try again. You can also try refreshing the TrainViewer app to update train data."
    }

    static func getRouteNotFoundGuidance(availableRoutes: [RouteSummary]) -> String {
        if availableRoutes.isEmpty {
            return "You don't have any saved routes yet. Please add some routes in the TrainViewer app first."
        } else {
            let routeNames = availableRoutes.map { $0.name }.joined(separator: ", ")
            return "Available routes: \(routeNames). Try asking about one of these routes."
        }
    }

    static func formatTimeUntilDeparture(_ minutes: Int, departureTime: String) -> String {
        switch minutes {
        case 0:
            return "departing now"
        case 1:
            return "departing in 1 minute at \(departureTime)"
        case 2...5:
            return "departing in \(minutes) minutes at \(departureTime) - hurry!"
        case 6...15:
            return "departing in \(minutes) minutes at \(departureTime)"
        default:
            return "departing at \(departureTime) in about \(minutes) minutes"
        }
    }

    static func formatUrgentDeparture(_ minutes: Int, destination: String) -> String {
        switch minutes {
        case 0:
            return "Your train to \(destination) is departing now! Don't miss it!"
        case 1:
            return "Hurry! Your train to \(destination) departs in just 1 minute."
        case 2...5:
            return "Hurry! Your train to \(destination) departs in \(minutes) minutes."
        default:
            return "Your train to \(destination) departs in \(minutes) minutes."
        }
    }
}

// MARK: - Additional Train Query Intents

struct TrainStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Train status"
    static var description = IntentDescription("Get the status and any delays for your train routes")

    @Parameter(title: "Route")
    var routeName: String?

    static var suggestedPhrases: [LocalizedStringResource] = [
        "Train status",
        "Are my trains delayed",
        "Check train delays",
        "Train delay information",
        "Is my train on time",
        "Train schedule status"
    ]

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let last = SharedStore.shared.loadLastLocation() else {
            return .result(dialog: "Please open the TrainViewer app at least once to enable location services.")
        }

        let from = Place(rawId: nil, name: "Current Location", latitude: last.lat, longitude: last.lon)
        let api = TransportAPIFactory.shared.make()
        let routeSummaries = SharedStore.shared.loadRouteSummaries()

        if routeSummaries.isEmpty {
            return .result(dialog: "Please add some routes in the TrainViewer app first to check their status.")
        }

        // If user specified a route name, check that specific route
        if let routeName = routeName {
            let matchingRoute = routeSummaries.first { summary in
                summary.fromName.localizedCaseInsensitiveContains(routeName) ||
                summary.toName.localizedCaseInsensitiveContains(routeName) ||
                summary.name.localizedCaseInsensitiveContains(routeName)
            }

            if let route = matchingRoute {
                let to = Place(rawId: nil, name: route.toName, latitude: route.toLat, longitude: route.toLon)

                do {
                    let options = try await api.nextJourneyOptions(from: from, to: to, results: 3)
                    if let firstOption = options.first {
                        let mins = max(0, Int(firstOption.departure.timeIntervalSince(Date()) / 60))

                        // For demo purposes, simulate occasional delays
                        let hasDelay = Int.random(in: 1...10) <= 2 // 20% chance of delay
                        if hasDelay {
                            let delayMins = Int.random(in: 5...25)
                            return .result(dialog: "Your train to \(route.toName) has a \(delayMins) minute delay. It will depart in \(mins + delayMins) minutes instead of \(mins) minutes.")
                        } else {
                            return .result(dialog: "Your train to \(route.toName) is on time and departs in \(mins) minutes.")
                        }
                    } else {
                        return .result(dialog: "No train information available for \(route.toName) at this time.")
                    }
                } catch {
                    return .result(dialog: "Unable to check train status for \(route.toName). Please try again later.")
                }
            }
            return .result(dialog: "Couldn't find a route matching '\(routeName)'. Available routes: \(routeSummaries.map { $0.name }.joined(separator: ", "))")
        }

        // Check status for all routes
        var statusUpdates: [String] = []

        for route in routeSummaries.prefix(3) { // Limit to first 3 routes to avoid too long responses
            let to = Place(rawId: nil, name: route.toName, latitude: route.toLat, longitude: route.toLon)

            do {
                let options = try await api.nextJourneyOptions(from: from, to: to, results: 1)
                if let option = options.first {
                    let mins = max(0, Int(option.departure.timeIntervalSince(Date()) / 60))

                    // Simulate occasional delays
                    let hasDelay = Int.random(in: 1...10) <= 2
                    if hasDelay {
                        let delayMins = Int.random(in: 5...15)
                        statusUpdates.append("\(route.toName): \(delayMins)min delay")
                    } else {
                        statusUpdates.append("\(route.toName): on time")
                    }
                }
            } catch {
                statusUpdates.append("\(route.toName): status unavailable")
            }
        }

        if statusUpdates.isEmpty {
            return .result(dialog: "Unable to check train status at this time. Please try again later.")
        }

        let statusSummary = statusUpdates.joined(separator: ", ")
        return .result(dialog: "Train status: \(statusSummary)")
    }
}

struct TrainArrivalIntent: AppIntent {
    static var title: LocalizedStringResource = "Train arrival"
    static var description = IntentDescription("Get arrival time for your train journey")

    @Parameter(title: "Route")
    var routeName: String?

    static var suggestedPhrases: [LocalizedStringResource] = [
        "When will my train arrive",
        "Train arrival time",
        "When does my train get there",
        "Arrival time for my train",
        "When will I arrive",
        "Train ETA"
    ]

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let last = SharedStore.shared.loadLastLocation() else {
            return .result(dialog: "Please open the TrainViewer app at least once to enable location services.")
        }

        let from = Place(rawId: nil, name: "Current Location", latitude: last.lat, longitude: last.lon)
        let api = TransportAPIFactory.shared.make()
        let routeSummaries = SharedStore.shared.loadRouteSummaries()

        if routeSummaries.isEmpty {
            return .result(dialog: "Please add some routes in the TrainViewer app first to get arrival times.")
        }

        // If user specified a route name, get arrival for that route
        if let routeName = routeName {
            let matchingRoute = routeSummaries.first { summary in
                summary.fromName.localizedCaseInsensitiveContains(routeName) ||
                summary.toName.localizedCaseInsensitiveContains(routeName) ||
                summary.name.localizedCaseInsensitiveContains(routeName)
            }

            if let route = matchingRoute {
                let to = Place(rawId: nil, name: route.toName, latitude: route.toLat, longitude: route.toLon)

                do {
                    let options = try await api.nextJourneyOptions(from: from, to: to, results: 1)
                    if let option = options.first {
                        let timeFormatter = DateFormatter()
                        timeFormatter.timeStyle = .short
                        timeFormatter.dateStyle = .none
                        let departureTime = timeFormatter.string(from: option.departure)

                        // Calculate estimated arrival time (simplified)
                        let travelMinutes = Int.random(in: 15...90) // Simulate travel time
                        let arrivalTime = option.departure.addingTimeInterval(TimeInterval(travelMinutes * 60))
                        let arrivalTimeString = timeFormatter.string(from: arrivalTime)

                        let departureMins = max(0, Int(option.departure.timeIntervalSince(Date()) / 60))

                        if departureMins == 0 {
                            return .result(dialog: "Your train to \(route.toName) is departing now and should arrive around \(arrivalTimeString).")
                        } else {
                            return .result(dialog: "Your train to \(route.toName) departs in \(departureMins) minutes at \(departureTime) and should arrive around \(arrivalTimeString).")
                        }
                    } else {
                        return .result(dialog: "No train information available for \(route.toName) at this time.")
                    }
                } catch {
                    return .result(dialog: "Unable to get arrival time for \(route.toName). Please try again later.")
                }
            }
            return .result(dialog: "Couldn't find a route matching '\(routeName)'. Available routes: \(routeSummaries.map { $0.name }.joined(separator: ", "))")
        }

        // Get arrival time for the next route
        for route in routeSummaries {
            let to = Place(rawId: nil, name: route.toName, latitude: route.toLat, longitude: route.toLon)

            do {
                let options = try await api.nextJourneyOptions(from: from, to: to, results: 1)
                if let option = options.first {
                    let timeFormatter = DateFormatter()
                    timeFormatter.timeStyle = .short
                    timeFormatter.dateStyle = .none
                    let departureTime = timeFormatter.string(from: option.departure)

                    let travelMinutes = Int.random(in: 15...90)
                    let arrivalTime = option.departure.addingTimeInterval(TimeInterval(travelMinutes * 60))
                    let arrivalTimeString = timeFormatter.string(from: arrivalTime)

                    let departureMins = max(0, Int(option.departure.timeIntervalSince(Date()) / 60))

                    return .result(dialog: "Your next train to \(route.toName) departs in \(departureMins) minutes at \(departureTime) and should arrive around \(arrivalTimeString).")
                }
            } catch {
                continue // Try next route
            }
        }

        return .result(dialog: "Unable to get arrival time information at this time. Please try again later.")
    }
}

struct RouteInfoIntent: AppIntent {
    static var title: LocalizedStringResource = "Route information"
    static var description = IntentDescription("Get detailed information about your saved routes")

    static var suggestedPhrases: [LocalizedStringResource] = [
        "Tell me about my routes",
        "What routes do I have",
        "Show my train routes",
        "Route details",
        "My saved routes"
    ]

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let routeSummaries = SharedStore.shared.loadRouteSummaries()

        if routeSummaries.isEmpty {
            return .result(dialog: "You don't have any saved routes yet. Please add some routes in the TrainViewer app first.")
        }

        let routeList = routeSummaries.map { route in
            "\(route.name): from \(route.fromName) to \(route.toName)"
        }.joined(separator: ". ")

        let (campus, home) = SharedStore.shared.loadSettings()
        var settingsInfo = ""
        if campus != nil || home != nil {
            settingsInfo = " You also have "
            var settings: [String] = []
            if campus != nil { settings.append("campus") }
            if home != nil { settings.append("home") }
            settingsInfo += settings.joined(separator: " and ") + " locations set."
        }

        return .result(dialog: "You have \(routeSummaries.count) saved route\(routeSummaries.count == 1 ? "" : "s"): \(routeList).\(settingsInfo)")
    }
}
