import Foundation

/// Protocol defining the interface for transport API services
protocol TransportAPI {
    /// Search for locations matching a query
    /// - Parameters:
    ///   - query: Search query string
    ///   - limit: Maximum number of results to return
    /// - Returns: Array of matching places
    func searchLocations(query: String, limit: Int) async throws -> [Place]
    
    /// Get journey options between two places
    /// - Parameters:
    ///   - from: Starting location
    ///   - to: Destination location
    ///   - results: Number of journey options to return
    /// - Returns: Array of journey options
    func nextJourneyOptions(from: Place, to: Place, results: Int) async throws -> [JourneyOption]
    
    /// Refresh an existing journey with real-time data
    /// - Parameter refreshToken: Token for refreshing the journey
    /// - Returns: Updated journey option, or nil if refresh failed
    func refreshJourney(refreshToken: String) async throws -> JourneyOption?
}