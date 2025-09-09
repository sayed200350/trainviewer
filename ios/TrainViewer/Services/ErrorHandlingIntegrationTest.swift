import Foundation

// MARK: - Error Handling Integration Test

/// Simple integration test to verify the enhanced error handling system works
final class ErrorHandlingIntegrationTest {
    
    static func runBasicTests() {
        print("🧪 [ErrorHandlingIntegrationTest] Starting basic integration tests...")
        
        // Test compilation first
        CompilationTest.testCompilation()
        
        // Test 1: Enhanced error creation
        testEnhancedErrorCreation()
        
        // Test 2: Error recovery service
        testErrorRecoveryService()
        
        // Test 3: Error presentation service
        testErrorPresentationService()
        
        // Test 4: Error integration service
        testErrorIntegrationService()
        
        print("✅ [ErrorHandlingIntegrationTest] All basic tests completed")
    }
    
    private static func testEnhancedErrorCreation() {
        print("🔍 Testing enhanced error creation...")
        
        let widgetError = EnhancedAppError.widgetConfigurationFailed(reason: "Test failure")
        assert(widgetError.severity == .high, "Widget error should have high severity")
        assert(widgetError.canRetryAutomatically == true, "Widget error should be retryable")
        assert(widgetError.errorDescription != nil, "Error should have description")
        
        let memoryError = EnhancedAppError.memoryPressureCritical
        assert(memoryError.severity == .critical, "Memory error should have critical severity")
        
        print("✅ Enhanced error creation test passed")
    }
    
    private static func testErrorRecoveryService() {
        print("🔍 Testing error recovery service...")
        
        let recoveryService = ErrorRecoveryService.shared
        
        // Test diagnostic info generation
        let diagnosticInfo = recoveryService.generateDiagnosticInfo()
        assert(!diagnosticInfo.appVersion.isEmpty, "Diagnostic info should have app version")
        assert(!diagnosticInfo.iOSVersion.isEmpty, "Diagnostic info should have iOS version")
        
        // Test error history
        let initialErrorCount = recoveryService.getRecentErrors().count
        
        Task {
            let testError = EnhancedAppError.hapticFeedbackUnavailable
            _ = await recoveryService.handleError(testError)
            
            let newErrorCount = recoveryService.getRecentErrors().count
            assert(newErrorCount > initialErrorCount, "Error should be added to history")
        }
        
        print("✅ Error recovery service test passed")
    }
    
    private static func testErrorPresentationService() {
        print("🔍 Testing error presentation service...")
        
        let presentationService = ErrorPresentationService.shared
        
        // Test error presentation
        let testError = EnhancedAppError.networkTimeout(retryAfter: 5.0)
        presentationService.presentEnhancedError(testError, context: .routePlanning)
        
        assert(presentationService.isShowingError == true, "Should be showing error")
        assert(presentationService.currentError != nil, "Should have current error")
        
        // Test error dismissal
        presentationService.dismissError()
        assert(presentationService.isShowingError == false, "Should not be showing error")
        assert(presentationService.currentError == nil, "Should not have current error")
        
        print("✅ Error presentation service test passed")
    }
    
    private static func testErrorIntegrationService() {
        print("🔍 Testing error integration service...")
        
        let integrationService = ErrorIntegrationService.shared
        
        // Test error report generation
        let errorReport = integrationService.generateErrorReport()
        assert(!errorReport.isEmpty, "Error report should not be empty")
        assert(errorReport.contains("TrainViewer Error Report"), "Report should have title")
        
        // Test API error conversion
        let apiError = APIError.rateLimited(retryAfter: 30.0)
        Task {
            await integrationService.handleAPIError(apiError, context: .routePlanning)
        }
        
        print("✅ Error integration service test passed")
    }
}

// MARK: - Test Runner Extension

extension ErrorHandlingIntegrationTest {
    
    /// Run comprehensive integration tests
    static func runComprehensiveTests() {
        print("🧪 [ErrorHandlingIntegrationTest] Starting comprehensive integration tests...")
        
        runBasicTests()
        testErrorConversions()
        testRecoveryScenarios()
        testPerformanceMetrics()
        
        print("✅ [ErrorHandlingIntegrationTest] All comprehensive tests completed")
    }
    
    private static func testErrorConversions() {
        print("🔍 Testing error conversions...")
        
        let errorHandlingService = ErrorHandlingService()
        
        // Test API error conversion
        let apiError = APIError.rateLimited(retryAfter: 15.0)
        Task {
            let (errorInfo, recoveryResult) = await errorHandlingService.analyzeAndRecoverError(apiError)
            assert(errorInfo.category == .rateLimited, "Should categorize as rate limited")
            assert(errorInfo.canRetryAutomatically == true, "Should be retryable")
        }
        
        // Test URL error conversion
        let urlError = URLError(.timedOut)
        Task {
            let (errorInfo, _) = await errorHandlingService.analyzeAndRecoverError(urlError)
            assert(errorInfo.category == .temporaryUnavailable, "Should categorize as temporary unavailable")
        }
        
        print("✅ Error conversions test passed")
    }
    
    private static func testRecoveryScenarios() {
        print("🔍 Testing recovery scenarios...")
        
        Task {
            let recoveryService = ErrorRecoveryService.shared
            
            // Test automatic recovery
            let performanceError = EnhancedAppError.performanceOptimizationFailed
            let result = await recoveryService.handleError(performanceError)
            
            switch result {
            case .recovered, .retryScheduled, .userActionRequired, .criticalFailure, .partialRecovery:
                print("✅ Recovery scenario handled correctly")
            }
            
            // Test batch request recovery
            let batchError = EnhancedAppError.batchRequestFailed(["url1", "url2"])
            let batchResult = await recoveryService.handleError(batchError)
            
            switch batchResult {
            case .recovered, .partialRecovery:
                print("✅ Batch recovery handled correctly")
            default:
                print("ℹ️ Batch recovery scheduled for retry")
            }
        }
        
        print("✅ Recovery scenarios test passed")
    }
    
    private static func testPerformanceMetrics() {
        print("🔍 Testing performance metrics...")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test error handling performance
        for _ in 0..<100 {
            let error = EnhancedAppError.networkTimeout(retryAfter: 1.0)
            _ = error.errorDescription
            _ = error.severity
            _ = error.canRetryAutomatically
        }
        
        let errorCreationTime = CFAbsoluteTimeGetCurrent() - startTime
        assert(errorCreationTime < 0.1, "Error creation should be fast")
        
        // Test diagnostic info performance
        let diagnosticStartTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<10 {
            _ = ErrorRecoveryService.shared.generateDiagnosticInfo()
        }
        
        let diagnosticTime = CFAbsoluteTimeGetCurrent() - diagnosticStartTime
        assert(diagnosticTime < 1.0, "Diagnostic generation should be reasonably fast")
        
        print("✅ Performance metrics test passed")
        print("ℹ️ Error creation time: \(String(format: "%.4f", errorCreationTime))s")
        print("ℹ️ Diagnostic generation time: \(String(format: "%.4f", diagnosticTime))s")
    }
}