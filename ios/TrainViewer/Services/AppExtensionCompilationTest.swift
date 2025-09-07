import Foundation

// MARK: - App Extension Compilation Test
// This file tests that our error handling services compile correctly in app extension contexts

#if APPEXTENSION
// Simulate app extension environment
class AppExtensionCompilationTest {
    func testErrorHandlingInExtension() {
        // Test EnhancedAppError
        let error = EnhancedAppError.widgetConfigurationFailed(reason: "Test")
        print("Error: \(error.localizedDescription)")
        print("Severity: \(error.severity.displayName)")
        
        // Test ErrorRecoveryService
        let recoveryService = ErrorRecoveryService.shared
        let diagnosticInfo = recoveryService.generateDiagnosticInfo()
        print("Diagnostic info generated: \(diagnosticInfo.timestamp)")
        
        // Test WidgetErrorHandling
        let widgetErrorHandling = WidgetErrorHandling.shared
        widgetErrorHandling.handleWidgetConfigurationError(error, context: "Test")
        
        print("✅ App extension compilation test passed")
    }
}
#else
// Main app compilation test
class MainAppCompilationTest {
    func testErrorHandlingInMainApp() {
        // Test EnhancedAppError
        let error = EnhancedAppError.locationPermissionDenied
        print("Error: \(error.localizedDescription)")
        print("Severity: \(error.severity.displayName)")
        
        // Test ErrorRecoveryService
        let recoveryService = ErrorRecoveryService.shared
        let diagnosticInfo = recoveryService.generateDiagnosticInfo()
        print("Diagnostic info generated: \(diagnosticInfo.timestamp)")
        
        // Test ErrorSeverity color (only available in main app)
        #if !APPEXTENSION
        let color = error.severity.color
        print("Error color: \(color)")
        #endif
        
        print("✅ Main app compilation test passed")
    }
}
#endif