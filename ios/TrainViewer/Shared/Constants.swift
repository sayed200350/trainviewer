import Foundation

enum AppConstants {
    static let dbBaseURL = URL(string: "https://v6.db.transport.rest")!
    static let vbbBaseURL = URL(string: "https://v5.vbb.transport.rest")!

    static let defaultResultsCount: Int = 3
    static let defaultWalkingSpeedMetersPerSecond: Double = 1.4
    static let defaultPreparationBufferMinutes: Int = 3

    // Change to your actual App Group if you enable it in both app and widget targets
    static let appGroupIdentifier: String = "group.com.yourcompany.trainviewer"
}