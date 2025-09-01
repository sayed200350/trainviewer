import Foundation

public enum AppConstants {
    public static let dbBaseURL = URL(string: "https://v6.db.transport.rest")!
    public static let vbbBaseURL = URL(string: "https://v5.vbb.transport.rest")!

    public static let defaultResultsCount: Int = 3
    public static let defaultWalkingSpeedMetersPerSecond: Double = 1.31 // Research-backed baseline for outdoor walking
    public static let defaultPreparationBufferMinutes: Int = 3

    // Change to your actual App Group if you enable it in both app and widget targets
    public static let appGroupIdentifier: String = "group.com.yourcompany.trainviewer"

    public static let privacyPolicyURL = URL(string: "https://example.com/privacy")!
    public static let termsOfServiceURL = URL(string: "https://example.com/terms")!
    public static let supportEmail = "support@example.com"
}