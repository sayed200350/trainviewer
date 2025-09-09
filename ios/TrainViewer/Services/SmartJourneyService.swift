import Foundation

/// Smart journey service that optimizes between refresh and full re-planning
final class SmartJourneyService: JourneyServiceProtocol {
    private let transportAPI: TransportAPI
    
    init(transportAPI: TransportAPI) {
        self.transportAPI = transportAPI
    }
    
    /// Get journey options with intelligent refresh vs re-planning logic
    func getJourneyOptions(
        from: Place,
        to: Place,
        currentJourney: JourneyOption? = nil,
        results: Int = AppConstants.defaultResultsCount
    ) async throws -> [JourneyOption] {
        
        // Strategy 1: Try to refresh existing journey if available
        if let current = currentJourney, current.canRefresh {
            do {
                if let refreshed = try await refreshExistingJourney(current) {
                    print("✅ [SmartJourneyService] Successfully refreshed existing journey")
                    return [refreshed]
                }
            } catch {
                print("⚠️ [SmartJourneyService] Refresh failed, falling back to full planning: \(error)")
            }
        }
        
        // Strategy 2: Full journey planning
        print("🔄 [SmartJourneyService] Using full journey planning")
        return try await transportAPI.nextJourneyOptions(from: from, to: to, results: results)
    }
    
    /// Refresh an existing journey with fallback logic
    private func refreshExistingJourney(_ journey: JourneyOption) async throws -> JourneyOption? {
        guard let refreshToken = journey.refreshToken else {
            print("⚠️ [SmartJourneyService] No refresh token available")
            return nil
        }
        
        // Check if journey is still relevant (not too old)
        let maxAge: TimeInterval = 3600 // 1 hour
        if Date().timeIntervalSince(journey.departure) > maxAge {
            print("⚠️ [SmartJourneyService] Journey too old to refresh (\(Date().timeIntervalSince(journey.departure))s)")
            return nil
        }
        
        return try await transportAPI.refreshJourney(refreshToken: refreshToken)
    }
    
    /// Refresh multiple journeys efficiently
    func refreshJourneys(_ journeys: [JourneyOption]) async -> [JourneyOption] {
        let results = await withTaskGroup(of: JourneyOption?.self) { group in
            var refreshedJourneys: [JourneyOption] = []
            
            for journey in journeys {
                if journey.canRefresh {
                    group.addTask {
                        do {
                            return try await self.refreshExistingJourney(journey)
                        } catch {
                            print("⚠️ [SmartJourneyService] Failed to refresh journey: \(error)")
                            return journey // Return original on failure
                        }
                    }
                } else {
                    // Can't refresh, keep original
                    refreshedJourneys.append(journey)
                }
            }
            
            for await result in group {
                if let refreshed = result {
                    refreshedJourneys.append(refreshed)
                }
            }
            
            return refreshedJourneys
        }
        
        return results
    }
}

// MARK: - Journey Comparison and Validation

extension SmartJourneyService {
    
    /// Compare two journeys to detect significant changes
    func hasSignificantChanges(original: JourneyOption, updated: JourneyOption) -> Bool {
        let delayThreshold: Int = 3 // minutes
        let originalDelay = original.delayMinutes ?? 0
        let updatedDelay = updated.delayMinutes ?? 0
        
        // Check for significant delay changes
        if abs(updatedDelay - originalDelay) >= delayThreshold {
            return true
        }
        
        // Check for platform changes
        if original.platform != updated.platform {
            return true
        }
        
        // Check for new warnings
        let originalWarningCount = original.warnings?.count ?? 0
        let updatedWarningCount = updated.warnings?.count ?? 0
        if updatedWarningCount > originalWarningCount {
            return true
        }
        
        // Check for significant departure time changes (beyond normal delays)
        let timeDifference = abs(updated.departure.timeIntervalSince(original.departure))
        if timeDifference > Double(delayThreshold * 60) { // Convert to seconds
            return true
        }
        
        return false
    }
    
    /// Validate that a journey is still viable
    func isJourneyViable(_ journey: JourneyOption) -> Bool {
        let now = Date()
        
        // Journey must not have departed yet (with some buffer)
        let departureBuffer: TimeInterval = 60 // 1 minute buffer
        if journey.departure.timeIntervalSince(now) < -departureBuffer {
            return false
        }
        
        // Journey must not be too far in the future
        let futureLimit: TimeInterval = 24 * 3600 // 24 hours
        if journey.departure.timeIntervalSince(now) > futureLimit {
            return false
        }
        
        // Journey must not have excessive delays
        let maxDelay = 60 // minutes
        if let delay = journey.delayMinutes, delay > maxDelay {
            return false
        }
        
        return true
    }
}

// MARK: - Caching Strategy

extension SmartJourneyService {
    
    /// Create a cache key for journey requests
    func cacheKey(from: Place, to: Place) -> String {
        let fromKey = from.rawId ?? "\(from.latitude ?? 0),\(from.longitude ?? 0)"
        let toKey = to.rawId ?? "\(to.latitude ?? 0),\(to.longitude ?? 0)"
        return "journey:\(fromKey)→\(toKey)"
    }
    
    /// Determine if a cached journey should be refreshed
    func shouldRefreshCache(journey: JourneyOption, cacheAge: TimeInterval) -> Bool {
        let maxCacheAge: TimeInterval
        
        // Closer to departure time = more frequent refreshes
        let timeUntilDeparture = journey.departure.timeIntervalSinceNow
        
        if timeUntilDeparture < 300 { // Less than 5 minutes
            maxCacheAge = 30 // Refresh every 30 seconds
        } else if timeUntilDeparture < 900 { // Less than 15 minutes
            maxCacheAge = 60 // Refresh every minute
        } else if timeUntilDeparture < 3600 { // Less than 1 hour
            maxCacheAge = 300 // Refresh every 5 minutes
        } else {
            maxCacheAge = 600 // Refresh every 10 minutes
        }
        
        return cacheAge > maxCacheAge
    }
}
