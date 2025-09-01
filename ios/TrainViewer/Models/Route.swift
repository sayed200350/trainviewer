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

    public init(id: UUID = UUID(), name: String, origin: Place, destination: Place, 
         preparationBufferMinutes: Int = 3, 
         walkingSpeedMetersPerSecond: Double = 1.4,
         isWidgetEnabled: Bool = false, widgetPriority: Int = 0, 
         color: RouteColor = .blue, isFavorite: Bool = false,
         createdAt: Date = Date(), lastUsed: Date = Date()) {
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
    }
    
    // Convenience initializer using AppConstants
    public static func create(id: UUID = UUID(), name: String, origin: Place, destination: Place, 
                             isWidgetEnabled: Bool = false, widgetPriority: Int = 0, 
                             color: RouteColor = .blue, isFavorite: Bool = false,
                             createdAt: Date = Date(), lastUsed: Date = Date()) -> Route {
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
            lastUsed: lastUsed
        )
    }
    
    // Helper method to update last used timestamp
    public mutating func markAsUsed() {
        lastUsed = Date()
    }
}

public struct JourneyOption: Identifiable, Hashable, Codable {
    public let id: UUID = UUID()
    public let departure: Date
    public let arrival: Date
    public let lineName: String?
    public let platform: String?
    public let delayMinutes: Int?
    public let totalMinutes: Int
    public let warnings: [String]?
    public let refreshToken: String? // For realtime updates
    
    public init(departure: Date, arrival: Date, lineName: String?, platform: String?, delayMinutes: Int?, totalMinutes: Int, warnings: [String]?, refreshToken: String? = nil) {
        self.departure = departure
        self.arrival = arrival
        self.lineName = lineName
        self.platform = platform
        self.delayMinutes = delayMinutes
        self.totalMinutes = totalMinutes
        self.warnings = warnings
        self.refreshToken = refreshToken
    }
    
    /// Check if this journey option can be refreshed
    public var canRefresh: Bool {
        return refreshToken != nil && !refreshToken!.isEmpty
    }
}