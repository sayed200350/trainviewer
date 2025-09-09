import Foundation
import CoreLocation
#if !APPEXTENSION
import UIKit
#endif
import UserNotifications
import ObjectiveC

// MARK: - Enhanced App Error Types

/// Enhanced error types with specific error categories and recovery suggestions
enum EnhancedAppError: LocalizedError, Equatable {
    case widgetConfigurationFailed(reason: String)
    case performanceOptimizationFailed
    case historyTrackingFailed(Error)
    case hapticFeedbackUnavailable
    case batchRequestFailed([String]) // URLs that failed
    case memoryPressureCritical
    case notificationSchedulingFailed(Error)
    case networkTimeout(retryAfter: TimeInterval)
    case apiRateLimited(retryAfter: TimeInterval)
    case locationPermissionDenied
    case invalidRouteConfiguration
    case dataCorruption(component: String)
    case backgroundRefreshDisabled
    case criticalServiceUnavailable(service: String)
    
    var errorDescription: String? {
        switch self {
        case .widgetConfigurationFailed(let reason):
            return "Widget setup failed: \(reason). Please try removing and re-adding the widget."
        case .performanceOptimizationFailed:
            return "Performance optimization temporarily unavailable. App functionality not affected."
        case .historyTrackingFailed:
            return "Journey history tracking paused. Your current routes are not affected."
        case .hapticFeedbackUnavailable:
            return "Haptic feedback not available on this device."
        case .batchRequestFailed(let urls):
            return "Some route updates failed (\(urls.count) requests). Retrying automatically."
        case .memoryPressureCritical:
            return "Low memory detected. Some features temporarily reduced."
        case .notificationSchedulingFailed:
            return "Notification scheduling failed. Check notification permissions in Settings."
        case .networkTimeout(let retryAfter):
            return "Network request timed out. Retrying in \(Int(retryAfter)) seconds."
        case .apiRateLimited(let retryAfter):
            return "Too many requests. Please wait \(Int(retryAfter)) seconds before trying again."
        case .locationPermissionDenied:
            return "Location access denied. Enable location services to use nearby station features."
        case .invalidRouteConfiguration:
            return "Route configuration is invalid. Please reconfigure your routes."
        case .dataCorruption(let component):
            return "Data corruption detected in \(component). Attempting automatic recovery."
        case .backgroundRefreshDisabled:
            return "Background refresh is disabled. Enable it in Settings for automatic updates."
        case .criticalServiceUnavailable(let service):
            return "\(service) service is temporarily unavailable. Please try again later."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .widgetConfigurationFailed:
            return "Go to Settings > Widgets to reconfigure, or contact support if the issue persists."
        case .performanceOptimizationFailed:
            return "Restart the app to re-enable optimizations."
        case .historyTrackingFailed:
            return "Check available storage space and restart the app."
        case .hapticFeedbackUnavailable:
            return "Haptic feedback will be disabled automatically."
        case .batchRequestFailed:
            return "Check your internet connection. Updates will retry automatically."
        case .memoryPressureCritical:
            return "Close other apps to free up memory."
        case .notificationSchedulingFailed:
            return "Enable notifications in iOS Settings > TrainViewer > Notifications."
        case .networkTimeout:
            return "Check your internet connection and try again."
        case .apiRateLimited:
            return "Wait for the specified time before making new requests."
        case .locationPermissionDenied:
            return "Go to Settings > Privacy & Security > Location Services > TrainViewer and enable location access."
        case .invalidRouteConfiguration:
            return "Remove and re-add your routes, or reset app settings."
        case .dataCorruption:
            return "If the problem persists, try reinstalling the app."
        case .backgroundRefreshDisabled:
            return "Go to Settings > General > Background App Refresh and enable it for TrainViewer."
        case .criticalServiceUnavailable:
            return "Check the service status page or try again in a few minutes."
        }
    }
    
    var failureReason: String? {
        switch self {
        case .widgetConfigurationFailed:
            return "Widget configuration data could not be saved or loaded."
        case .performanceOptimizationFailed:
            return "Performance optimization services failed to initialize."
        case .historyTrackingFailed:
            return "Journey history database operations failed."
        case .hapticFeedbackUnavailable:
            return "Device does not support haptic feedback."
        case .batchRequestFailed:
            return "Multiple API requests failed simultaneously."
        case .memoryPressureCritical:
            return "System memory usage is critically high."
        case .notificationSchedulingFailed:
            return "iOS notification system rejected the scheduling request."
        case .networkTimeout:
            return "Network request exceeded timeout limit."
        case .apiRateLimited:
            return "API rate limit exceeded."
        case .locationPermissionDenied:
            return "User denied location access permission."
        case .invalidRouteConfiguration:
            return "Route configuration contains invalid or corrupted data."
        case .dataCorruption:
            return "Stored data integrity check failed."
        case .backgroundRefreshDisabled:
            return "iOS background refresh is disabled for this app."
        case .criticalServiceUnavailable:
            return "Essential service is not responding."
        }
    }
    
    // MARK: - Error Priority and Severity
    
    var severity: ErrorSeverity {
        switch self {
        case .memoryPressureCritical, .dataCorruption, .criticalServiceUnavailable:
            return .critical
        case .widgetConfigurationFailed, .notificationSchedulingFailed, .invalidRouteConfiguration:
            return .high
        case .networkTimeout, .apiRateLimited, .locationPermissionDenied, .backgroundRefreshDisabled:
            return .medium
        case .performanceOptimizationFailed, .historyTrackingFailed, .hapticFeedbackUnavailable, .batchRequestFailed:
            return .low
        }
    }
    
    var canRetryAutomatically: Bool {
        switch self {
        case .networkTimeout, .apiRateLimited, .batchRequestFailed, .performanceOptimizationFailed:
            return true
        case .widgetConfigurationFailed, .historyTrackingFailed, .notificationSchedulingFailed, .dataCorruption:
            return true
        default:
            return false
        }
    }
    
    var retryDelay: TimeInterval? {
        switch self {
        case .networkTimeout(let retryAfter), .apiRateLimited(let retryAfter):
            return retryAfter
        case .batchRequestFailed:
            return 5.0
        case .performanceOptimizationFailed:
            return 10.0
        case .historyTrackingFailed:
            return 15.0
        case .widgetConfigurationFailed:
            return 3.0
        case .notificationSchedulingFailed:
            return 5.0
        case .dataCorruption:
            return 2.0
        default:
            return nil
        }
    }
    
    // MARK: - Equatable Implementation
    
    static func == (lhs: EnhancedAppError, rhs: EnhancedAppError) -> Bool {
        switch (lhs, rhs) {
        case (.widgetConfigurationFailed(let l), .widgetConfigurationFailed(let r)):
            return l == r
        case (.performanceOptimizationFailed, .performanceOptimizationFailed):
            return true
        case (.hapticFeedbackUnavailable, .hapticFeedbackUnavailable):
            return true
        case (.batchRequestFailed(let l), .batchRequestFailed(let r)):
            return l == r
        case (.memoryPressureCritical, .memoryPressureCritical):
            return true
        case (.networkTimeout(let l), .networkTimeout(let r)):
            return l == r
        case (.apiRateLimited(let l), .apiRateLimited(let r)):
            return l == r
        case (.locationPermissionDenied, .locationPermissionDenied):
            return true
        case (.invalidRouteConfiguration, .invalidRouteConfiguration):
            return true
        case (.dataCorruption(let l), .dataCorruption(let r)):
            return l == r
        case (.backgroundRefreshDisabled, .backgroundRefreshDisabled):
            return true
        case (.criticalServiceUnavailable(let l), .criticalServiceUnavailable(let r)):
            return l == r
        default:
            return false
        }
    }
}

// MARK: - Error Severity and Recovery

enum ErrorSeverity: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    var displayName: String {
        switch self {
        case .low: return "Minor Issue"
        case .medium: return "Moderate Issue"
        case .high: return "Important Issue"
        case .critical: return "Critical Issue"
        }
    }
    
    #if !APPEXTENSION
    var color: UIColor {
        switch self {
        case .low: return .systemBlue
        case .medium: return .systemOrange
        case .high: return .systemRed
        case .critical: return .systemPurple
        }
    }
    #endif
}

enum ErrorRecoveryResult {
    case recovered
    case retryScheduled(after: TimeInterval)
    case userActionRequired(message: String)
    case criticalFailure
    case partialRecovery(details: String)
}

// MARK: - Diagnostic Information

struct DiagnosticInfo: Codable {
    let appVersion: String
    let buildNumber: String
    let iOSVersion: String
    let deviceModel: String
    let deviceIdentifier: String
    let memoryUsage: Int64
    let availableMemory: Int64
    let diskSpaceAvailable: Int64
    let networkStatus: NetworkStatus
    let lastErrors: [ErrorSnapshot]
    let timestamp: Date
    let locale: String
    let timezone: String
    let batteryLevel: Float
    let isLowPowerModeEnabled: Bool
    let backgroundRefreshStatus: String
    
    struct ErrorSnapshot: Codable {
        let errorType: String
        let errorMessage: String
        let timestamp: Date
        let severity: String
        let wasRecovered: Bool
    }
    
    enum NetworkStatus: String, Codable {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case offline = "Offline"
        case unknown = "Unknown"
    }
}

// MARK: - Error Recovery Service

final class ErrorRecoveryService {
    static let shared = ErrorRecoveryService()
    
    private var recentErrors: [EnhancedAppError] = []
    private var retryAttempts: [String: Int] = [:]
    private let maxRetryAttempts = 3
    private let errorHistoryLimit = 50
    
    private init() {}
    
    // MARK: - Error Handling and Recovery
    
    func handleError(_ error: EnhancedAppError) async -> ErrorRecoveryResult {
        print("🔍 [ErrorRecoveryService] Handling error: \(error)")
        
        // Add to recent errors
        addToErrorHistory(error)
        
        // Check if we should attempt automatic recovery
        if error.canRetryAutomatically {
            return await attemptAutomaticRecovery(error)
        } else {
            return .userActionRequired(message: error.recoverySuggestion ?? "Manual intervention required")
        }
    }
    
    private func attemptAutomaticRecovery(_ error: EnhancedAppError) async -> ErrorRecoveryResult {
        let errorKey = String(describing: error)
        let currentAttempts = retryAttempts[errorKey, default: 0]
        
        // Check if we've exceeded retry attempts
        if currentAttempts >= maxRetryAttempts {
            print("❌ [ErrorRecoveryService] Max retry attempts exceeded for: \(error)")
            return .criticalFailure
        }
        
        // Increment retry count
        retryAttempts[errorKey] = currentAttempts + 1
        
        // Wait for retry delay if specified
        if let delay = error.retryDelay {
            print("⏳ [ErrorRecoveryService] Waiting \(delay)s before retry attempt \(currentAttempts + 1)")
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Attempt specific recovery based on error type
        switch error {
        case .performanceOptimizationFailed:
            return await recoverPerformanceOptimization()
        case .historyTrackingFailed:
            return await recoverHistoryTracking()
        case .widgetConfigurationFailed:
            return await recoverWidgetConfiguration()
        case .batchRequestFailed(let urls):
            return await recoverBatchRequests(urls)
        case .notificationSchedulingFailed:
            return await recoverNotificationScheduling()
        case .dataCorruption(let component):
            return await recoverDataCorruption(component)
        default:
            return .retryScheduled(after: error.retryDelay ?? 30.0)
        }
    }
    
    // MARK: - Specific Recovery Methods
    
    private func recoverPerformanceOptimization() async -> ErrorRecoveryResult {
        // Attempt to reinitialize performance optimization services
        do {
            // This would integrate with your PerformanceOptimizer
            print("🔧 [ErrorRecoveryService] Attempting to recover performance optimization")
            
            // Simulate recovery attempt
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Reset retry count on success
            retryAttempts.removeValue(forKey: String(describing: EnhancedAppError.performanceOptimizationFailed))
            
            return .recovered
        } catch {
            return .retryScheduled(after: 10.0)
        }
    }
    
    private func recoverHistoryTracking() async -> ErrorRecoveryResult {
        print("🔧 [ErrorRecoveryService] Attempting to recover history tracking")
        
        // Attempt to reinitialize history tracking
        // This would integrate with your JourneyHistoryService
        
        // Check available storage
        let availableSpace = getAvailableDiskSpace()
        if availableSpace < 100_000_000 { // Less than 100MB
            return .userActionRequired(message: "Insufficient storage space. Please free up space and try again.")
        }
        
        // Attempt to recover
        do {
            // Simulate recovery
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            retryAttempts.removeValue(forKey: String(describing: EnhancedAppError.historyTrackingFailed(NSError())))
            return .recovered
        } catch {
            return .retryScheduled(after: 15.0)
        }
    }
    
    private func recoverWidgetConfiguration() async -> ErrorRecoveryResult {
        print("🔧 [ErrorRecoveryService] Attempting to recover widget configuration")
        
        // Attempt to reset and restore widget configuration
        do {
            // This would integrate with your widget configuration system
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            retryAttempts.removeValue(forKey: String(describing: EnhancedAppError.widgetConfigurationFailed(reason: "")))
            return .recovered
        } catch {
            return .userActionRequired(message: "Please remove and re-add your widgets manually.")
        }
    }
    
    private func recoverBatchRequests(_ failedUrls: [String]) async -> ErrorRecoveryResult {
        print("🔧 [ErrorRecoveryService] Attempting to recover \(failedUrls.count) failed requests")
        
        var recoveredCount = 0
        
        // Attempt to retry each failed request individually
        for url in failedUrls {
            do {
                // This would integrate with your APIClient to retry individual requests
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds per request
                recoveredCount += 1
            } catch {
                print("❌ [ErrorRecoveryService] Failed to recover request: \(url)")
            }
        }
        
        if recoveredCount == failedUrls.count {
            retryAttempts.removeValue(forKey: String(describing: EnhancedAppError.batchRequestFailed(failedUrls)))
            return .recovered
        } else if recoveredCount > 0 {
            return .partialRecovery(details: "Recovered \(recoveredCount) of \(failedUrls.count) requests")
        } else {
            return .retryScheduled(after: 5.0)
        }
    }
    
    private func recoverNotificationScheduling() async -> ErrorRecoveryResult {
        print("🔧 [ErrorRecoveryService] Attempting to recover notification scheduling")
        
        // Check notification permissions
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        if settings.authorizationStatus != .authorized {
            return .userActionRequired(message: "Please enable notifications in Settings to receive departure reminders.")
        }
        
        // Attempt to reschedule notifications
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            retryAttempts.removeValue(forKey: String(describing: EnhancedAppError.notificationSchedulingFailed(NSError())))
            return .recovered
        } catch {
            return .retryScheduled(after: 5.0)
        }
    }
    
    private func recoverDataCorruption(_ component: String) async -> ErrorRecoveryResult {
        print("🔧 [ErrorRecoveryService] Attempting to recover data corruption in: \(component)")
        
        // Attempt to rebuild corrupted data
        do {
            // This would integrate with your Core Data stack to rebuild corrupted entities
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds for data recovery
            
            retryAttempts.removeValue(forKey: String(describing: EnhancedAppError.dataCorruption(component: component)))
            return .recovered
        } catch {
            return .userActionRequired(message: "Data corruption detected. Please restart the app or reinstall if the problem persists.")
        }
    }
    
    // MARK: - Diagnostic Information Generation
    
    func generateDiagnosticInfo() -> DiagnosticInfo {
        let processInfo = ProcessInfo.processInfo
        
        // Get device-specific information
        #if !APPEXTENSION
        let device = UIDevice.current
        let iOSVersion = device.systemVersion
        let deviceModel = device.model
        let deviceIdentifier = device.identifierForVendor?.uuidString ?? "Unknown"
        let batteryLevel = device.batteryLevel
        #else
        let iOSVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let deviceModel = "Unknown (App Extension)"
        let deviceIdentifier = "Unknown (App Extension)"
        let batteryLevel: Float = -1.0
        #endif
        
        return DiagnosticInfo(
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
            iOSVersion: iOSVersion,
            deviceModel: deviceModel,
            deviceIdentifier: deviceIdentifier,
            memoryUsage: getMemoryUsage(),
            availableMemory: getAvailableMemory(),
            diskSpaceAvailable: getAvailableDiskSpace(),
            networkStatus: getCurrentNetworkStatus(),
            lastErrors: recentErrors.suffix(10).map { error in
                DiagnosticInfo.ErrorSnapshot(
                    errorType: String(describing: type(of: error)),
                    errorMessage: error.localizedDescription,
                    timestamp: Date(),
                    severity: error.severity.displayName,
                    wasRecovered: retryAttempts[String(describing: error)] == nil
                )
            },
            timestamp: Date(),
            locale: Locale.current.identifier,
            timezone: TimeZone.current.identifier,
            batteryLevel: batteryLevel,
            isLowPowerModeEnabled: processInfo.isLowPowerModeEnabled,
            backgroundRefreshStatus: getBackgroundRefreshStatus()
        )
    }
    
    // MARK: - Error History Management
    
    private func addToErrorHistory(_ error: EnhancedAppError) {
        recentErrors.append(error)
        
        // Keep only recent errors
        if recentErrors.count > errorHistoryLimit {
            recentErrors.removeFirst(recentErrors.count - errorHistoryLimit)
        }
    }
    
    func clearErrorHistory() {
        recentErrors.removeAll()
        retryAttempts.removeAll()
    }
    
    func getRecentErrors(severity: ErrorSeverity? = nil) -> [EnhancedAppError] {
        if let severity = severity {
            return recentErrors.filter { $0.severity == severity }
        }
        return recentErrors
    }
    
    // MARK: - System Information Helpers
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return -1
        }
    }
    
    private func getAvailableMemory() -> Int64 {
        return Int64(ProcessInfo.processInfo.physicalMemory)
    }
    
    private func getAvailableDiskSpace() -> Int64 {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let freeSpace = systemAttributes[.systemFreeSize] as? NSNumber {
                return freeSpace.int64Value
            }
        } catch {
            print("❌ [ErrorRecoveryService] Failed to get disk space: \(error)")
        }
        return -1
    }
    
    private func getCurrentNetworkStatus() -> DiagnosticInfo.NetworkStatus {
        // This would integrate with your network monitoring
        // For now, return a placeholder
        return .unknown
    }
    
        private func getBackgroundRefreshStatus() -> String {
        // Always check if we're in an app extension first
        if Bundle.main.bundlePath.hasSuffix(".appex") {
            return "Not Available (App Extension)"
        }

        // Use NSClassFromString to safely check if UIApplication is available
        guard let uiApplicationClass = NSClassFromString("UIApplication") else {
            return "Not Available (App Extension)"
        }

        let sharedSelector = NSSelectorFromString("sharedApplication")
        guard let methodIMP = class_getMethodImplementation(uiApplicationClass, sharedSelector),
              methodIMP != nil else {
            return "Not Available (App Extension)"
        }

        // Use the Objective-C runtime to safely call the method
        typealias SharedApplicationFunction = @convention(c) (AnyClass, Selector) -> AnyObject?
        let sharedApplicationFunction = unsafeBitCast(methodIMP, to: SharedApplicationFunction.self)
        guard let sharedApplication = sharedApplicationFunction(uiApplicationClass, sharedSelector) else {
            return "Unknown"
        }

        let backgroundRefreshSelector = NSSelectorFromString("backgroundRefreshStatus")
        guard sharedApplication.responds(to: backgroundRefreshSelector) else {
            return "Unknown"
        }

        guard let statusValueUnmanaged = (sharedApplication as AnyObject).perform(backgroundRefreshSelector) else {
            return "Unknown"
        }

        let statusValue = statusValueUnmanaged.takeUnretainedValue() as? Int ?? -1

        switch statusValue {
        case 0: // UIBackgroundRefreshStatus.restricted
            return "Restricted"
        case 1: // UIBackgroundRefreshStatus.denied
            return "Denied"
        case 2: // UIBackgroundRefreshStatus.available
            return "Available"
        default:
            return "Unknown"
        }
    }
}