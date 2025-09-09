import Foundation

/// Protocol for background refresh functionality that can be implemented differently for main app vs extensions
protocol BackgroundRefreshProtocol {
    func register()
    func schedule()
    func scheduleForRoute(_ route: Any)
    func triggerManualRefresh() async
    func handleAppDidEnterBackground()
    func handleAppDidBecomeActive()
    func configure(with smartJourneyService: JourneyServiceProtocol)
}

/// Extension-safe implementation that provides no-op functionality for app extensions
final class ExtensionBackgroundRefreshService: BackgroundRefreshProtocol {
    static let shared = ExtensionBackgroundRefreshService()
    private init() {}
    
    private var smartJourneyService: JourneyServiceProtocol?
    private var lastRefreshDate: Date?
    
    func register() {
        print("ℹ️ [ExtensionBackgroundRefreshService] Background task registration not available in app extensions")
    }
    
    func schedule() {
        print("ℹ️ [ExtensionBackgroundRefreshService] Background task scheduling not available in app extensions")
    }
    
    func scheduleForRoute(_ route: Any) {
        print("ℹ️ [ExtensionBackgroundRefreshService] Route-specific scheduling not available in app extensions")
    }
    
    func triggerManualRefresh() async {
        print("🔄 [ExtensionBackgroundRefreshService] Manual refresh triggered (extension-safe)")
        await performRouteRefresh()
        lastRefreshDate = Date()
    }
    
    func handleAppDidEnterBackground() {
        print("📱 [ExtensionBackgroundRefreshService] Background handling not available in app extensions")
    }
    
    func handleAppDidBecomeActive() {
        print("📱 [ExtensionBackgroundRefreshService] App became active (extension context)")
        
        // Check if we need an immediate refresh
        if let lastRefresh = lastRefreshDate,
           Date().timeIntervalSince(lastRefresh) > 900 { // 15 minutes
            Task {
                await triggerManualRefresh()
            }
        }
    }
    
    func configure(with smartJourneyService: JourneyServiceProtocol) {
        self.smartJourneyService = smartJourneyService
    }
    
    // MARK: - Extension-Safe Refresh Logic
    
    private func performRouteRefresh() async {
        print("🔄 [ExtensionBackgroundRefreshService] Performing extension-safe route refresh")
        
        do {
            // Extension-safe refresh logic here
            print("🔄 [ExtensionBackgroundRefreshService] Extension-safe refresh completed")
        } catch {
            print("❌ [ExtensionBackgroundRefreshService] Route refresh failed: \(error)")
        }
    }
}