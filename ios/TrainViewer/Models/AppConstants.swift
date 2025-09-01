import Foundation

/// Application-wide constants
struct AppConstants {
    /// Default number of journey results to fetch
    static let defaultResultsCount = 3
    
    /// Maximum number of journey results
    static let maxResultsCount = 10
    
    /// Minimum refresh interval in seconds
    static let minRefreshInterval: TimeInterval = 30
    
    /// Default refresh interval in seconds
    static let defaultRefreshInterval: TimeInterval = 300 // 5 minutes
    
    /// Maximum age for cached data in seconds
    static let maxCacheAge: TimeInterval = 900 // 15 minutes
    
    /// Background task identifier
    static let backgroundTaskIdentifier = "com.yourcompany.trainviewer.refresh"
}