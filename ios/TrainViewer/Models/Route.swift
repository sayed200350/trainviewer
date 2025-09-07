import Foundation
import CoreLocation
import SwiftUI

public enum RouteColor: String, CaseIterable, Codable {
    case blue, green, orange, red, purple, pink
    
    public var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .purple: return .purple
        case .pink: return .pink
        }
    }
    
    public var displayName: String {
        switch self {
        case .blue: return "Blue"
        case .green: return "Green"
        case .orange: return "Orange"
        case .red: return "Red"
        case .purple: return "Purple"
        case .pink: return "Pink"
        }
    }
}

public enum RefreshInterval: Int, CaseIterable, Codable {
    case manual = 0
    case oneMinute = 1
    case twoMinutes = 2
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    
    public var displayName: String {
        switch self {
        case .manual: return "Manual Only"
        case .oneMinute: return "1 Minute"
        case .twoMinutes: return "2 Minutes"
        case .fiveMinutes: return "5 Minutes"
        case .tenMinutes: return "10 Minutes"
        case .fifteenMinutes: return "15 Minutes"
        }
    }
    
    public var timeInterval: TimeInterval {
        return TimeInterval(rawValue * 60)
    }
}

public struct Route: Identifiable, Hashable, Codable {
    public let id: UUID
    public var name: String

    public var origin: Place
    public var destination: Place

    public var preparationBufferMinutes: Int
    public var walkingSpeedMetersPerSecond: Double
    
    // New MVP features
    public var isWidgetEnabled: Bool
    public var widgetPriority: Int
    public var color: RouteColor
    public var isFavorite: Bool
    public var createdAt: Date
    public var lastUsed: Date
    
    // Enhanced features for task 4
    public var customRefreshInterval: RefreshInterval
    public var usageCount: Int

    public init(id: UUID = UUID(), name: String, origin: Place, destination: Place, 
         preparationBufferMinutes: Int = 3, 
         walkingSpeedMetersPerSecond: Double = 1.4,
         isWidgetEnabled: Bool = false, widgetPriority: Int = 0, 
         color: RouteColor = .blue, isFavorite: Bool = false,
         createdAt: Date = Date(), lastUsed: Date = Date(),
         customRefreshInterval: RefreshInterval = .fiveMinutes, usageCount: Int = 0) {
        self.id = id
        self.name = name
        self.origin = origin
        self.destination = destination
        self.preparationBufferMinutes = preparationBufferMinutes
        self.walkingSpeedMetersPerSecond = walkingSpeedMetersPerSecond
        self.isWidgetEnabled = isWidgetEnabled
        self.widgetPriority = widgetPriority
        self.color = color
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.lastUsed = lastUsed
        self.customRefreshInterval = customRefreshInterval
        self.usageCount = usageCount
    }
    
    // Convenience initializer using AppConstants
    public static func create(id: UUID = UUID(), name: String, origin: Place, destination: Place, 
                             isWidgetEnabled: Bool = false, widgetPriority: Int = 0, 
                             color: RouteColor = .blue, isFavorite: Bool = false,
                             createdAt: Date = Date(), lastUsed: Date = Date(),
                             customRefreshInterval: RefreshInterval = .fiveMinutes, usageCount: Int = 0) -> Route {
        return Route(
            id: id,
            name: name,
            origin: origin,
            destination: destination,
            preparationBufferMinutes: AppConstants.defaultPreparationBufferMinutes,
            walkingSpeedMetersPerSecond: AppConstants.defaultWalkingSpeedMetersPerSecond,
            isWidgetEnabled: isWidgetEnabled,
            widgetPriority: widgetPriority,
            color: color,
            isFavorite: isFavorite,
            createdAt: createdAt,
            lastUsed: lastUsed,
            customRefreshInterval: customRefreshInterval,
            usageCount: usageCount
        )
    }
    
    // Helper method to update last used timestamp and increment usage count
    public mutating func markAsUsed() {
        lastUsed = Date()
        usageCount += 1
    }
    
    // Helper method to toggle favorite status
    public mutating func toggleFavorite() {
        isFavorite.toggle()
    }
    
    // Helper method to update custom refresh interval
    public mutating func updateRefreshInterval(_ interval: RefreshInterval) {
        customRefreshInterval = interval
    }
    
    // Computed property for usage frequency classification
    public var usageFrequency: UsageFrequency {
        let daysSinceCreation = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
        guard daysSinceCreation > 0 else { return .rarely }
        
        let usagePerDay = Double(usageCount) / Double(daysSinceCreation)
        
        if usagePerDay >= 1.0 {
            return .daily
        } else if usagePerDay >= 0.3 {
            return .weekly
        } else if usagePerDay >= 0.1 {
            return .monthly
        } else {
            return .rarely
        }
    }
}

public enum UsageFrequency: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case rarely = "rarely"
    
    public var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .rarely: return "Rarely"
        }
    }
    
    public var sortOrder: Int {
        switch self {
        case .daily: return 0
        case .weekly: return 1
        case .monthly: return 2
        case .rarely: return 3
        }
    }
}

public struct RouteStatistics: Codable {
    public let routeId: UUID
    public let usageCount: Int
    public let usageFrequency: UsageFrequency
    public let lastUsed: Date
    public let createdAt: Date
    public let averageDelayMinutes: Double?
    public let reliabilityScore: Double
    
    public init(routeId: UUID, usageCount: Int, usageFrequency: UsageFrequency, 
                lastUsed: Date, createdAt: Date, averageDelayMinutes: Double? = nil, 
                reliabilityScore: Double = 1.0) {
        self.routeId = routeId
        self.usageCount = usageCount
        self.usageFrequency = usageFrequency
        self.lastUsed = lastUsed
        self.createdAt = createdAt
        self.averageDelayMinutes = averageDelayMinutes
        self.reliabilityScore = reliabilityScore
    }
}

