import Foundation

enum TicketType: String, Codable, CaseIterable, Identifiable {
    case none
    case deutschlandStudent // €29.40
    case semesterTicket

    var id: String { rawValue }

    var monthlyPriceEUR: Double {
        switch self {
        case .none: return 0
        case .deutschlandStudent: return 29.40
        case .semesterTicket: return 0 // varies per uni; treat as prepaid
        }
    }
}

enum ProviderPreference: String, Codable, CaseIterable, Identifiable {
    case auto
    case db
    case vbb
    var id: String { rawValue }
}

final class UserSettingsStore: ObservableObject {
    static let shared = UserSettingsStore()

    @Published var ticketType: TicketType { didSet { save() } }
    @Published var providerPreference: ProviderPreference { didSet { save() } }
    @Published var examModeEnabled: Bool { didSet { save() } }
    @Published var energySavingMode: Bool { didSet { save() } }
    @Published var nightModePreference: Bool { didSet { save() } }
    @Published var studentVerified: Bool { didSet { save() } }
    @Published var analyticsEnabled: Bool { didSet { save() } }

    @Published var campusPlace: Place? { didSet { save() } }
    @Published var homePlace: Place? { didSet { save() } }

    private let defaults = UserDefaults.standard

    private init() {
        self.ticketType = defaults.decode(key: "settings.ticketType", default: .none)
        self.providerPreference = defaults.decode(key: "settings.providerPreference", default: .auto)
        self.examModeEnabled = defaults.object(forKey: "settings.examModeEnabled") as? Bool ?? false
        self.energySavingMode = defaults.object(forKey: "settings.energySavingMode") as? Bool ?? false
        self.nightModePreference = defaults.object(forKey: "settings.nightModePreference") as? Bool ?? false
        self.studentVerified = defaults.object(forKey: "settings.studentVerified") as? Bool ?? false
        self.analyticsEnabled = defaults.object(forKey: "settings.analyticsEnabled") as? Bool ?? false
        self.campusPlace = defaults.decode(key: "settings.campusPlace", default: Optional<Place>.none)
        self.homePlace = defaults.decode(key: "settings.homePlace", default: Optional<Place>.none)
        SharedStore.shared.saveSettings(campusPlace: campusPlace, homePlace: homePlace)
    }

    private func save() {
        defaults.encode(ticketType, key: "settings.ticketType")
        defaults.encode(providerPreference, key: "settings.providerPreference")
        defaults.set(examModeEnabled, forKey: "settings.examModeEnabled")
        defaults.set(energySavingMode, forKey: "settings.energySavingMode")
        defaults.set(nightModePreference, forKey: "settings.nightModePreference")
        defaults.set(studentVerified, forKey: "settings.studentVerified")
        defaults.set(analyticsEnabled, forKey: "settings.analyticsEnabled")
        defaults.encode(campusPlace, key: "settings.campusPlace")
        defaults.encode(homePlace, key: "settings.homePlace")
        SharedStore.shared.saveSettings(campusPlace: campusPlace, homePlace: homePlace)
    }
}

private extension UserDefaults {
    func encode<T: Encodable>(_ value: T?, key: String) {
        guard let value = value else { removeObject(forKey: key); return }
        let data = try? JSONEncoder().encode(value)
        set(data, forKey: key)
    }
    func decode<T: Decodable>(key: String, default def: T) -> T {
        guard let data = data(forKey: key) else { return def }
        return (try? JSONDecoder().decode(T.self, from: data)) ?? def
    }
}