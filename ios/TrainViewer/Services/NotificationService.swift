import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    func scheduleLeaveReminder(routeName: String, leaveAt: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "Time to leave"
        content.body = "Leave now for \(routeName)"
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: leaveAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: "leave-\(routeName)-\(leaveAt.timeIntervalSince1970)", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }
}