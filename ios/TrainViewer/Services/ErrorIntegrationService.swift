import Foundation
import SwiftUI
import CoreLocation

// MARK: - Error Integration Service

/// Service that integrates enhanced error handling throughout the app
final class ErrorIntegrationService: ObservableObject {
    static let shared = ErrorIntegrationService()
    
    private let errorRecoveryService = ErrorRecoveryService.shared
    private let errorPresentationService = ErrorPresentationService.shared
    private let errorHandlingService = ErrorHandlingService()
    
    private init() {}
    
    // MARK: - API Integration
    
    /// Enhanced API error handling with automatic recovery
    func handleAPIError(_ error: APIError, context: ErrorContext = .general) async {
        print("🔍 [ErrorIntegrationService] Handling API error: \(error)")
        
        let enhancedError = convertAPIError(error)
        let recoveryResult = await errorRecoveryService.handleError(enhancedError)
        
        await handleRecoveryResult(recoveryResult, for: enhancedError, context: context)
    }
    
    /// Enhanced network error handling
    func handleNetworkError(_ error: URLError, context: ErrorContext = .general) async {
        print("🔍 [ErrorIntegrationService] Handling network error: \(error)")
        
        let enhancedError = convertNetworkError(error)
        let recoveryResult = await errorRecoveryService.handleError(enhancedError)
        
        await handleRecoveryResult(recoveryResult, for: enhancedError, context: context)
    }
    
    /// Enhanced location error handling
    func handleLocationError(_ error: CLError, context: ErrorContext = .locationSearch) async {
        print("🔍 [ErrorIntegrationService] Handling location error: \(error)")
        
        let enhancedError = convertLocationError(error)
        let recoveryResult = await errorRecoveryService.handleError(enhancedError)
        
        await handleRecoveryResult(recoveryResult, for: enhancedError, context: context)
    }
    
    // MARK: - Widget Integration
    
    /// Handle widget-specific errors with enhanced recovery
    func handleWidgetError(_ error: Error, widgetContext: String) async {
        print("🔍 [ErrorIntegrationService] Handling widget error: \(error)")
        
        let enhancedError = EnhancedAppError.widgetConfigurationFailed(reason: widgetContext)
        let recoveryResult = await errorRecoveryService.handleError(enhancedError)
        
        await handleRecoveryResult(recoveryResult, for: enhancedError, context: .widgetConfiguration)
    }
    
    /// Handle widget configuration failures
    func handleWidgetConfigurationFailure(reason: String) async {
        let error = EnhancedAppError.widgetConfigurationFailed(reason: reason)
        await errorPresentationService.presentEnhancedError(error, context: .widgetConfiguration)
    }
    
    // MARK: - Performance Integration
    
    /// Handle performance-related errors
    func handlePerformanceError(_ error: Error) async {
        print("🔍 [ErrorIntegrationService] Handling performance error: \(error)")
        
        let enhancedError = EnhancedAppError.performanceOptimizationFailed
        let recoveryResult = await errorRecoveryService.handleError(enhancedError)
        
        // Performance errors are usually handled silently unless critical
        if case .criticalFailure = recoveryResult {
            await errorPresentationService.presentEnhancedError(enhancedError)
        }
    }
    
    /// Handle memory pressure warnings
    func handleMemoryPressure() async {
        print("⚠️ [ErrorIntegrationService] Handling memory pressure")
        
        let error = EnhancedAppError.memoryPressureCritical
        await errorPresentationService.presentEnhancedError(error)
        
        // Attempt automatic memory cleanup
        await performMemoryCleanup()
    }
    
    /// Handle batch request failures
    func handleBatchRequestFailure(failedUrls: [String]) async {
        print("🔍 [ErrorIntegrationService] Handling batch request failure: \(failedUrls.count) requests")
        
        let error = EnhancedAppError.batchRequestFailed(failedUrls)
        let recoveryResult = await errorRecoveryService.handleError(error)
        
        // Only show user notification for critical batch failures
        if case .criticalFailure = recoveryResult {
            await errorPresentationService.presentEnhancedError(error, context: .backgroundRefresh)
        }
    }
    
    // MARK: - Notification Integration
    
    /// Handle notification scheduling errors
    func handleNotificationError(_ error: Error) async {
        print("🔍 [ErrorIntegrationService] Handling notification error: \(error)")
        
        let enhancedError = EnhancedAppError.notificationSchedulingFailed(error)
        let recoveryResult = await errorRecoveryService.handleError(enhancedError)
        
        await handleRecoveryResult(recoveryResult, for: enhancedError, context: .general)
    }
    
    // MARK: - Data Integration
    
    /// Handle Core Data errors
    func handleDataError(_ error: Error, component: String) async {
        print("🔍 [ErrorIntegrationService] Handling data error in \(component): \(error)")
        
        let enhancedError = EnhancedAppError.dataCorruption(component: component)
        let recoveryResult = await errorRecoveryService.handleError(enhancedError)
        
        await handleRecoveryResult(recoveryResult, for: enhancedError, context: .general)
    }
    
    /// Handle history tracking errors
    func handleHistoryTrackingError(_ error: Error) async {
        print("🔍 [ErrorIntegrationService] Handling history tracking error: \(error)")
        
        let enhancedError = EnhancedAppError.historyTrackingFailed(error)
        let recoveryResult = await errorRecoveryService.handleError(enhancedError)
        
        // History tracking errors are usually handled silently
        if case .criticalFailure = recoveryResult {
            await errorPresentationService.presentEnhancedError(enhancedError)
        }
    }
    
    // MARK: - System Integration
    
    /// Handle system permission errors
    func handlePermissionError(type: PermissionType) async {
        print("🔍 [ErrorIntegrationService] Handling permission error: \(type)")
        
        let enhancedError: EnhancedAppError
        let context: ErrorContext
        
        switch type {
        case .location:
            enhancedError = .locationPermissionDenied
            context = .locationSearch
        case .notifications:
            enhancedError = .notificationSchedulingFailed(NSError(domain: "Permission", code: 1))
            context = .general
        case .backgroundRefresh:
            enhancedError = .backgroundRefreshDisabled
            context = .backgroundRefresh
        }
        
        await errorPresentationService.presentEnhancedError(enhancedError, context: context)
    }
    
    /// Handle haptic feedback unavailability
    func handleHapticFeedbackUnavailable() {
        print("ℹ️ [ErrorIntegrationService] Haptic feedback unavailable")
        
        // This is a low-severity error that doesn't need user intervention
        Task {
            let error = EnhancedAppError.hapticFeedbackUnavailable
            _ = await errorRecoveryService.handleError(error)
        }
    }
    
    // MARK: - Error Conversion Helpers
    
    private func convertAPIError(_ error: APIError) -> EnhancedAppError {
        switch error {
        case .rateLimited(let retryAfter):
            return .apiRateLimited(retryAfter: retryAfter ?? 30.0)
        case .network:
            return .networkTimeout(retryAfter: 15.0)
        case .requestFailed(let status, _) where status >= 500:
            return .criticalServiceUnavailable(service: "Transport API")
        case .decodingFailed:
            return .dataCorruption(component: "API Response")
        case .tooManyRetries:
            return .criticalServiceUnavailable(service: "Transport API")
        default:
            return .criticalServiceUnavailable(service: "API")
        }
    }
    
    private func convertNetworkError(_ error: URLError) -> EnhancedAppError {
        switch error.code {
        case .timedOut:
            return .networkTimeout(retryAfter: 10.0)
        case .notConnectedToInternet, .networkConnectionLost:
            return .criticalServiceUnavailable(service: "Network Connection")
        case .cannotFindHost, .dnsLookupFailed:
            return .criticalServiceUnavailable(service: "DNS Resolution")
        default:
            return .networkTimeout(retryAfter: 15.0)
        }
    }
    
    private func convertLocationError(_ error: CLError) -> EnhancedAppError {
        switch error.code {
        case .denied:
            return .locationPermissionDenied
        case .locationUnknown, .geocodeFoundNoResult:
            return .criticalServiceUnavailable(service: "Location Services")
        case .network:
            return .networkTimeout(retryAfter: 10.0)
        default:
            return .criticalServiceUnavailable(service: "Location Services")
        }
    }
    
    // MARK: - Recovery Result Handling
    
    private func handleRecoveryResult(
        _ result: ErrorRecoveryResult,
        for error: EnhancedAppError,
        context: ErrorContext
    ) async {
        switch result {
        case .recovered:
            print("✅ [ErrorIntegrationService] Error recovered successfully")
            
        case .retryScheduled(let delay):
            print("🔄 [ErrorIntegrationService] Retry scheduled in \(delay)s")
            
        case .userActionRequired(let message):
            print("👤 [ErrorIntegrationService] User action required: \(message)")
            await errorPresentationService.presentEnhancedError(error, context: context)
            
        case .criticalFailure:
            print("💥 [ErrorIntegrationService] Critical failure occurred")
            await errorPresentationService.presentEnhancedError(error, context: context)
            
        case .partialRecovery(let details):
            print("⚠️ [ErrorIntegrationService] Partial recovery: \(details)")
            // For partial recovery, we might show a less prominent notification
        }
    }
    
    // MARK: - Utility Methods
    
    private func performMemoryCleanup() async {
        print("🧹 [ErrorIntegrationService] Performing memory cleanup")
        
        // This would integrate with your performance optimization services
        // For now, we'll simulate cleanup
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Clear caches, reduce memory usage, etc.
        URLCache.shared.removeAllCachedResponses()
        
        print("✅ [ErrorIntegrationService] Memory cleanup completed")
    }
    
    /// Generate comprehensive error report for support
    func generateErrorReport() -> String {
        let diagnosticInfo = errorRecoveryService.generateDiagnosticInfo()
        
        var report = """
        TrainViewer Error Report
        Generated: \(diagnosticInfo.timestamp)
        
        App Information:
        - Version: \(diagnosticInfo.appVersion) (\(diagnosticInfo.buildNumber))
        - iOS Version: \(diagnosticInfo.iOSVersion)
        - Device: \(diagnosticInfo.deviceModel)
        
        System Status:
        - Memory Usage: \(ByteCountFormatter.string(fromByteCount: diagnosticInfo.memoryUsage, countStyle: .memory))
        - Available Memory: \(ByteCountFormatter.string(fromByteCount: diagnosticInfo.availableMemory, countStyle: .memory))
        - Disk Space: \(ByteCountFormatter.string(fromByteCount: diagnosticInfo.diskSpaceAvailable, countStyle: .file))
        - Network: \(diagnosticInfo.networkStatus.rawValue)
        - Battery: \(Int(diagnosticInfo.batteryLevel * 100))%
        - Low Power Mode: \(diagnosticInfo.isLowPowerModeEnabled ? "Yes" : "No")
        - Background Refresh: \(diagnosticInfo.backgroundRefreshStatus)
        
        Recent Errors:
        """
        
        for (index, errorSnapshot) in diagnosticInfo.lastErrors.enumerated() {
            report += """
            
            \(index + 1). \(errorSnapshot.errorType)
               Message: \(errorSnapshot.errorMessage)
               Severity: \(errorSnapshot.severity)
               Time: \(errorSnapshot.timestamp)
               Recovered: \(errorSnapshot.wasRecovered ? "Yes" : "No")
            """
        }
        
        return report
    }
}

// MARK: - Permission Types

enum PermissionType {
    case location
    case notifications
    case backgroundRefresh
    
    var displayName: String {
        switch self {
        case .location:
            return "Location Services"
        case .notifications:
            return "Notifications"
        case .backgroundRefresh:
            return "Background App Refresh"
        }
    }
}

// MARK: - Error Integration Extensions

extension ErrorIntegrationService {
    
    /// Convenience method for handling generic errors with context
    func handleGenericError(_ error: Error, context: ErrorContext = .general) async {
        if let apiError = error as? APIError {
            await handleAPIError(apiError, context: context)
        } else if let urlError = error as? URLError {
            await handleNetworkError(urlError, context: context)
        } else if let locationError = error as? CLError {
            await handleLocationError(locationError, context: context)
        } else {
            // Handle unknown error types
            let enhancedError = EnhancedAppError.criticalServiceUnavailable(service: "Unknown Service")
            await errorPresentationService.presentEnhancedError(enhancedError, context: context)
        }
    }
    
    /// Batch error handling for multiple errors
    func handleMultipleErrors(_ errors: [Error], context: ErrorContext = .general) async {
        if errors.count > 3 {
            // If too many errors, treat as batch failure
            let urls = errors.compactMap { _ in "batch_operation" }
            await handleBatchRequestFailure(failedUrls: urls)
        } else {
            // Handle each error individually
            for error in errors {
                await handleGenericError(error, context: context)
            }
        }
    }
}

// MARK: - SwiftUI Integration

struct ErrorHandlingViewModifier: ViewModifier {
    @ObservedObject private var errorIntegrationService = ErrorIntegrationService.shared
    
    func body(content: Content) -> some View {
        content
            .errorPresentation()
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                Task {
                    await errorIntegrationService.handleMemoryPressure()
                }
            }
    }
}

extension View {
    func enhancedErrorHandling() -> some View {
        modifier(ErrorHandlingViewModifier())
    }
}