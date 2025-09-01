import Foundation
import BackgroundTasks
import UIKit

#if !APP_EXTENSION
final class BackgroundRefreshService: BackgroundRefreshProtocol {
    static let shared = BackgroundRefreshService()
    private init() {}

    static let taskIdentifier = "com.trainviewer.refresh"

    private var smartJourneyService: JourneyServiceProtocol?
    private var lastRefreshDate: Date?

    // MARK: - Background Task Registration

    func register() {
        print("🔧 [BackgroundRefreshService] Registering background task handlers")

        #if !APP_EXTENSION
        // Only register background tasks in the main app, not in extensions
        registerBackgroundTasksIfAvailable()
        #else
        print("ℹ️ [BackgroundRefreshService] Background task registration not available in app extensions")
        #endif
    }
    
    #if !APP_EXTENSION
    private func registerBackgroundTasksIfAvailable() {
        // This method only compiles for the main app, not extensions
        guard NSClassFromString("BGTaskScheduler") != nil else {
            print("ℹ️ [BackgroundRefreshService] BGTaskScheduler not available on this platform")
            return
        }
        
        registerBGTaskSchedulerIfAvailable()
    }
    #endif
    
    #if !APP_EXTENSION
    // BGTaskScheduler registration - only works in main app, not extensions
    @objc func registerBGTaskSchedulerIfAvailable() {
        print("✅ [BackgroundRefreshService] BGTaskScheduler registration available in main app")
        
        // Register background app refresh task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }
    #endif
    
    // MARK: - Background Task Scheduling

    func schedule() {
        #if !APP_EXTENSION
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = calculateNextRefreshTime()
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ [BackgroundRefreshService] Background refresh scheduled for \(request.earliestBeginDate?.description ?? "unknown")")
        } catch {
            print("❌ [BackgroundRefreshService] Failed to schedule background refresh: \(error)")
        }
        #else
        print("ℹ️ [BackgroundRefreshService] Background task scheduling not available in app extensions")
        #endif
    }

    func scheduleForRoute(_ route: Any) {
        #if !APP_EXTENSION
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = calculateRouteSpecificRefreshTime(for: route)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ [BackgroundRefreshService] Route-specific refresh scheduled for \(request.earliestBeginDate?.description ?? "unknown")")
        } catch {
            print("❌ [BackgroundRefreshService] Failed to schedule route-specific refresh: \(error)")
        }
        #else
        print("ℹ️ [BackgroundRefreshService] Route-specific scheduling not available in app extensions")
        #endif
    }
    
    // MARK: - Background Task Execution

    #if !APP_EXTENSION
    // Handle background app refresh task - only available in main app
    internal func handleAppRefresh(task: BGAppRefreshTask) {
        print("🔄 [BackgroundRefreshService] Handling background refresh task")
        
        // Schedule the next refresh immediately
        schedule()

        // Set up task completion handling
        let refreshOperation = BackgroundRefreshOperation { [weak self] in
            await self?.triggerManualRefresh()
        }

        // Perform the refresh
        refreshOperation.completionBlock = {
            print("✅ [BackgroundRefreshService] Background refresh completed successfully")
            task.setTaskCompleted(success: true)
        }

        // Handle task expiration
        task.expirationHandler = {
            print("⏰ [BackgroundRefreshService] Background refresh task expired")
            refreshOperation.cancel()
            task.setTaskCompleted(success: false)
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
    
    private func calculateRouteSpecificRefreshTime(for route: Any) -> Date {
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
        print("✅ [BackgroundRefreshService] Manual refresh completed")
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
    private let refreshAction: () async -> Void

    init(refreshAction: @escaping () async -> Void) {
        self.refreshAction = refreshAction
        super.init()
    }

    override func main() {
        guard !isCancelled else { return }

        let semaphore = DispatchSemaphore(value: 0)

        Task {
            await refreshAction()
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
        #if !APP_EXTENSION
        schedule()
        #else
        print("ℹ️ [BackgroundRefreshService] Background scheduling not available in app extensions")
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
#endif
