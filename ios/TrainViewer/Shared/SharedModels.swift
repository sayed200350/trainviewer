import Foundation

public struct WidgetSnapshot: Codable {
    public let routeId: UUID
    public let routeName: String
    public let leaveInMinutes: Int
    public let departure: Date
    public let arrival: Date

    public init(routeId: UUID, routeName: String, leaveInMinutes: Int, departure: Date, arrival: Date) {
        self.routeId = routeId
        self.routeName = routeName
        self.leaveInMinutes = leaveInMinutes
        self.departure = departure
        self.arrival = arrival
    }
}

public struct RouteSummary: Codable, Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public init(id: UUID, name: String) { self.id = id; self.name = name }
}