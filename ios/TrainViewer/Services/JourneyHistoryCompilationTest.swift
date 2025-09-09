import Foundation

/// Compilation test for Journey History system
final class JourneyHistoryCompilationTest {
    
    func testCompilation() {
        // Test privacy manager
        let privacyManager = PrivacyManager.shared
        let _ = privacyManager.hasJourneyTrackingConsent
        
        // Test settings store
        let settings = UserSettingsStore.shared
        let _ = settings.journeyTrackingEnabled
        
        // Test simple service (with in-memory Core Data)
        let coreDataStack = CoreDataStack(inMemory: true)
        let service = SimpleJourneyHistoryService(context: coreDataStack.context)
        
        print("✅ Journey History compilation test passed")
        print("Privacy enabled: \(privacyManager.isJourneyTrackingEnabled)")
        print("Settings tracking: \(settings.journeyTrackingEnabled)")
        print("Service initialized: \(service)")
    }
}