import Foundation
import UserNotifications
import SwiftUI

/// Service for managing semester ticket renewal notifications
final class SemesterTicketNotificationService {
    static let shared = SemesterTicketNotificationService()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard

    // Notification preference keys
    private let notificationEnabledKey = "semesterTicket.notifications.enabled"
    private let notificationDaysBeforeKey = "semesterTicket.notifications.daysBefore"
    private let lastNotificationCheckKey = "semesterTicket.notifications.lastCheck"

    private init() {}

    // MARK: - Notification Preferences

    /// Check if notifications are enabled
    var notificationsEnabled: Bool {
        get { userDefaults.bool(forKey: notificationEnabledKey) }
        set {
            userDefaults.set(newValue, forKey: notificationEnabledKey)
            if newValue {
                scheduleAllRenewalNotifications()
            } else {
                cancelAllRenewalNotifications()
            }
        }
    }

    /// Days before expiry to send notifications
    var notificationDaysBefore: [Int] {
        get {
            let saved = userDefaults.array(forKey: notificationDaysBeforeKey) as? [Int]
            return saved ?? [30, 14, 7, 1] // Default: 30, 14, 7, and 1 day before
        }
        set {
            userDefaults.set(newValue, forKey: notificationDaysBeforeKey)
            if notificationsEnabled {
                scheduleAllRenewalNotifications()
            }
        }
    }

    // MARK: - Notification Scheduling

    /// Schedule renewal notifications for a specific ticket
    func scheduleRenewalNotifications(for ticket: SemesterTicket) async {
        guard notificationsEnabled else { return }

        // Cancel existing notifications for this ticket first
        await cancelRenewalNotifications(for: ticket.id)

        // Schedule new notifications
        for daysBefore in notificationDaysBefore {
            await scheduleNotification(for: ticket, daysBeforeExpiry: daysBefore)
        }
    }

    /// Schedule all renewal notifications for all tickets
    func scheduleAllRenewalNotifications() {
        guard notificationsEnabled else { return }

        Task {
            let result = SemesterTicketService.shared.fetchAllTickets()

            switch result {
            case .success(let tickets):
                for ticket in tickets {
                    await scheduleRenewalNotifications(for: ticket)
                }
            case .failure(let error):
                print("Failed to fetch tickets for notifications: \(error)")
            }
        }
    }

    /// Cancel all renewal notifications for a specific ticket
    func cancelRenewalNotifications(for ticketId: UUID) async {
        let identifiers = notificationDaysBefore.map { days in
            "semester-renewal-\(ticketId.uuidString)-\(days)days"
        }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Cancel all renewal notifications
    func cancelAllRenewalNotifications() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["semester-renewal"])
    }

    // MARK: - Notification Creation

    private func scheduleNotification(for ticket: SemesterTicket, daysBeforeExpiry: Int) async {
        guard let expiryDate = Calendar.current.date(byAdding: .day, value: -daysBeforeExpiry, to: ticket.validityEnd) else {
            return
        }

        // Don't schedule notifications for past dates
        guard expiryDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Semester Ticket Expires Soon"
        content.sound = .default
        content.categoryIdentifier = "SEMESTER_TICKET_RENEWAL"

        // Customize message based on days remaining
        switch daysBeforeExpiry {
        case 30:
            content.body = "Your semester ticket for \(ticket.universityName) expires in 30 days. Start planning your renewal!"
            content.subtitle = "30 days remaining"
        case 14:
            content.body = "Your semester ticket for \(ticket.universityName) expires in 2 weeks. Don't forget to renew!"
            content.subtitle = "2 weeks remaining"
        case 7:
            content.body = "Your semester ticket for \(ticket.universityName) expires in 1 week. Time to renew!"
            content.subtitle = "1 week remaining"
        case 1:
            content.body = "⚠️ Your semester ticket for \(ticket.universityName) expires tomorrow!"
            content.subtitle = "Expires tomorrow"
        default:
            content.body = "Your semester ticket for \(ticket.universityName) expires in \(daysBeforeExpiry) days."
            content.subtitle = "\(daysBeforeExpiry) days remaining"
        }

        // Add user info for deep linking
        content.userInfo = [
            "ticketId": ticket.id.uuidString,
            "universityName": ticket.universityName,
            "daysBeforeExpiry": daysBeforeExpiry
        ]

        let components = Calendar.current.dateComponents([.year, .month, .day], from: expiryDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let identifier = "semester-renewal-\(ticket.id.uuidString)-\(daysBeforeExpiry)days"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            print("Scheduled renewal notification for \(ticket.universityName) - \(daysBeforeExpiry) days before expiry")
        } catch {
            print("Failed to schedule renewal notification: \(error)")
        }
    }

    // MARK: - Notification Management

    /// Update notifications when a ticket is created or updated
    func handleTicketChange(_ ticket: SemesterTicket) {
        guard notificationsEnabled else { return }

        Task {
            await scheduleRenewalNotifications(for: ticket)
        }
    }

    /// Remove notifications when a ticket is deleted
    func handleTicketDeletion(ticketId: UUID) {
        Task {
            await cancelRenewalNotifications(for: ticketId)
        }
    }

    /// Check and reschedule notifications if needed (call this periodically)
    func refreshNotificationsIfNeeded() {
        let lastCheck = userDefaults.object(forKey: lastNotificationCheckKey) as? Date ?? .distantPast
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()

        // Only refresh if we haven't checked in the last day
        guard lastCheck < oneDayAgo else { return }

        userDefaults.set(Date(), forKey: lastNotificationCheckKey)

        if notificationsEnabled {
            scheduleAllRenewalNotifications()
        }
    }

    // MARK: - Notification Categories

    /// Register notification categories for better UX
    func registerNotificationCategories() {
        let renewalAction = UNNotificationAction(
            identifier: "RENEW_NOW",
            title: "Renew Now",
            options: [.foreground]
        )

        let laterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "Remind Me Later",
            options: []
        )

        let renewalCategory = UNNotificationCategory(
            identifier: "SEMESTER_TICKET_RENEWAL",
            actions: [renewalAction, laterAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([renewalCategory])
    }

    // MARK: - Utility Methods

    /// Get pending renewal notifications for debugging
    func getPendingRenewalNotifications() async -> [UNNotificationRequest] {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.filter { $0.identifier.hasPrefix("semester-renewal") }
    }

    /// Format expiry date for display
    func formatExpiryDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }

    /// Check if notifications are authorized
    func checkNotificationAuthorization() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus == .authorized
    }
}

// MARK: - Notification Preferences View Model
class SemesterTicketNotificationViewModel: ObservableObject {
    @Published var notificationsEnabled = false
    @Published var selectedDays = [30, 14, 7, 1]
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let service = SemesterTicketNotificationService.shared
    private let availableDays = [60, 45, 30, 21, 14, 7, 3, 1]

    init() {
        loadSettings()
        checkAuthorization()
    }

    func loadSettings() {
        notificationsEnabled = service.notificationsEnabled
        selectedDays = service.notificationDaysBefore
    }

    func checkAuthorization() {
        Task {
            let status = await service.checkNotificationAuthorization()
            await MainActor.run {
                self.authorizationStatus = status ? .authorized : .denied
            }
        }
    }

    func toggleNotifications() {
        service.notificationsEnabled = !notificationsEnabled
        loadSettings() // Refresh from service
    }

    func updateNotificationDays(_ days: [Int]) {
        service.notificationDaysBefore = days
        loadSettings() // Refresh from service
    }

    var availableDaysOptions: [Int] {
        availableDays
    }

    func isDaySelected(_ day: Int) -> Bool {
        selectedDays.contains(day)
    }

    func toggleDay(_ day: Int) {
        if isDaySelected(day) {
            selectedDays.removeAll { $0 == day }
        } else {
            selectedDays.append(day)
            selectedDays.sort(by: >) // Sort descending
        }
        updateNotificationDays(selectedDays)
    }
}

