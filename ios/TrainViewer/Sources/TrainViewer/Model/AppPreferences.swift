import Foundation

enum WalkingSpeed: String, Codable {
    case slow
    case normal
    case fast
}

struct UserPreferences: Codable {
    var preferredDepartureBufferMins: Int
    var walkingSpeed: WalkingSpeed
    var avoidStairs: Bool
    var use24HourTime: Bool
    var universityName: String?
    var universityLatitude: Double?
    var universityLongitude: Double?

    static let `default` = UserPreferences(
        preferredDepartureBufferMins: 2,
        walkingSpeed: .normal,
        avoidStairs: false,
        use24HourTime: true,
        universityName: nil,
        universityLatitude: nil,
        universityLongitude: nil
    )
}

final class AppPreferences {
    static let shared = AppPreferences()

    private let defaults: UserDefaults
    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private enum Keys {
        static let buffer = "prefs.preferredDepartureBufferMins"
        static let speed = "prefs.walkingSpeed"
        static let avoidStairs = "prefs.avoidStairs"
        static let use24h = "prefs.use24HourTime"
        static let uniName = "prefs.universityName"
        static let uniLat = "prefs.universityLatitude"
        static let uniLng = "prefs.universityLongitude"
    }

    var preferredDepartureBufferMins: Int {
        get { let v = defaults.integer(forKey: Keys.buffer); return v == 0 ? 2 : v }
        set { defaults.set(newValue, forKey: Keys.buffer) }
    }

    var walkingSpeed: WalkingSpeed {
        get {
            guard let raw = defaults.string(forKey: Keys.speed), let v = WalkingSpeed(rawValue: raw) else { return .normal }
            return v
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.speed) }
    }

    var avoidStairs: Bool {
        get { defaults.object(forKey: Keys.avoidStairs) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Keys.avoidStairs) }
    }

    var use24HourTime: Bool {
        get { defaults.object(forKey: Keys.use24h) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.use24h) }
    }

    var universityName: String? {
        get { defaults.string(forKey: Keys.uniName) }
        set { defaults.set(newValue, forKey: Keys.uniName) }
    }

    var universityLocation: (lat: Double, lng: Double)? {
        get {
            let lat = defaults.object(forKey: Keys.uniLat) as? Double
            let lng = defaults.object(forKey: Keys.uniLng) as? Double
            guard let lat, let lng else { return nil }
            return (lat, lng)
        }
        set {
            defaults.set(newValue?.lat, forKey: Keys.uniLat)
            defaults.set(newValue?.lng, forKey: Keys.uniLng)
        }
    }

    func exportToJSON() -> String? {
        let prefs = UserPreferences(
            preferredDepartureBufferMins: preferredDepartureBufferMins,
            walkingSpeed: walkingSpeed,
            avoidStairs: avoidStairs,
            use24HourTime: use24HourTime,
            universityName: universityName,
            universityLatitude: universityLocation?.lat,
            universityLongitude: universityLocation?.lng
        )
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(prefs) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func importFromJSON(_ json: String) {
        guard let data = json.data(using: .utf8) else { return }
        let decoder = JSONDecoder()
        guard let prefs = try? decoder.decode(UserPreferences.self, from: data) else { return }
        preferredDepartureBufferMins = prefs.preferredDepartureBufferMins
        walkingSpeed = prefs.walkingSpeed
        avoidStairs = prefs.avoidStairs
        use24HourTime = prefs.use24HourTime
        universityName = prefs.universityName
        if let lat = prefs.universityLatitude, let lng = prefs.universityLongitude {
            universityLocation = (lat, lng)
        }
    }
}


