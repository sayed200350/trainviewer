import Foundation

/// Protocol defining the interface for journey planning services
protocol JourneyServiceProtocol {
    /// Get journey options between two places
    /// - Parameters:
    ///   - from: Starting location
    ///   - to: Destination location
    ///   - currentJourney: Optional existing journey to refresh
    ///   - results: Number of results to return
    /// - Returns: Array of journey options
    func getJourneyOptions(
        from: Place,
        to: Place,
        currentJourney: JourneyOption?,
        results: Int
    ) async throws -> [JourneyOption]
}