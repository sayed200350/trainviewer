import Foundation

/// Represents a single journey history entry with departure, arrival, and performance data
public struct JourneyHistoryEntry: Identifiable, Codable, Hashable {
    public let id: UUID
    public let routeId: UUID
    public let routeName: String
    public let departureTime: Date
    public let arrivalTime: Date
    public let actualDepartureTime: Date?
    public let actualArrivalTime: Date?
    public let delayMinutes: Int
    public let wasSuccessful: Bool
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        routeId: UUID,
        routeName: String,
        departureTime: Date,
        arrivalTime: Date,
        actualDepartureTime: Date? = nil,
        actualArrivalTime: Date? = nil,
        delayMinutes: Int = 0,
        wasSuccessful: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.routeId = routeId
        self.routeName = routeName
        self.departureTime = departureTime
        self.arrivalTime = arrivalTime
        self.actualDepartureTime = actualDepartureTime
        self.actualArrivalTime = actualArrivalTime
        self.delayMinutes = delayMinutes
        self.wasSuccessful = wasSuccessful
        self.createdAt = createdAt
    }
    
    /// Duration of the planned journey
    public var plannedDuration: TimeInterval {
        arrivalTime.timeIntervalSince(departureTime)
    }
    
    /// Duration of the actual journey (if available)
    public var actualDuration: TimeInterval? {
        guard let actualDeparture = actualDepartureTime,
              let actualArrival = actualArrivalTime else { return nil }
        return actualArrival.timeIntervalSince(actualDeparture)
    }
    
    /// Whether the journey had any delays
    public var hadDelay: Bool {
        delayMinutes > 0
    }
    
    /// Delay category for statistics
    public var delayCategory: DelayCategory {
        switch delayMinutes {
        case 0:
            return .onTime
        case 1...5:
            return .slightDelay
        case 6...15:
            return .moderateDelay
        default:
            return .significantDelay
        }
    }
    
    /// Time slot for privacy-aware statistics
    public var timeSlot: TimeSlot {
        let hour = Calendar.current.component(.hour, from: departureTime)
        switch hour {
        case 5..<9:
            return .earlyMorning
        case 9..<12:
            return .morning
        case 12..<14:
            return .midday
        case 14..<18:
            return .afternoon
        case 18..<22:
            return .evening
        default:
            return .night
        }
    }
}

/// Aggregated statistics about journey history
public struct JourneyStatistics: Codable {
    public let totalJourneys: Int
    public let averageDelayMinutes: Double
    public let mostUsedRouteId: UUID?
    public let mostUsedRouteName: String?
    public let peakTravelHours: [Int] // Hours of day (0-23)
    public let weeklyPattern: [Int] // Journeys per day of week (0=Sunday)
    public let monthlyTrend: [String: Int] // Month-year keys to journey counts
    public let reliabilityScore: Double // 0.0 to 1.0
    public let onTimePercentage: Double
    public let generatedAt: Date
    
    public init(
        totalJourneys: Int = 0,
        averageDelayMinutes: Double = 0.0,
        mostUsedRouteId: UUID? = nil,
        mostUsedRouteName: String? = nil,
        peakTravelHours: [Int] = [],
        weeklyPattern: [Int] = Array(repeating: 0, count: 7),
        monthlyTrend: [String: Int] = [:],
        reliabilityScore: Double = 1.0,
        onTimePercentage: Double = 100.0,
        generatedAt: Date = Date()
    ) {
        self.totalJourneys = totalJourneys
        self.averageDelayMinutes = averageDelayMinutes
        self.mostUsedRouteId = mostUsedRouteId
        self.mostUsedRouteName = mostUsedRouteName
        self.peakTravelHours = peakTravelHours
        self.weeklyPattern = weeklyPattern
        self.monthlyTrend = monthlyTrend
        self.reliabilityScore = reliabilityScore
        self.onTimePercentage = onTimePercentage
        self.generatedAt = generatedAt
    }
}

/// Time slots for privacy-aware journey tracking
public enum TimeSlot: String, CaseIterable, Codable {
    case earlyMorning = "early_morning"
    case morning = "morning"
    case midday = "midday"
    case afternoon = "afternoon"
    case evening = "evening"
    case night = "night"
    
    public var displayName: String {
        switch self {
        case .earlyMorning: return "Early Morning (5-9 AM)"
        case .morning: return "Morning (9 AM-12 PM)"
        case .midday: return "Midday (12-2 PM)"
        case .afternoon: return "Afternoon (2-6 PM)"
        case .evening: return "Evening (6-10 PM)"
        case .night: return "Night (10 PM-5 AM)"
        }
    }
}

/// Delay categories for statistics
public enum DelayCategory: String, CaseIterable, Codable {
    case onTime = "on_time"
    case slightDelay = "slight_delay"
    case moderateDelay = "moderate_delay"
    case significantDelay = "significant_delay"
    
    public var displayName: String {
        switch self {
        case .onTime: return "On Time"
        case .slightDelay: return "Slight Delay (1-5 min)"
        case .moderateDelay: return "Moderate Delay (6-15 min)"
        case .significantDelay: return "Significant Delay (15+ min)"
        }
    }
    
    public var color: String {
        switch self {
        case .onTime: return "green"
        case .slightDelay: return "yellow"
        case .moderateDelay: return "orange"
        case .significantDelay: return "red"
        }
    }
}

/// Time range options for viewing history
public enum TimeRange: CaseIterable {
    case lastWeek
    case lastMonth
    case lastThreeMonths
    case lastYear
    case all
    
    public var displayName: String {
        switch self {
        case .lastWeek: return "Last Week"
        case .lastMonth: return "Last Month"
        case .lastThreeMonths: return "Last 3 Months"
        case .lastYear: return "Last Year"
        case .all: return "All Time"
        }
    }
    
    public var dateRange: DateInterval? {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .lastWeek:
            guard let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) else { return nil }
            return DateInterval(start: weekAgo, end: now)
        case .lastMonth:
            guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) else { return nil }
            return DateInterval(start: monthAgo, end: now)
        case .lastThreeMonths:
            guard let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) else { return nil }
            return DateInterval(start: threeMonthsAgo, end: now)
        case .lastYear:
            guard let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) else { return nil }
            return DateInterval(start: yearAgo, end: now)
        case .all:
            return nil // No date filtering
        }
    }
}

/// Anonymized journey entry for privacy protection
public struct AnonymizedHistoryEntry: Codable {
    public let routeHash: String // Hashed route identifier
    public let timeSlot: TimeSlot // Generalized time instead of exact time
    public let delayCategory: DelayCategory // Categorized instead of exact delay
    public let dayOfWeek: Int // 0=Sunday, 1=Monday, etc.
    public let monthYear: String // "2024-01" format
    
    public init(from entry: JourneyHistoryEntry) {
        self.routeHash = String(entry.routeId.hashValue)
        self.timeSlot = entry.timeSlot
        self.delayCategory = entry.delayCategory
        
        let calendar = Calendar.current
        self.dayOfWeek = calendar.component(.weekday, from: entry.departureTime) - 1 // Convert to 0-based
        
        let year = calendar.component(.year, from: entry.departureTime)
        let month = calendar.component(.month, from: entry.departureTime)
        self.monthYear = String(format: "%04d-%02d", year, month)
    }
}