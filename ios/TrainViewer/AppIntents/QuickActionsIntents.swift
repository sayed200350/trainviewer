import AppIntents
import Foundation

struct NextToCampusIntent: AppIntent {
    static var title: LocalizedStringResource = "Next to campus"
    static var description = IntentDescription("Get the next departure to your campus")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let (campus, _) = SharedStore.shared.loadSettings()
        guard let campus = campus else { return .result(dialog: "Set your campus in Settings first.") }
        guard let last = SharedStore.shared.loadLastLocation() else { return .result(dialog: "Open the app once to capture your location.") }
        let from = Place(rawId: nil, name: "Current Location", latitude: last.lat, longitude: last.lon)
        let api = TransportAPIFactory.shared.make()
        if let option = try? await api.nextJourneyOptions(from: from, to: campus, results: 1).first {
            let mins = max(0, Int(option.departure.timeIntervalSince(Date()) / 60))
            return .result(dialog: "Leave in \(mins) minutes for \(campus.name).")
        }
        return .result(dialog: "No departures found.")
    }
}

struct NextHomeIntent: AppIntent {
    static var title: LocalizedStringResource = "Next home"
    static var description = IntentDescription("Get the next departure to go home")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let (_, home) = SharedStore.shared.loadSettings()
        guard let home = home else { return .result(dialog: "Set your home in Settings first.") }
        guard let last = SharedStore.shared.loadLastLocation() else { return .result(dialog: "Open the app once to capture your location.") }
        let from = Place(rawId: nil, name: "Current Location", latitude: last.lat, longitude: last.lon)
        let api = TransportAPIFactory.shared.make()
        if let option = try? await api.nextJourneyOptions(from: from, to: home, results: 1).first {
            let mins = max(0, Int(option.departure.timeIntervalSince(Date()) / 60))
            return .result(dialog: "Leave in \(mins) minutes to get home.")
        }
        return .result(dialog: "No departures found.")
    }
}