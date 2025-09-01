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
    
    /// Debug API calls and departure calculations
    @MainActor
    static func debugDepartureCalculations() async {
        print("🔍 [TestRunner] Starting departure calculation debugging...")
        
        let routesViewModel = RoutesViewModel()
        routesViewModel.loadRoutes()
        
        if routesViewModel.routes.isEmpty {
            print("⚠️ [TestRunner] No routes found. Please add a route first.")
            return
        }
        
        print("🔍 [TestRunner] Found \(routesViewModel.routes.count) routes:")
        for route in routesViewModel.routes {
            print("🔍 [TestRunner] - \(route.name): \(route.origin.name) → \(route.destination.name)")
        }
        
        print("🔍 [TestRunner] Starting refresh to trigger API calls...")
        await routesViewModel.refreshAll()
        
        print("🔍 [TestRunner] Debugging complete. Check console output above for details.")
    }
    
    /// Test a specific route with detailed debugging
    @MainActor
    static func testSpecificRoute(routeName: String) async {
        print("🔍 [TestRunner] Testing specific route: \(routeName)")
        
        let routesViewModel = RoutesViewModel()
        routesViewModel.loadRoutes()
        
        guard let route = routesViewModel.routes.first(where: { $0.name == routeName }) else {
            print("❌ [TestRunner] Route '\(routeName)' not found. Available routes:")
            for route in routesViewModel.routes {
                print("   - \(route.name)")
            }
            return
        }
        
        print("🔍 [TestRunner] Testing route: \(route.name)")
        print("🔍 [TestRunner] Origin: \(route.origin.name) (\(route.origin.rawId ?? "no ID"))")
        print("🔍 [TestRunner] Destination: \(route.destination.name) (\(route.destination.rawId ?? "no ID"))")
        
        let api = TransportAPIFactory.createAPI()
        do {
            let options = try await api.nextJourneyOptions(
                from: route.origin, 
                to: route.destination, 
                results: 5
            )
            print("✅ [TestRunner] Successfully got \(options.count) options")
            
            let status = routesViewModel.computeStatus(for: route, options: options)
            print("✅ [TestRunner] Final status - Leave in: \(status.leaveInMinutes ?? 0) minutes")
            
        } catch {
            print("❌ [TestRunner] API call failed: \(error)")
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
    
    /// Quick debugging helper for departure calculations
    static func quickDebug() async {
        print("🚀 [TestRunner] Quick debugging started...")
        await debugDepartureCalculations()
    }
    
    /// Test the new best journey selection logic
    @MainActor
    static func testBestJourneySelection() async {
        print("🎯 [TestRunner] Testing best journey selection...")
        
        let routesViewModel = RoutesViewModel()
        routesViewModel.loadRoutes()
        
        guard let firstRoute = routesViewModel.routes.first else {
            print("❌ [TestRunner] No routes found to test")
            return
        }
        
        print("🎯 [TestRunner] Testing route: \(firstRoute.name)")
        print("🎯 [TestRunner] From: \(firstRoute.origin.name) to: \(firstRoute.destination.name)")
        
        do {
            let transportAPI = TransportAPIFactory.createAPI()
            let options = try await transportAPI.nextJourneyOptions(from: firstRoute.origin, to: firstRoute.destination, results: 10)
            
            print("🎯 [TestRunner] API returned \(options.count) options")
            
            if let bestOption = options.first {
                print("🎯 [TestRunner] Best option selected:")
                print("🎯 [TestRunner] - Departure: \(bestOption.departure)")
                print("🎯 [TestRunner] - Arrival: \(bestOption.arrival)")
                print("🎯 [TestRunner] - Duration: \(bestOption.totalMinutes) minutes")
                print("🎯 [TestRunner] - Line: \(bestOption.lineName ?? "Unknown")")
                print("🎯 [TestRunner] - Platform: \(bestOption.platform ?? "Unknown")")
                print("🎯 [TestRunner] - Delay: \(bestOption.delayMinutes ?? 0) minutes")
                if let warnings = bestOption.warnings {
                    print("🎯 [TestRunner] - Warnings: \(warnings)")
                }
            } else {
                print("❌ [TestRunner] No suitable options found")
            }
        } catch {
            print("❌ [TestRunner] Error testing journey selection: \(error)")
        }
    }
    
    /// Quick test for the new best journey selection
    static func quickTestBestJourney() async {
        print("🎯 [TestRunner] Quick test for best journey selection...")
        await testBestJourneySelection()
    }
}
#endif