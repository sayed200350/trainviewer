# Design Document

## Overview

This design document outlines the architecture and implementation approach for the TrainViewer enhancement phase. Building on the existing fully functional iOS app with SwiftUI, Core Data, and WidgetKit integration, this phase focuses on improving user experience, performance, and adding advanced features while maintaining the current robust architecture.

The design leverages the existing MVVM architecture, extends current services, and adds new components for enhanced functionality without disrupting the production-ready codebase.

## Architecture

### Enhanced Architecture Overview

Building on the existing MVVM architecture, we'll add new components and enhance existing ones:

```
┌─────────────────────────────────────────────────────────────┐
│                    Enhanced Views Layer                     │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │   Enhanced      │ │   Statistics    │ │  Accessibility  ││
│  │   MainView      │ │     Views       │ │   Enhanced UI   ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                Enhanced ViewModels Layer                    │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │   Enhanced      │ │   Statistics    │ │   Settings      ││
│  │ RoutesViewModel │ │   ViewModel     │ │   ViewModel     ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                  Enhanced Services Layer                    │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │   Performance   │ │    Journey      │ │    Haptic       ││
│  │   Optimizer     │ │    History      │ │    Service      ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Enhanced Data Layer                      │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │   Enhanced      │ │    Journey      │ │   Performance   ││
│  │   Core Data     │ │    History      │ │     Cache       ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Key Design Principles

1. **Backward Compatibility**: All enhancements maintain compatibility with existing data and functionality
2. **Performance First**: Every enhancement considers performance impact and optimization opportunities
3. **Accessibility by Design**: All new features include accessibility considerations from the start
4. **Incremental Enhancement**: Build on existing components rather than replacing them
5. **User-Centric**: Focus on solving real user pain points identified in the current app

## Components and Interfaces

### 1. Enhanced Models

#### Enhanced Route Model
```swift
// Extend existing Route model with new properties
extension Route {
    var isFavorite: Bool { get set }
    var customRefreshInterval: RefreshInterval { get set }
    var lastUsed: Date { get set }
    var usageCount: Int { get set }
    var averageJourneyTime: TimeInterval? { get set }
}

enum RefreshInterval: Int, CaseIterable, Codable {
    case manual = 0
    case oneMinute = 1
    case twoMinutes = 2
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    
    var displayName: String {
        switch self {
        case .manual: return "Manual Only"
        case .oneMinute: return "1 Minute"
        case .twoMinutes: return "2 Minutes"
        case .fiveMinutes: return "5 Minutes"
        case .tenMinutes: return "10 Minutes"
        case .fifteenMinutes: return "15 Minutes"
        }
    }
}
```

#### Journey History Models (New)
```swift
struct JourneyHistoryEntry: Identifiable, Codable {
    let id: UUID
    let routeId: UUID
    let routeName: String
    let departureTime: Date
    let arrivalTime: Date
    let actualDepartureTime: Date?
    let actualArrivalTime: Date?
    let delayMinutes: Int
    let wasSuccessful: Bool
    let createdAt: Date
}

struct JourneyStatistics: Codable {
    let totalJourneys: Int
    let averageDelayMinutes: Double
    let mostUsedRoute: Route?
    let peakTravelHours: [Int] // Hours of day (0-23)
    let weeklyPattern: [Int] // Journeys per day of week
    let monthlyTrend: [Date: Int] // Journeys per month
}
```

### 2. Enhanced ViewModels

#### Enhanced RoutesViewModel
```swift
@MainActor
final class RoutesViewModel: ObservableObject {
    // Existing properties...
    
    // New enhancement properties
    @Published var favoriteRoutes: [Route] = []
    @Published var recentRoutes: [Route] = []
    @Published var routeStatistics: [UUID: RouteStatistics] = [:]
    @Published var isPerformanceOptimized: Bool = true
    
    // New methods
    func toggleFavorite(for route: Route)
    func reorderFavorites(_ routes: [Route])
    func updateUsageStatistics(for route: Route)
    func getOptimalRefreshInterval(for route: Route) -> RefreshInterval
    func batchUpdateRoutes(_ routes: [Route]) async
}

struct RouteStatistics {
    let averageDelay: TimeInterval
    let reliabilityScore: Double // 0.0 to 1.0
    let usageFrequency: UsageFrequency
    let lastUsed: Date
}

enum UsageFrequency {
    case daily, weekly, monthly, rarely
}
```

#### JourneyHistoryViewModel (New)
```swift
@MainActor
final class JourneyHistoryViewModel: ObservableObject {
    @Published var historyEntries: [JourneyHistoryEntry] = []
    @Published var statistics: JourneyStatistics?
    @Published var isTrackingEnabled: Bool = true
    @Published var selectedTimeRange: TimeRange = .lastMonth
    
    private let historyService: JourneyHistoryService
    
    func loadHistory(for timeRange: TimeRange)
    func recordJourney(_ entry: JourneyHistoryEntry)
    func generateStatistics() -> JourneyStatistics
    func exportHistory() -> Data
    func clearHistory(olderThan date: Date)
}

enum TimeRange: CaseIterable {
    case lastWeek, lastMonth, lastThreeMonths, lastYear, all
    
    var displayName: String {
        switch self {
        case .lastWeek: return "Last Week"
        case .lastMonth: return "Last Month"
        case .lastThreeMonths: return "Last 3 Months"
        case .lastYear: return "Last Year"
        case .all: return "All Time"
        }
    }
}
```

#### SettingsViewModel (Enhanced)
```swift
@MainActor
final class SettingsViewModel: ObservableObject {
    // Existing properties...
    
    // New enhancement properties
    @Published var defaultRefreshInterval: RefreshInterval = .fiveMinutes
    @Published var isHapticFeedbackEnabled: Bool = true
    @Published var isJourneyTrackingEnabled: Bool = true
    @Published var isPerformanceOptimizationEnabled: Bool = true
    @Published var notificationAdvanceTime: TimeInterval = 300 // 5 minutes
    @Published var isSmartNotificationsEnabled: Bool = true
    
    func resetToDefaults()
    func exportSettings() -> Data
    func importSettings(from data: Data) throws
}
```

### 3. Enhanced Services

#### PerformanceOptimizer (New)
```swift
final class PerformanceOptimizer {
    static let shared = PerformanceOptimizer()
    
    private let imageCache = NSCache<NSString, UIImage>()
    private let requestBatcher = APIRequestBatcher()
    private let memoryMonitor = MemoryMonitor()
    
    func optimizeImageLoading(for url: URL) async -> UIImage?
    func batchAPIRequests(_ requests: [APIRequest]) async -> [APIResponse]
    func handleMemoryWarning()
    func optimizeBackgroundRefresh() -> TimeInterval
    func getOptimalCacheSize() -> Int
}

final class APIRequestBatcher {
    private var pendingRequests: [APIRequest] = []
    private let batchInterval: TimeInterval = 0.5
    
    func addRequest(_ request: APIRequest)
    func processBatch() async -> [APIResponse]
}

final class MemoryMonitor {
    @Published var currentMemoryUsage: Int64 = 0
    @Published var isMemoryPressureHigh: Bool = false
    
    func startMonitoring()
    func handleMemoryPressure()
}
```

#### JourneyHistoryService (New)
```swift
final class JourneyHistoryService {
    private let coreDataStack: CoreDataStack
    private let maxHistoryEntries = 1000
    
    func recordJourney(_ entry: JourneyHistoryEntry) async throws
    func fetchHistory(for timeRange: TimeRange) async throws -> [JourneyHistoryEntry]
    func generateStatistics(for timeRange: TimeRange) async throws -> JourneyStatistics
    func cleanupOldEntries() async throws
    func exportHistory() async throws -> Data
}
```

#### Enhanced NotificationService
```swift
extension NotificationService {
    func scheduleSmartReminder(for route: Route, departure: Date) async
    func updateReminderForDelay(routeId: UUID, newDeparture: Date) async
    func scheduleDisruptionAlert(for route: Route, message: String) async
    func batchScheduleReminders(_ reminders: [NotificationRequest]) async
    func getOptimalNotificationTime(for route: Route) -> TimeInterval
}

struct NotificationRequest {
    let routeId: UUID
    let departureTime: Date
    let message: String
    let priority: NotificationPriority
}

enum NotificationPriority {
    case low, normal, high, critical
}
```

#### HapticFeedbackService (New)
```swift
final class HapticFeedbackService {
    static let shared = HapticFeedbackService()
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    func playButtonTap()
    func playSuccess()
    func playError()
    func playWarning()
    func playSelection()
    func playRefresh()
    
    var isEnabled: Bool { get set }
}
```

### 4. Enhanced Widget System

#### Widget Configuration Enhancement
```swift
struct EnhancedWidgetConfiguration: AppIntent {
    static var title: LocalizedStringResource = "Configure Widget"
    
    @Parameter(title: "Route")
    var route: RouteEntity
    
    @Parameter(title: "Refresh Interval")
    var refreshInterval: RefreshInterval
    
    @Parameter(title: "Show Favorites Only")
    var showFavoritesOnly: Bool
    
    @Parameter(title: "Compact Mode")
    var compactMode: Bool
}

struct WidgetPerformanceOptimizer {
    static func getOptimalUpdateInterval(for route: Route) -> TimeInterval
    static func shouldUpdateWidget(lastUpdate: Date, route: Route) -> Bool
    static func optimizeWidgetContent(for size: WidgetFamily) -> WidgetContent
}
```

## Data Models

### Enhanced Core Data Schema

#### Enhanced RouteEntity
```swift
extension RouteEntity {
    @NSManaged var isFavorite: Bool
    @NSManaged var customRefreshIntervalRaw: Int16
    @NSManaged var lastUsed: Date
    @NSManaged var usageCount: Int32
    @NSManaged var averageJourneyTime: Double // -1 if not calculated
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    
    var customRefreshInterval: RefreshInterval {
        get { RefreshInterval(rawValue: Int(customRefreshIntervalRaw)) ?? .fiveMinutes }
        set { customRefreshIntervalRaw = Int16(newValue.rawValue) }
    }
}
```

#### JourneyHistoryEntity (New)
```swift
@objc(JourneyHistoryEntity)
final class JourneyHistoryEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var routeId: UUID
    @NSManaged var routeName: String
    @NSManaged var departureTime: Date
    @NSManaged var arrivalTime: Date
    @NSManaged var actualDepartureTime: Date?
    @NSManaged var actualArrivalTime: Date?
    @NSManaged var delayMinutes: Int16
    @NSManaged var wasSuccessful: Bool
    @NSManaged var createdAt: Date
}
```

## Error Handling

### Enhanced Error Types
```swift
enum EnhancedAppError: LocalizedError {
    case widgetConfigurationFailed(reason: String)
    case performanceOptimizationFailed
    case historyTrackingFailed(Error)
    case hapticFeedbackUnavailable
    case batchRequestFailed([APIRequest])
    case memoryPressureCritical
    case notificationSchedulingFailed(Error)
    
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
        case .batchRequestFailed:
            return "Some route updates failed. Retrying automatically."
        case .memoryPressureCritical:
            return "Low memory detected. Some features temporarily reduced."
        case .notificationSchedulingFailed:
            return "Notification scheduling failed. Check notification permissions in Settings."
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
        }
    }
}
```

### Enhanced Error Recovery
```swift
final class ErrorRecoveryService {
    static let shared = ErrorRecoveryService()
    
    func handleError(_ error: EnhancedAppError) async -> ErrorRecoveryResult
    func scheduleRetry(for operation: FailedOperation, after delay: TimeInterval)
    func reportCriticalError(_ error: Error, context: String)
    func generateDiagnosticInfo() -> DiagnosticInfo
}

enum ErrorRecoveryResult {
    case recovered
    case retryScheduled(after: TimeInterval)
    case userActionRequired(message: String)
    case criticalFailure
}

struct DiagnosticInfo {
    let appVersion: String
    let iOSVersion: String
    let deviceModel: String
    let memoryUsage: Int64
    let networkStatus: NetworkStatus
    let lastErrors: [EnhancedAppError]
}
```

## Performance Considerations

### API Optimization Strategy
```swift
final class APIOptimizationStrategy {
    // Batch multiple route requests
    func batchRouteRequests(_ routes: [Route]) -> [BatchedAPIRequest]
    
    // Intelligent caching with TTL
    func getCacheStrategy(for route: Route) -> CacheStrategy
    
    // Adaptive refresh intervals based on usage patterns
    func getAdaptiveRefreshInterval(for route: Route) -> TimeInterval
    
    // Network-aware request scheduling
    func scheduleRequest(_ request: APIRequest, networkCondition: NetworkCondition)
}

struct CacheStrategy {
    let ttl: TimeInterval
    let priority: CachePriority
    let shouldPersist: Bool
}

enum CachePriority {
    case low, normal, high, critical
}

enum NetworkCondition {
    case wifi, cellular, poor, offline
}
```

### Memory Management
```swift
final class MemoryManager {
    static let shared = MemoryManager()
    
    private let imageCache = NSCache<NSString, UIImage>()
    private let dataCache = NSCache<NSString, NSData>()
    
    func configureOptimalCacheLimits()
    func handleMemoryWarning()
    func preloadCriticalData()
    func clearNonEssentialCaches()
    
    var currentMemoryFootprint: Int64 { get }
    var isMemoryPressureHigh: Bool { get }
}
```

## Testing Strategy

### Enhanced Testing Approach
```swift
// Performance Testing
final class PerformanceTests: XCTestCase {
    func testAPIBatchingPerformance()
    func testMemoryUsageUnderLoad()
    func testWidgetUpdatePerformance()
    func testCacheEfficiency()
}

// User Experience Testing
final class UXTests: XCTestCase {
    func testHapticFeedbackTiming()
    func testAccessibilityNavigation()
    func testDarkModeConsistency()
    func testErrorRecoveryFlows()
}

// Integration Testing
final class EnhancementIntegrationTests: XCTestCase {
    func testFavoriteRoutesIntegration()
    func testHistoryTrackingAccuracy()
    func testNotificationSchedulingReliability()
    func testWidgetConfigurationPersistence()
}
```

## Accessibility Design

### Enhanced Accessibility Features
```swift
final class AccessibilityEnhancer {
    static let shared = AccessibilityEnhancer()
    
    func enhanceVoiceOverLabels(for view: UIView)
    func provideDynamicTypeSupport(for textElements: [UILabel])
    func addHighContrastSupport(for colors: [UIColor]) -> [UIColor]
    func implementReducedMotionAlternatives(for animations: [UIViewPropertyAnimator])
    
    var isVoiceOverRunning: Bool { UIAccessibility.isVoiceOverRunning }
    var preferredContentSizeCategory: UIContentSizeCategory { UIApplication.shared.preferredContentSizeCategory }
}

struct AccessibilityConfiguration {
    let voiceOverLabels: [String: String]
    let dynamicTypeScaling: [UIFont.TextStyle: CGFloat]
    let highContrastColors: [UIColor]
    let reducedMotionAlternatives: [String: UIView.AnimationOptions]
}
```

## Security and Privacy

### Enhanced Privacy Protection
```swift
final class PrivacyManager {
    static let shared = PrivacyManager()
    
    func anonymizeHistoryData(_ entries: [JourneyHistoryEntry]) -> [AnonymizedHistoryEntry]
    func encryptSensitiveData(_ data: Data) throws -> Data
    func decryptSensitiveData(_ encryptedData: Data) throws -> Data
    func clearPrivateData()
    
    var isHistoryTrackingConsented: Bool { get set }
    var isLocationTrackingConsented: Bool { get set }
}

struct AnonymizedHistoryEntry {
    let routeHash: String // Hashed route identifier
    let timeSlot: TimeSlot // Generalized time instead of exact time
    let delayCategory: DelayCategory // Categorized instead of exact delay
}

enum TimeSlot {
    case earlyMorning, morning, midday, afternoon, evening, night
}

enum DelayCategory {
    case onTime, slightDelay, moderateDelay, significantDelay
}
```

## Deployment Strategy

### Phased Rollout Plan
```swift
enum EnhancementPhase {
    case phase1 // Widget fixes, error handling, performance
    case phase2 // Favorites, history, customization
    case phase3 // Advanced features, analytics, polish
    
    var features: [Feature] {
        switch self {
        case .phase1:
            return [.widgetFixes, .enhancedErrors, .performanceOptimization]
        case .phase2:
            return [.favoriteRoutes, .journeyHistory, .customRefresh]
        case .phase3:
            return [.hapticFeedback, .smartNotifications, .accessibility]
        }
    }
}

final class FeatureToggleManager {
    static let shared = FeatureToggleManager()
    
    func isFeatureEnabled(_ feature: Feature) -> Bool
    func enableFeature(_ feature: Feature)
    func disableFeature(_ feature: Feature)
    func rolloutFeature(_ feature: Feature, toPercentage: Double)
}
```

This design builds incrementally on your existing production-ready app, focusing on user experience improvements and performance optimizations while maintaining the robust architecture you've already established.