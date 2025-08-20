import Foundation
import BackgroundTasks
import UIKit

// Protocol for journey service to avoid circular imports
protocol JourneyServiceProtocol {
    // Empty protocol for now - can be extended as needed
}

final class BackgroundRefreshService {
    static let shared = BackgroundRefreshService()
    private init() {}

    static let taskIdentifier = "com.yourcompany.trainviewer.refresh"
    
    private var smartJourneyService: JourneyServiceProtocol?
    private var lastRefreshDate: Date?
    
    // MARK: - Background Task Registration
    
    func register() {
        print("🔧 [BackgroundRefreshService] Registering background task handlers")

        #if os(iOS) && !targetEnvironment(macCatalyst) && !APP_EXTENSION
        // Additional runtime check to ensure we're not in an extension
        let isExtension = Bundle.main.bundleIdentifier?.contains(".widget") == true ||
                         Bundle.main.bundleIdentifier?.contains(".extension") == true ||
                         Bundle.main.bundleIdentifier?.contains("Watch") == true

        if !isExtension {
            registerBackgroundTasksIfAvailable()
        } else {
            print("ℹ️ [BackgroundRefreshService] Background task registration not available in extensions")
        }
        #else
        print("ℹ️ [BackgroundRefreshService] Background task registration not available in extensions or on this platform")
        #endif
    }
    
    private func registerBackgroundTasksIfAvailable() {
        // Check if we're running in an extension
        #if APP_EXTENSION || targetEnvironment(simulator)
        print("ℹ️ [BackgroundRefreshService] Background task registration not available in extensions or simulator")
        return
        #else
        // Only proceed if we can safely access BGTaskScheduler
        guard let bundleId = Bundle.main.bundleIdentifier,
              !bundleId.contains("widget"),
              !bundleId.contains("extension"),
              !bundleId.contains("Watch") else {
            print("ℹ️ [BackgroundRefreshService] Running in extension, background tasks not available")
            return
        }

        // Additional runtime check for the specific API availability
        guard NSClassFromString("BGTaskScheduler") != nil else {
            print("ℹ️ [BackgroundRefreshService] BGTaskScheduler not available on this platform")
            return
        }

        // Check if we're running in an app extension at runtime
        if ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"]?.contains("widget") == true ||
           ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"]?.contains("extension") == true {
            print("ℹ️ [BackgroundRefreshService] Running in extension context, background tasks not available")
            return
        }

        do {
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: Self.taskIdentifier,
                using: DispatchQueue.global(qos: .background)
            ) { [weak self] task in
                self?.handleAppRefresh(task: task as! BGAppRefreshTask)
            }
            print("✅ [BackgroundRefreshService] Background task handlers registered successfully")
        } catch {
            print("⚠️ [BackgroundRefreshService] Failed to register background task: \(error)")
        }
        #endif
    }
    
    // MARK: - Background Task Scheduling
    
    func schedule() {
        #if !APP_EXTENSION && !targetEnvironment(macCatalyst)
        // Additional runtime check to ensure we're not in an extension
        let isExtension = Bundle.main.bundleIdentifier?.contains(".widget") == true ||
                         Bundle.main.bundleIdentifier?.contains(".extension") == true ||
                         Bundle.main.bundleIdentifier?.contains("Watch") == true ||
                         ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"]?.contains("widget") == true ||
                         ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"]?.contains("extension") == true

        if !isExtension && NSClassFromString("BGTaskScheduler") != nil {
            // Cancel any existing pending task
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskIdentifier)

            let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)

            // Schedule based on user's route usage patterns
            request.earliestBeginDate = calculateNextRefreshTime()

            do {
                try BGTaskScheduler.shared.submit(request)
                print("✅ [BackgroundRefreshService] Background refresh scheduled for: \(request.earliestBeginDate?.description ?? "immediate")")
            } catch {
                print("❌ [BackgroundRefreshService] Failed to schedule background refresh: \(error)")
            }
        } else {
            print("ℹ️ [BackgroundRefreshService] Background task scheduling not available in extensions")
        }
        #else
        print("ℹ️ [BackgroundRefreshService] Background task scheduling not available in extensions or on this platform")
        #endif
    }
    
    func scheduleForRoute(_ route: Route) {
        #if !APP_EXTENSION && !targetEnvironment(macCatalyst)
        // Additional runtime check to ensure we're not in an extension
        let isExtension = Bundle.main.bundleIdentifier?.contains(".widget") == true ||
                         Bundle.main.bundleIdentifier?.contains(".extension") == true ||
                         Bundle.main.bundleIdentifier?.contains("Watch") == true ||
                         ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"]?.contains("widget") == true ||
                         ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"]?.contains("extension") == true

        if !isExtension && NSClassFromString("BGTaskScheduler") != nil {
            // Schedule refresh specifically for a route's next departure
            // This is more precise than general app refresh

            let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)

            // Calculate when this route will next be needed
            let nextRefreshTime = calculateRouteSpecificRefreshTime(for: route)
            request.earliestBeginDate = nextRefreshTime

            do {
                try BGTaskScheduler.shared.submit(request)
                print("✅ [BackgroundRefreshService] Route-specific refresh scheduled for: \(nextRefreshTime)")
            } catch {
                print("❌ [BackgroundRefreshService] Failed to schedule route refresh: \(error)")
            }
        } else {
            print("ℹ️ [BackgroundRefreshService] Route-specific scheduling not available in extensions")
        }
        #else
        print("ℹ️ [BackgroundRefreshService] Route-specific scheduling not available in extensions or on this platform")
        #endif
    }
    
    // MARK: - Background Task Execution
    
    #if os(iOS) && !targetEnvironment(macCatalyst) && !targetEnvironment(simulator) && !APP_EXTENSION
    private func handleAppRefresh(task: BGAppRefreshTask) {
        print("🔄 [BackgroundRefreshService] Background refresh task started")

        // Schedule the next refresh immediately
        schedule()

        // Set up task completion handling
        let refreshOperation = BackgroundRefreshOperation()

        task.expirationHandler = {
            print("⏰ [BackgroundRefreshService] Background task expired, marking as complete")
            refreshOperation.cancel()
            task.setTaskCompleted(success: false)
        }

        // Perform the refresh
        refreshOperation.completionBlock = {
            print("✅ [BackgroundRefreshService] Background refresh completed successfully")
            task.setTaskCompleted(success: !refreshOperation.isCancelled)
        }

        let operationQueue = OperationQueue()
        operationQueue.addOperation(refreshOperation)
    }
    #endif
    
    // MARK: - Refresh Timing Logic
    
    private func calculateNextRefreshTime() -> Date {
        let now = Date()
        
        // Check if we've refreshed recently
        if let lastRefresh = lastRefreshDate,
           now.timeIntervalSince(lastRefresh) < 300 { // 5 minutes minimum
            return now.addingTimeInterval(300) // Wait at least 5 more minutes
        }
        
        // Calculate based on current time and typical usage patterns
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        // Refresh more frequently during commute hours
        let refreshInterval: TimeInterval
        if (hour >= 6 && hour <= 9) || (hour >= 17 && hour <= 20) {
            refreshInterval = 300 // 5 minutes during rush hour
        } else if hour >= 5 && hour <= 23 {
            refreshInterval = 900 // 15 minutes during active hours
        } else {
            refreshInterval = 3600 // 1 hour during night hours
        }
        
        return now.addingTimeInterval(refreshInterval)
    }
    
    private func calculateRouteSpecificRefreshTime(for route: Route) -> Date {
        let now = Date()
        
        // For routes that are used regularly, predict when they'll be needed next
        // This is a simplified heuristic - in a full implementation, you'd analyze usage patterns
        
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentWeekday = calendar.component(.weekday, from: now)
        
        // Predict next usage based on typical commute patterns
        var nextUsageTime = now
        
        if currentWeekday >= 2 && currentWeekday <= 6 { // Monday-Friday
            if currentHour < 7 { // Before morning commute
                nextUsageTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now) ?? now
            } else if currentHour < 18 { // Before evening commute
                nextUsageTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now
            } else { // After evening commute, next morning
                nextUsageTime = calendar.date(byAdding: .day, value: 1, to: now) ?? now
                nextUsageTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: nextUsageTime) ?? now
            }
        } else { // Weekend
            // Less predictable, refresh every 2 hours
            nextUsageTime = now.addingTimeInterval(7200)
        }
        
        // Refresh 10 minutes before predicted usage
        return nextUsageTime.addingTimeInterval(-600)
    }
    
    // MARK: - Manual Refresh Trigger
    
    func triggerManualRefresh() async {
        print("🔄 [BackgroundRefreshService] Manual refresh triggered")
        await performRouteRefresh()
        lastRefreshDate = Date()
    }
    
    // MARK: - Refresh Logic
    
    private func performRouteRefresh() async {
        // This would typically integrate with your route storage and view models
        // For now, it's a placeholder that demonstrates the pattern
        
        print("🔄 [BackgroundRefreshService] Performing background route refresh")
        
        // Example: Refresh active routes
        do {
            // Get routes from storage (simplified)
            // Note: This would need to be implemented based on your actual storage mechanism
            // For now, we'll just log that refresh was attempted
            print("🔄 [BackgroundRefreshService] Background refresh completed")
            
            // Example of how this would work with actual route storage:
            // let routeStore = RouteStore.shared
            // let activeRoutes = routeStore.getActiveRoutes()
            // for route in activeRoutes {
            //     if let smartService = smartJourneyService {
            //         let _ = try await smartService.getJourneyOptions(
            //             from: route.origin,
            //             to: route.destination,
            //             results: 1
            //         )
            //     }
            // }
            
        } catch {
            print("❌ [BackgroundRefreshService] Route refresh failed: \(error)")
        }
    }
    
    // MARK: - Configuration
    
    func configure(with smartJourneyService: JourneyServiceProtocol) {
        self.smartJourneyService = smartJourneyService
    }
}

// MARK: - Background Refresh Operation

private final class BackgroundRefreshOperation: Operation {
    private let backgroundService = BackgroundRefreshService.shared
    
    override func main() {
        guard !isCancelled else { return }
        
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            await backgroundService.triggerManualRefresh()
            semaphore.signal()
        }
        
        semaphore.wait()
    }
}

// MARK: - App Lifecycle Integration

extension BackgroundRefreshService {
    
    /// Call this when the app enters background
    func handleAppDidEnterBackground() {
        print("📱 [BackgroundRefreshService] App entered background, scheduling refresh")
        #if !APP_EXTENSION && !targetEnvironment(macCatalyst)
        // Additional runtime check to ensure we're not in an extension
        let isExtension = Bundle.main.bundleIdentifier?.contains(".widget") == true ||
                         Bundle.main.bundleIdentifier?.contains(".extension") == true ||
                         Bundle.main.bundleIdentifier?.contains("Watch") == true ||
                         ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"]?.contains("widget") == true ||
                         ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"]?.contains("extension") == true

        if !isExtension && NSClassFromString("BGTaskScheduler") != nil {
            schedule()
        } else {
            print("ℹ️ [BackgroundRefreshService] Background scheduling not available in extensions")
        }
        #else
        print("ℹ️ [BackgroundRefreshService] Background scheduling not available in extensions or on this platform")
        #endif
    }
    
    /// Call this when the app becomes active
    func handleAppDidBecomeActive() {
        print("📱 [BackgroundRefreshService] App became active")
        
        // Check if we need an immediate refresh
        if let lastRefresh = lastRefreshDate,
           Date().timeIntervalSince(lastRefresh) > 900 { // 15 minutes
            Task {
                await triggerManualRefresh()
            }
        }
    }
}