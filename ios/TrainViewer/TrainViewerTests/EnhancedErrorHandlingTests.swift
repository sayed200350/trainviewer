import XCTest
import CoreLocation
@testable import TrainViewer

final class EnhancedErrorHandlingTests: XCTestCase {
    
    var errorRecoveryService: ErrorRecoveryService!
    var errorHandlingService: ErrorHandlingService!
    
    override func setUp() {
        super.setUp()
        errorRecoveryService = ErrorRecoveryService.shared
        errorHandlingService = ErrorHandlingService()
        
        // Clear any previous error history
        errorRecoveryService.clearErrorHistory()
    }
    
    override func tearDown() {
        errorRecoveryService.clearErrorHistory()
        super.tearDown()
    }
    
    // MARK: - Enhanced Error Tests
    
    func testEnhancedErrorProperties() {
        let widgetError = EnhancedAppError.widgetConfigurationFailed(reason: "Invalid configuration")
        
        XCTAssertEqual(widgetError.severity, .high)
        XCTAssertTrue(widgetError.canRetryAutomatically)
        XCTAssertEqual(widgetError.retryDelay, 3.0)
        XCTAssertNotNil(widgetError.errorDescription)
        XCTAssertNotNil(widgetError.recoverySuggestion)
    }
    
    func testErrorSeverityLevels() {
        let lowSeverityError = EnhancedAppError.hapticFeedbackUnavailable
        let mediumSeverityError = EnhancedAppError.networkTimeout(retryAfter: 10.0)
        let highSeverityError = EnhancedAppError.widgetConfigurationFailed(reason: "Test")
        let criticalSeverityError = EnhancedAppError.memoryPressureCritical
        
        XCTAssertEqual(lowSeverityError.severity, .low)
        XCTAssertEqual(mediumSeverityError.severity, .medium)
        XCTAssertEqual(highSeverityError.severity, .high)
        XCTAssertEqual(criticalSeverityError.severity, .critical)
    }
    
    func testErrorEquality() {
        let error1 = EnhancedAppError.widgetConfigurationFailed(reason: "Test")
        let error2 = EnhancedAppError.widgetConfigurationFailed(reason: "Test")
        let error3 = EnhancedAppError.widgetConfigurationFailed(reason: "Different")
        
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }
    
    // MARK: - Error Recovery Tests
    
    func testAutomaticErrorRecovery() async {
        let error = EnhancedAppError.performanceOptimizationFailed
        
        let result = await errorRecoveryService.handleError(error)
        
        switch result {
        case .recovered:
            XCTAssertTrue(true, "Error was successfully recovered")
        case .retryScheduled(let delay):
            XCTAssertGreaterThan(delay, 0, "Retry should be scheduled with positive delay")
        case .userActionRequired:
            XCTAssertTrue(true, "User action required is a valid result")
        case .criticalFailure:
            XCTFail("Should not reach critical failure on first attempt")
        case .partialRecovery:
            XCTAssertTrue(true, "Partial recovery is acceptable")
        }
    }
    
    func testRetryLimitEnforcement() async {
        let error = EnhancedAppError.performanceOptimizationFailed
        
        // Attempt recovery multiple times to test retry limit
        var results: [ErrorRecoveryResult] = []
        
        for _ in 0..<5 {
            let result = await errorRecoveryService.handleError(error)
            results.append(result)
        }
        
        // Should eventually reach critical failure due to retry limit
        let hasCriticalFailure = results.contains { result in
            if case .criticalFailure = result {
                return true
            }
            return false
        }
        
        XCTAssertTrue(hasCriticalFailure, "Should reach critical failure after max retries")
    }
    
    func testBatchRequestRecovery() async {
        let failedUrls = ["https://api1.example.com", "https://api2.example.com"]
        let error = EnhancedAppError.batchRequestFailed(failedUrls)
        
        let result = await errorRecoveryService.handleError(error)
        
        switch result {
        case .recovered, .partialRecovery, .retryScheduled:
            XCTAssertTrue(true, "Batch request recovery attempted")
        default:
            XCTFail("Unexpected recovery result for batch request")
        }
    }
    
    // MARK: - Diagnostic Information Tests
    
    func testDiagnosticInfoGeneration() {
        let diagnosticInfo = errorRecoveryService.generateDiagnosticInfo()
        
        XCTAssertFalse(diagnosticInfo.appVersion.isEmpty)
        XCTAssertFalse(diagnosticInfo.iOSVersion.isEmpty)
        XCTAssertFalse(diagnosticInfo.deviceModel.isEmpty)
        XCTAssertGreaterThanOrEqual(diagnosticInfo.memoryUsage, 0)
        XCTAssertNotNil(diagnosticInfo.timestamp)
        XCTAssertFalse(diagnosticInfo.locale.isEmpty)
        XCTAssertFalse(diagnosticInfo.timezone.isEmpty)
    }
    
    func testErrorHistoryTracking() async {
        let error1 = EnhancedAppError.networkTimeout(retryAfter: 5.0)
        let error2 = EnhancedAppError.hapticFeedbackUnavailable
        
        _ = await errorRecoveryService.handleError(error1)
        _ = await errorRecoveryService.handleError(error2)
        
        let recentErrors = errorRecoveryService.getRecentErrors()
        XCTAssertEqual(recentErrors.count, 2)
        XCTAssertTrue(recentErrors.contains(error1))
        XCTAssertTrue(recentErrors.contains(error2))
    }
    
    func testErrorHistoryFiltering() async {
        let lowError = EnhancedAppError.hapticFeedbackUnavailable
        let highError = EnhancedAppError.widgetConfigurationFailed(reason: "Test")
        
        _ = await errorRecoveryService.handleError(lowError)
        _ = await errorRecoveryService.handleError(highError)
        
        let lowSeverityErrors = errorRecoveryService.getRecentErrors(severity: .low)
        let highSeverityErrors = errorRecoveryService.getRecentErrors(severity: .high)
        
        XCTAssertEqual(lowSeverityErrors.count, 1)
        XCTAssertEqual(highSeverityErrors.count, 1)
        XCTAssertTrue(lowSeverityErrors.contains(lowError))
        XCTAssertTrue(highSeverityErrors.contains(highError))
    }
    
    // MARK: - Error Conversion Tests
    
    func testAPIErrorConversion() async {
        let apiError = APIError.rateLimited(retryAfter: 30.0)
        let (errorInfo, recoveryResult) = await errorHandlingService.analyzeAndRecoverError(apiError)
        
        XCTAssertEqual(errorInfo.category, .rateLimited)
        XCTAssertNotNil(recoveryResult)
    }
    
    func testURLErrorConversion() async {
        let urlError = URLError(.timedOut)
        let (errorInfo, recoveryResult) = await errorHandlingService.analyzeAndRecoverError(urlError)
        
        XCTAssertEqual(errorInfo.category, .temporaryUnavailable)
        XCTAssertNotNil(recoveryResult)
    }
    
    func testLocationErrorConversion() async {
        let locationError = CLError(.denied)
        let (errorInfo, recoveryResult) = await errorHandlingService.analyzeAndRecoverError(locationError)
        
        XCTAssertEqual(errorInfo.category, .invalidInput)
        XCTAssertNotNil(recoveryResult)
    }
    
    // MARK: - Error Presentation Tests
    
    func testPresentableErrorCreation() {
        let error = EnhancedAppError.widgetConfigurationFailed(reason: "Test failure")
        let errorService = ErrorPresentationService.shared
        
        errorService.presentEnhancedError(error, context: .widgetConfiguration)
        
        XCTAssertTrue(errorService.isShowingError)
        XCTAssertNotNil(errorService.currentError)
        XCTAssertEqual(errorService.currentError?.severity, .high)
        XCTAssertEqual(errorService.currentError?.context, .widgetConfiguration)
    }
    
    func testErrorDismissal() {
        let errorService = ErrorPresentationService.shared
        
        errorService.presentEnhancedError(.hapticFeedbackUnavailable)
        XCTAssertTrue(errorService.isShowingError)
        
        errorService.dismissError()
        XCTAssertFalse(errorService.isShowingError)
        XCTAssertNil(errorService.currentError)
    }
    
    // MARK: - Performance Tests
    
    func testErrorHandlingPerformance() {
        measure {
            for _ in 0..<100 {
                let error = EnhancedAppError.networkTimeout(retryAfter: 1.0)
                let _ = error.errorDescription
                let _ = error.recoverySuggestion
                let _ = error.severity
            }
        }
    }
    
    func testDiagnosticInfoPerformance() {
        measure {
            for _ in 0..<10 {
                let _ = errorRecoveryService.generateDiagnosticInfo()
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testMemoryPressureHandling() async {
        let error = EnhancedAppError.memoryPressureCritical
        
        let result = await errorRecoveryService.handleError(error)
        
        // Memory pressure should require user action
        switch result {
        case .userActionRequired:
            XCTAssertTrue(true, "Memory pressure correctly requires user action")
        default:
            XCTFail("Memory pressure should require user action")
        }
    }
    
    func testDataCorruptionRecovery() async {
        let error = EnhancedAppError.dataCorruption(component: "CoreData")
        
        let result = await errorRecoveryService.handleError(error)
        
        // Data corruption should attempt recovery
        switch result {
        case .recovered, .retryScheduled, .userActionRequired:
            XCTAssertTrue(true, "Data corruption recovery attempted")
        default:
            XCTFail("Data corruption should attempt recovery")
        }
    }
    
    func testConcurrentErrorHandling() async {
        let errors = [
            EnhancedAppError.networkTimeout(retryAfter: 1.0),
            EnhancedAppError.performanceOptimizationFailed,
            EnhancedAppError.hapticFeedbackUnavailable
        ]
        
        // Handle multiple errors concurrently
        await withTaskGroup(of: ErrorRecoveryResult.self) { group in
            for error in errors {
                group.addTask {
                    return await self.errorRecoveryService.handleError(error)
                }
            }
            
            var results: [ErrorRecoveryResult] = []
            for await result in group {
                results.append(result)
            }
            
            XCTAssertEqual(results.count, errors.count, "All errors should be handled")
        }
    }
}

// MARK: - Mock Error Recovery Service for Testing

protocol ErrorRecoveryServiceProtocol {
    func handleError(_ error: EnhancedAppError) async -> ErrorRecoveryResult
}

class MockErrorRecoveryService: ErrorRecoveryServiceProtocol {
    var shouldSucceedRecovery = true
    var recoveryDelay: TimeInterval = 0.1

    func handleError(_ error: EnhancedAppError) async -> ErrorRecoveryResult {
        // Simulate recovery delay
        try? await Task.sleep(nanoseconds: UInt64(recoveryDelay * 1_000_000_000))
        
        if shouldSucceedRecovery {
            return .recovered
        } else {
            return .retryScheduled(after: 5.0)
        }
    }
}

// MARK: - Test Utilities

extension EnhancedErrorHandlingTests {
    
    func createTestError(severity: ErrorSeverity) -> EnhancedAppError {
        switch severity {
        case .low:
            return .hapticFeedbackUnavailable
        case .medium:
            return .networkTimeout(retryAfter: 5.0)
        case .high:
            return .widgetConfigurationFailed(reason: "Test")
        case .critical:
            return .memoryPressureCritical
        }
    }
    
    func waitForAsyncOperation(timeout: TimeInterval = 5.0) async {
        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
    }
}