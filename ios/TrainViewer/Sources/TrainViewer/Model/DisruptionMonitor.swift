import Foundation
import CoreLocation
import UserNotifications

final class DisruptionMonitor {
    static let shared = DisruptionMonitor()
    private let api: TransitAPI
    private init(api: TransitAPI = TransitAPIProvider.shared.api) { self.api = api }

    func requestNotificationAuth() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func detectDelay(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        plannedDeparture: Date,
        thresholdMinutes: Int = 5
    ) async -> Int? {
        let list = (try? await api.fetchNextDepartures(origin: origin, destination: destination, limit: 1)) ?? []
        guard let next = list.first else { return nil }
        let delta = Int(next.departureTime.timeIntervalSince(plannedDeparture) / 60)
        let delay = max(delta, next.delayMinutes ?? 0)
        return delay >= thresholdMinutes ? delay : nil
    }

    func checkForDisruption(
        routeId: String,
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        plannedDeparture: Date,
        thresholdMinutes: Int = 5
    ) async {
        let list = (try? await api.fetchNextDepartures(origin: origin, destination: destination, limit: 1)) ?? []
        guard let next = list.first else { return }
        let delay = max(0, Int(next.departureTime.timeIntervalSince(plannedDeparture) / 60))
        if delay >= thresholdMinutes || (next.delayMinutes ?? 0) >= thresholdMinutes {
            await notifyDelay(routeId: routeId, delayMinutes: max(delay, next.delayMinutes ?? 0))
        }
    }

    @MainActor
    private func notifyDelay(routeId: String, delayMinutes: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Transit Delay Detected"
        content.body = "Your next journey is delayed by +\(delayMinutes) min."
        content.userInfo = ["routeId": routeId]
        let request = UNNotificationRequest(identifier: "delay_\(routeId)_\(UUID().uuidString)", content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}


