import Foundation

public enum AppConstants {
    // API URLs
    public static let dbBaseURL = URL(string: "https://v6.db.transport.rest")!
    public static let vbbBaseURL = URL(string: "https://v5.vbb.transport.rest")!

    // Journey results
    public static let defaultResultsCount: Int = 3
    public static let maxResultsCount: Int = 10

    // Walking and timing
    public static let defaultWalkingSpeedMetersPerSecond: Double = 1.31 // Research-backed baseline for outdoor walking
    public static let defaultPreparationBufferMinutes: Int = 3

    // Refresh intervals
    public static let minRefreshInterval: TimeInterval = 30
    public static let defaultRefreshInterval: TimeInterval = 300 // 5 minutes
    public static let maxCacheAge: TimeInterval = 900 // 15 minutes

    // Background tasks
    public static let backgroundTaskIdentifier: String = "com.trainviewer.refresh"

    // Change to your actual App Group if you enable it in both app and widget targets
    public static let appGroupIdentifier: String = "group.com.trainviewer"

    // Legal and support
    public static let privacyPolicyURL = URL(string: "https://example.com/privacy")!
    public static let termsOfServiceURL = URL(string: "https://example.com/terms")!
    public static let supportEmail = "support@example.com"
}