import Foundation

/// Factory for creating the appropriate background refresh service based on the target
final class BackgroundRefreshFactory {

    /// Returns the appropriate background refresh service for the current target
    static func createService() -> BackgroundRefreshProtocol {
        #if APP_EXTENSION
        return ExtensionBackgroundRefreshService.shared
        #else
        // Only reference BackgroundRefreshService when not in extension
        return createMainAppService()
        #endif
    }

    #if !APP_EXTENSION
    /// Creates the main app background refresh service (only available in main app)
    private static func createMainAppService() -> BackgroundRefreshProtocol {
        return BackgroundRefreshService.shared
    }
    #endif
}
