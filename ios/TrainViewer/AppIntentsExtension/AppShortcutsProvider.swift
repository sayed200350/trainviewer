import AppIntents
import Foundation

// MARK: - App Shortcuts Provider
struct TrainViewerShortcutsProvider: AppShortcutsProvider {
    @available(iOS 16.0, *)
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: WidgetTrainIntent(),
                phrases: [
                    "When's my train",
                    "My train time",
                    "What's my train time",
                    "When does my train leave",
                    "Check my train",
                    "My train departure",
                    "What's my next train"
                ],
                shortTitle: "My Train",
                systemImageName: "tram.fill"
            ),

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
                    "When's school train",
                    "When is my train to campus",
                    "My train to campus",
                    "Train to campus",
                    "Campus train time",
                    "When's campus train"
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
                    "When's home train",
                    "When is my train home",
                    "My train home",
                    "Train home",
                    "Home train time"
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
            ),

            AppShortcut(
                intent: TrainStatusIntent(),
                phrases: [
                    "Train status",
                    "Are my trains delayed",
                    "Check train delays",
                    "Train delay information",
                    "Is my train on time",
                    "Train schedule status"
                ],
                shortTitle: "Train Status",
                systemImageName: "exclamationmark.triangle.fill"
            ),

            AppShortcut(
                intent: TrainArrivalIntent(),
                phrases: [
                    "When will my train arrive",
                    "Train arrival time",
                    "When does my train get there",
                    "Arrival time for my train",
                    "When will I arrive",
                    "Train ETA"
                ],
                shortTitle: "Train Arrival",
                systemImageName: "clock.fill"
            ),

            AppShortcut(
                intent: RouteInfoIntent(),
                phrases: [
                    "Tell me about my routes",
                    "What routes do I have",
                    "Show my train routes",
                    "Route details",
                    "My saved routes"
                ],
                shortTitle: "My Routes",
                systemImageName: "map.fill"
            )
        ]
    }
}

// MARK: - App Intents Configuration
struct TrainViewerAppIntentsExtension: AppIntentsPackage {
    static var includedPackages: [AppIntentsPackage.Type] = []

    static var includedIntents: [any AppIntent.Type] = [
        WidgetTrainIntent.self,
        NextToCampusIntent.self,
        NextHomeIntent.self,
        NextTrainIntent.self,
        SiriDebugIntent.self,
        TrainStatusIntent.self,
        TrainArrivalIntent.self,
        RouteInfoIntent.self
    ]

    static var suggestedEntities: [any AppEntity.Type] = []

    init() {}
}
