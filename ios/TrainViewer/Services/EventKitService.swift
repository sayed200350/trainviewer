import Foundation
import EventKit

struct CalendarEvent {
    let title: String
    let startDate: Date
    let location: String?
}

final class EventKitService {
    static let shared = EventKitService()
    private init() {}

    private let store = EKEventStore()

    func requestAccess() async -> Bool {
        do {
            return try await store.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    func nextEvent(withinHours: Int = 12, matchingCampus campus: Place?) async -> CalendarEvent? {
        let calendars = store.calendars(for: .event)
        let start = Date()
        let end = Calendar.current.date(byAdding: .hour, value: withinHours, to: start)!
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
        let events = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }
        if let campus = campus {
            // Prefer events whose location mentions campus name
            if let matched = events.first(where: { ($0.location ?? "").localizedCaseInsensitiveContains(campus.name) }) {
                return CalendarEvent(title: matched.title, startDate: matched.startDate, location: matched.location)
            }
        }
        guard let first = events.first else { return nil }
        return CalendarEvent(title: first.title, startDate: first.startDate, location: first.location)
    }
}