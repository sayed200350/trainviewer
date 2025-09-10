//
//  LiveActivityService.swift
//  TrainViewer
//
//  Created by Sayed Mohamed on 10.09.25.
//

import Foundation

/// Service for managing Live Activities for train departures
final class LiveActivityService {
    static let shared = LiveActivityService()

    private init() {}

    /// Start a Live Activity for a train departure
    /// - Parameters:
    ///   - route: The route information
    ///   - departure: The departure information
    ///   - walkingTime: Walking time in minutes
    /// - Returns: The activity ID if successfully started
    func startTrainDepartureActivity(
        routeId: String,
        routeName: String,
        originName: String,
        destinationName: String,
        departureTime: Date,
        arrivalTime: Date,
        platform: String?,
        lineName: String?,
        delayMinutes: Int?,
        walkingTime: Int?
    ) async throws -> String? {

        // Live Activities are only available in widget extension, not main app
        print("ℹ️ Live Activity requested from main app")
        print("🔄 Route: \(routeName), Departure: \(departureTime)")
        print("📱 Live Activities must be managed from widget extension")
        return nil
    }

    /// Update an existing Live Activity
    /// - Parameters:
    ///   - activityId: The activity ID to update
    ///   - routeName: Updated route name
    ///   - leaveInMinutes: Updated leave in minutes
    ///   - departureTime: Updated departure time
    ///   - arrivalTime: Updated arrival time
    ///   - platform: Updated platform
    ///   - lineName: Updated line name
    ///   - delayMinutes: Updated delay minutes
    ///   - walkingTime: Updated walking time
    func updateTrainDepartureActivity(
        activityId: String,
        routeName: String,
        leaveInMinutes: Int,
        departureTime: Date,
        arrivalTime: Date,
        platform: String?,
        lineName: String?,
        delayMinutes: Int?,
        walkingTime: Int?
    ) async {

        // Live Activity updates are only available in widget extension
        print("ℹ️ Live Activity update requested from main app")
        print("🔄 Route: \(routeName), Leave in: \(leaveInMinutes)min")
        print("📱 Live Activity updates must be managed from widget extension")
    }

    /// End a Live Activity
    /// - Parameter activityId: The activity ID to end
    /// - Parameter finalStatus: The final status (e.g., "departed", "cancelled")
    func endTrainDepartureActivity(activityId: String, finalStatus: String = "completed") async {
        // Live Activity ending is only available in widget extension
        print("ℹ️ Live Activity end requested from main app")
        print("🏁 Route: \(activityId), Status: \(finalStatus)")
        print("📱 Live Activity ending must be managed from widget extension")
    }

    /// Get all active Live Activities
    func getActiveActivities() -> [Any] {
        // Live Activity listing is only available in widget extension
        print("ℹ️ Live Activity listing requested from main app")
        print("📱 Live Activity listing must be managed from widget extension")
        return []
    }

    /// End all active Live Activities
    func endAllActivities() async {
        print("ℹ️ End all Live Activities requested")
        // Since we can't access real activities in main app, just log
        print("🚫 ActivityKit not available - cannot end all activities from main app")
    }

    // MARK: - Helper Methods

    private func determineStatus(delayMinutes: Int?, departureTime: Date) -> String {
        if let delay = delayMinutes, delay > 0 {
            return "delayed"
        }

        let timeUntilDeparture = departureTime.timeIntervalSince(Date())
        if timeUntilDeparture <= 0 {
            return "departed"
        }

        return "on-time"
    }

    private func getUpdateMessage(delayMinutes: Int?, leaveInMinutes: Int) -> String {
        if let delay = delayMinutes, delay > 0 {
            return "Train delayed by \(delay) minutes. Leave in \(leaveInMinutes) minutes."
        }

        if leaveInMinutes <= 0 {
            return "Train is departing now!"
        }

        return "Train departs in \(leaveInMinutes) minutes."
    }
}

// MARK: - Convenience Extensions

extension LiveActivityService {


    /// Update Live Activity from RouteStatus
    func updateActivity(activityId: String, from status: RouteStatus, routeName: String) async {
        guard let firstOption = status.options.first else { return }

        await updateTrainDepartureActivity(
            activityId: activityId,
            routeName: routeName,
            leaveInMinutes: status.leaveInMinutes ?? 0,
            departureTime: firstOption.departure,
            arrivalTime: firstOption.arrival,
            platform: firstOption.platform,
            lineName: firstOption.lineName,
            delayMinutes: firstOption.delayMinutes,
            walkingTime: 10 // TODO: Pass route for actual walking time calculation
        )
    }
}
