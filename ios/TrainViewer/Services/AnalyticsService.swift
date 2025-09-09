import Foundation

final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    private var sessionStartTime: Date?

    private var isEnabled: Bool { UserSettingsStore.shared.analyticsEnabled }

    func track(event name: String, properties: [String: String] = [:]) {
        guard isEnabled else { return }
        let payload: [String: Any] = [
            "event": name,
            "properties": properties,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        // For MVP, simply print; swap this for a backend or analytics SDK in production
        print("[Analytics] \(payload)")
    }

    func screen(_ name: String) { track(event: "screen", properties: ["name": name]) }

    func sessionStart() {
        guard isEnabled else { return }
        sessionStartTime = Date()
        track(event: "session_start")
    }

    func sessionEnd() {
        guard isEnabled else { return }
        let end = Date()
        let duration = sessionStartTime.map { Int(end.timeIntervalSince($0)) } ?? 0
        track(event: "session_end", properties: ["duration_s": String(duration)])
        sessionStartTime = nil
    }
}