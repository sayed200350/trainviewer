import Foundation
import UIKit
import CoreTelephony

/// Service that manages adaptive refresh intervals based on departure times, battery, and network conditions
final class AdaptiveRefreshService {
    static let shared = AdaptiveRefreshService()
    
    private let networkInfo = CTTelephonyNetworkInfo()
    private var batteryMonitoringEnabled = false
    
    private init() {
        setupBatteryMonitoring()
    }
    
    // MARK: - Battery Monitoring Setup
    
    private func setupBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryMonitoringEnabled = true
    }
    
    // MARK: - Adaptive Refresh Logic
    
    /// Calculate optimal refresh interval for a route based on multiple factors
    func getAdaptiveRefreshInterval(for route: Route, nextDeparture: Date? = nil) -> TimeInterval {
        let baseInterval = route.customRefreshInterval.timeInterval
        
        // Factor 1: Time until departure (increases frequency as departure approaches)
        let departureMultiplier = getDepartureTimeMultiplier(nextDeparture: nextDeparture)
        
        // Factor 2: Battery level (reduces frequency on low battery)
        let batteryMultiplier = getBatteryMultiplier()
        
        // Factor 3: Network conditions (reduces frequency on cellular/poor connection)
        let networkMultiplier = getNetworkMultiplier()
        
        // Factor 4: Usage frequency (more frequent for daily routes)
        let usageMultiplier = getUsageFrequencyMultiplier(for: route)
        
        // Calculate final interval
        let adaptiveInterval = baseInterval * departureMultiplier * batteryMultiplier * networkMultiplier * usageMultiplier
        
        // Ensure reasonable bounds (minimum 30 seconds, maximum 30 minutes)
        let finalInterval = max(30, min(1800, adaptiveInterval))
        
        print("🔄 [AdaptiveRefreshService] Calculated interval for \(route.name):")
        print("   Base: \(baseInterval)s, Departure: \(departureMultiplier)x, Battery: \(batteryMultiplier)x")
        print("   Network: \(networkMultiplier)x, Usage: \(usageMultiplier)x = \(finalInterval)s")
        
        return finalInterval
    }
    
    // MARK: - Departure Time Logic
    
    private func getDepartureTimeMultiplier(nextDeparture: Date?) -> Double {
        guard let departure = nextDeparture else { return 1.0 }
        
        let timeUntilDeparture = departure.timeIntervalSinceNow
        
        // Increase refresh frequency as departure approaches
        if timeUntilDeparture < 300 { // Less than 5 minutes
            return 0.2 // 5x more frequent
        } else if timeUntilDeparture < 600 { // Less than 10 minutes
            return 0.3 // 3.3x more frequent
        } else if timeUntilDeparture < 900 { // Less than 15 minutes
            return 0.5 // 2x more frequent
        } else if timeUntilDeparture < 1800 { // Less than 30 minutes
            return 0.7 // 1.4x more frequent
        } else if timeUntilDeparture < 3600 { // Less than 1 hour
            return 1.0 // Normal frequency
        } else {
            return 1.5 // Less frequent for distant departures
        }
    }
    
    // MARK: - Battery Awareness
    
    private func getBatteryMultiplier() -> Double {
        guard batteryMonitoringEnabled else { return 1.0 }
        
        let batteryLevel = UIDevice.current.batteryLevel
        let batteryState = UIDevice.current.batteryState
        
        // If charging, no need to conserve battery
        if batteryState == .charging || batteryState == .full {
            return 1.0
        }
        
        // Adjust based on battery level
        if batteryLevel < 0.1 { // Less than 10%
            return 3.0 // Much less frequent
        } else if batteryLevel < 0.2 { // Less than 20%
            return 2.0 // Less frequent
        } else if batteryLevel < 0.3 { // Less than 30%
            return 1.5 // Slightly less frequent
        } else {
            return 1.0 // Normal frequency
        }
    }
    
    // MARK: - Network Conditions
    
    private func getNetworkMultiplier() -> Double {
        // Check if on WiFi vs Cellular
        if isOnWiFi() {
            return 1.0 // Normal frequency on WiFi
        } else if isOnCellular() {
            return 1.5 // Less frequent on cellular to save data
        } else {
            return 3.0 // Much less frequent if no connection
        }
    }
    
    private func isOnWiFi() -> Bool {
        // Simple check - in a full implementation, you'd use more sophisticated network detection
        return true // Placeholder - would need proper network detection
    }
    
    private func isOnCellular() -> Bool {
        guard let radioAccessTechnology = networkInfo.serviceCurrentRadioAccessTechnology?.values.first else {
            return false
        }
        
        // Check if we have any cellular connection
        return !radioAccessTechnology.isEmpty
    }
    
    // MARK: - Usage Frequency
    
    private func getUsageFrequencyMultiplier(for route: Route) -> Double {
        switch route.usageFrequency {
        case .daily:
            return 0.8 // More frequent for daily routes
        case .weekly:
            return 1.0 // Normal frequency
        case .monthly:
            return 1.2 // Less frequent for monthly routes
        case .rarely:
            return 1.5 // Much less frequent for rarely used routes
        }
    }
    
    // MARK: - Smart Scheduling
    
    /// Determine if a route should be refreshed now based on various conditions
    func shouldRefreshRoute(_ route: Route, lastRefresh: Date, nextDeparture: Date? = nil) -> Bool {
        let timeSinceLastRefresh = Date().timeIntervalSince(lastRefresh)
        let optimalInterval = getAdaptiveRefreshInterval(for: route, nextDeparture: nextDeparture)
        
        // Always refresh if we've exceeded the optimal interval
        if timeSinceLastRefresh >= optimalInterval {
            return true
        }
        
        // Force refresh if departure is very soon and we haven't refreshed recently
        if let departure = nextDeparture {
            let timeUntilDeparture = departure.timeIntervalSinceNow
            if timeUntilDeparture < 300 && timeSinceLastRefresh > 60 { // 5 minutes until departure, 1 minute since refresh
                return true
            }
        }
        
        return false
    }
    
    /// Get the next scheduled refresh time for a route
    func getNextRefreshTime(for route: Route, lastRefresh: Date, nextDeparture: Date? = nil) -> Date {
        let interval = getAdaptiveRefreshInterval(for: route, nextDeparture: nextDeparture)
        return lastRefresh.addingTimeInterval(interval)
    }
    
    // MARK: - Battery Optimization Suggestions
    
    /// Get battery optimization suggestions for the user
    func getBatteryOptimizationSuggestions() -> [String] {
        var suggestions: [String] = []
        
        let batteryLevel = UIDevice.current.batteryLevel
        let batteryState = UIDevice.current.batteryState
        
        if batteryState != .charging && batteryLevel < 0.2 {
            suggestions.append("Battery is low (\(Int(batteryLevel * 100))%). Consider reducing refresh frequency.")
        }
        
        if !isOnWiFi() && isOnCellular() {
            suggestions.append("Using cellular data. Refresh intervals have been increased to save data.")
        }
        
        return suggestions
    }
    
    // MARK: - Performance Metrics
    
    /// Calculate refresh efficiency score (0.0 to 1.0)
    func getRefreshEfficiencyScore(for route: Route) -> Double {
        let baseScore = 1.0
        
        // Reduce score based on battery usage
        let batteryMultiplier = getBatteryMultiplier()
        let batteryScore = 1.0 / batteryMultiplier
        
        // Reduce score based on network usage
        let networkMultiplier = getNetworkMultiplier()
        let networkScore = 1.0 / networkMultiplier
        
        // Combine scores
        return baseScore * batteryScore * networkScore
    }
}

// MARK: - Refresh Strategy

extension AdaptiveRefreshService {
    
    /// Get recommended refresh strategy for a route
    func getRefreshStrategy(for route: Route, nextDeparture: Date? = nil) -> RefreshStrategy {
        let interval = getAdaptiveRefreshInterval(for: route, nextDeparture: nextDeparture)
        let batteryLevel = UIDevice.current.batteryLevel
        let isCharging = UIDevice.current.batteryState == .charging
        
        if interval <= 60 {
            return .aggressive
        } else if interval <= 300 {
            return .normal
        } else if batteryLevel < 0.2 && !isCharging {
            return .conservative
        } else {
            return .balanced
        }
    }
}

enum RefreshStrategy: String, CaseIterable {
    case aggressive = "aggressive"
    case normal = "normal"
    case balanced = "balanced"
    case conservative = "conservative"
    
    var displayName: String {
        switch self {
        case .aggressive: return "Aggressive (High Frequency)"
        case .normal: return "Normal"
        case .balanced: return "Balanced"
        case .conservative: return "Conservative (Battery Saving)"
        }
    }
    
    var description: String {
        switch self {
        case .aggressive: return "Updates every 30-60 seconds near departure time"
        case .normal: return "Updates every 2-5 minutes based on conditions"
        case .balanced: return "Balances freshness with battery and data usage"
        case .conservative: return "Minimizes updates to preserve battery"
        }
    }
}