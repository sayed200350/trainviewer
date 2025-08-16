import Foundation

/// A simple test runner for validating app functionality
/// This can be used during development to ensure features work correctly
final class TestRunner {
    
    /// Run all available tests and return a summary
    static func runAllTests() -> String {
        var results: [String] = []
        
        // Run LocationService validation
        let locationReport = LocationServiceValidator.validateLocationService()
        results.append("LocationService: \(locationReport.passedTests)/\(locationReport.totalTests) tests passed")
        
        // Run Map Component tests
        let mapReport = MapComponentValidator.validateMapComponents()
        results.append("MapComponents: \(mapReport.passedTests)/\(mapReport.totalTests) tests passed")
        
        return results.joined(separator: "\n")
    }
    
    /// Run LocationService tests specifically
    static func runLocationServiceTests() -> LocationServiceValidator.ValidationReport {
        return LocationServiceValidator.validateLocationService()
    }
    
    /// Run Map Component tests specifically
    static func runMapComponentTests() -> MapComponentValidator.ValidationReport {
        return MapComponentValidator.validateMapComponents()
    }
    
    /// Run compilation validation
    static func runCompilationValidation() {
        CompilationValidator.runAllValidations()
    }
    
    /// Run build validation
    static func runBuildValidation() -> Bool {
        return BuildValidator.runAllValidations()
    }
    
    /// Print detailed test results to console
    static func printDetailedTestResults() {
        print("🧪 Running Test Suite...")
        
        let locationReport = LocationServiceValidator.validateLocationService()
        LocationServiceValidator.printValidationReport(locationReport)
        
        let mapReport = MapComponentValidator.validateMapComponents()
        MapComponentValidator.printValidationReport(mapReport)
        
        // Summary
        let totalTests = locationReport.totalTests + mapReport.totalTests
        let totalPassed = locationReport.passedTests + mapReport.passedTests
        let overallSuccess = Double(totalPassed) / Double(totalTests) * 100
        
        print("📊 Overall Test Summary:")
        print("   Tests Run: \(totalTests)")
        print("   Passed: \(totalPassed)")
        print("   Failed: \(totalTests - totalPassed)")
        print("   Success Rate: \(String(format: "%.1f", overallSuccess))%")
        
        if overallSuccess >= 90 {
            print("🎉 Excellent! All core functionality is working properly.")
        } else if overallSuccess >= 75 {
            print("⚠️  Good, but some issues need attention.")
        } else {
            print("🚨 Critical issues detected. Please review failed tests.")
        }
    }
}

#if DEBUG
extension TestRunner {
    /// Development helper to run tests from anywhere in the app
    static func runTestsInDevelopment() {
        DispatchQueue.global(qos: .background).async {
            printDetailedTestResults()
        }
    }
}
#endif