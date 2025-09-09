import Testing
import Foundation
@testable import TrainViewer

// MARK: - Mock Services for Testing

protocol JourneyHistoryServiceProtocol {
    func fetchHistory(for timeRange: TimeRange) async throws -> [JourneyHistoryEntry]
    func fetchHistory(for routeId: UUID, timeRange: TimeRange) async throws -> [JourneyHistoryEntry]
    func recordJourney(_ entry: JourneyHistoryEntry) async throws
    func recordJourneyFromOption(_ option: JourneyOption, route: Route, wasSuccessful: Bool) async throws
    func generateStatistics(for timeRange: TimeRange) async throws -> JourneyStatistics
    func generateRouteStatistics(for routeId: UUID, timeRange: TimeRange) async throws -> JourneyStatistics
    func clearHistory() async throws
    func clearAllHistory() async throws
    func exportData() async throws -> Data
    func exportHistory() async throws -> Data
    func exportAnonymizedHistory() async throws -> Data
    func cleanupOldEntries() async throws
}

final class MockJourneyHistoryService: JourneyHistoryServiceProtocol {
    var mockHistoryEntries: [JourneyHistoryEntry] = []
    var mockStatistics: JourneyStatistics?
    var mockRouteStatistics: [UUID: JourneyStatistics] = [:]
    var shouldThrowError = false
    var recordedEntries: [JourneyHistoryEntry] = []
    var recordedJourneyOptions: [(JourneyOption, Route, Bool)] = []

    func fetchHistory(for timeRange: TimeRange) async throws -> [JourneyHistoryEntry] {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock fetch error"])
        }
        return mockHistoryEntries
    }
    
    func fetchHistory(for routeId: UUID, timeRange: TimeRange) async throws -> [JourneyHistoryEntry] {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock fetch error"])
        }
        return mockHistoryEntries.filter { $0.routeId == routeId }
    }
    
    func generateStatistics(for timeRange: TimeRange) async throws -> JourneyStatistics {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock statistics error"])
        }
        return mockStatistics ?? JourneyStatistics(
            totalJourneys: 0,
            averageDelayMinutes: 0,
            mostUsedRouteId: nil,
            mostUsedRouteName: nil,
            peakTravelHours: [],
            weeklyPattern: Array(repeating: 0, count: 7),
            monthlyTrend: [:],
            reliabilityScore: 1.0,
            onTimePercentage: 100
        )
    }
    
    func generateRouteStatistics(for routeId: UUID, timeRange: TimeRange) async throws -> JourneyStatistics {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock route statistics error"])
        }
        return mockRouteStatistics[routeId] ?? JourneyStatistics(
            totalJourneys: 0,
            averageDelayMinutes: 0,
            mostUsedRouteId: nil,
            mostUsedRouteName: nil,
            peakTravelHours: [],
            weeklyPattern: Array(repeating: 0, count: 7),
            monthlyTrend: [:],
            reliabilityScore: 1.0,
            onTimePercentage: 100
        )
    }
    
    func recordJourney(_ entry: JourneyHistoryEntry) async throws {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock record error"])
        }
        recordedEntries.append(entry)
    }
    
    func recordJourneyFromOption(_ option: JourneyOption, route: Route, wasSuccessful: Bool) async throws {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock record option error"])
        }
        recordedJourneyOptions.append((option, route, wasSuccessful))
    }
    
    func exportHistory() async throws -> Data {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock export error"])
        }
        return "Mock export data".data(using: .utf8)!
    }
    
    func exportAnonymizedHistory() async throws -> Data {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock anonymized export error"])
        }
        return "Mock anonymized export data".data(using: .utf8)!
    }
    
    func clearAllHistory() async throws {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock clear error"])
        }
        mockHistoryEntries.removeAll()
        recordedEntries.removeAll()
        recordedJourneyOptions.removeAll()
    }
    
    func cleanupOldEntries() async throws {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock cleanup error"])
        }
        // Mock cleanup - remove entries older than 30 days
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 3600)
        mockHistoryEntries.removeAll { $0.departureTime < thirtyDaysAgo }
    }
}

protocol UserSettingsStoreProtocol {
    var refreshInterval: TimeInterval { get set }
    var notificationsEnabled: Bool { get set }
    var theme: String { get set }
    var language: String { get set }
}

class MockUserSettingsStore: UserSettingsStoreProtocol {
    var refreshInterval: TimeInterval = 30.0
    var notificationsEnabled: Bool = true
    var theme: String = "system"
    var language: String = "en"
}

// MARK: - Wrapper Classes for Constructor Compatibility

class JourneyHistoryServiceWrapper: JourneyHistoryService {
    private let mock: JourneyHistoryServiceProtocol

    init(mock: JourneyHistoryServiceProtocol) {
        self.mock = mock
        super.init(context: CoreDataStack(inMemory: true).context)
    }

    override func fetchHistory(for timeRange: TimeRange) async throws -> [JourneyHistoryEntry] {
        return try await mock.fetchHistory(for: timeRange)
    }

    override func recordJourney(_ entry: JourneyHistoryEntry) async throws {
        try await mock.recordJourney(entry)
    }

    override func generateStatistics(for timeRange: TimeRange) async throws -> JourneyStatistics {
        return try await mock.generateStatistics(for: timeRange)
    }

    override func generateRouteStatistics(for routeId: UUID, timeRange: TimeRange) async throws -> JourneyStatistics {
        return try await mock.generateRouteStatistics(for: routeId, timeRange: timeRange)
    }

    override func clearHistory() async throws {
        try await mock.clearHistory()
    }

    override func exportData() async throws -> Data {
        return try await mock.exportData()
    }

    override func fetchHistory(for routeId: UUID, timeRange: TimeRange) async throws -> [JourneyHistoryEntry] {
        return try await mock.fetchHistory(for: routeId, timeRange: timeRange)
    }

    override func recordJourneyFromOption(_ option: JourneyOption, route: Route, wasSuccessful: Bool) async throws {
        try await mock.recordJourneyFromOption(option, route: route, wasSuccessful: wasSuccessful)
    }

    override func clearAllHistory() async throws {
        try await mock.clearAllHistory()
    }

    override func exportHistory() async throws -> Data {
        return try await mock.exportHistory()
    }

    override func exportAnonymizedHistory() async throws -> Data {
        return try await mock.exportAnonymizedHistory()
    }

    override func cleanupOldEntries() async throws {
        try await mock.cleanupOldEntries()
    }
}

class UserSettingsStoreWrapper: UserSettingsStore {
    private let mock: UserSettingsStoreProtocol

    init(mock: UserSettingsStoreProtocol) {
        self.mock = mock
        super.init()
    }

    override var refreshInterval: TimeInterval {
        get { mock.refreshInterval }
        set { /* Not needed for testing */ }
    }

    override var notificationsEnabled: Bool {
        get { mock.notificationsEnabled }
        set { /* Not needed for testing */ }
    }

    override var theme: String {
        get { mock.theme }
        set { /* Not needed for testing */ }
    }

    override var language: String {
        get { mock.language }
        set { /* Not needed for testing */ }
    }
}

@MainActor
struct JourneyHistoryViewModelTests {
    
    // MARK: - Initialization Tests
    
    @Test("JourneyHistoryViewModel initializes with correct default values")
    func testInitialization() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        #expect(viewModel.historyEntries.isEmpty)
        #expect(viewModel.statistics == nil)
        #expect(viewModel.routeStatistics.isEmpty)
        #expect(viewModel.selectedTimeRange == TimeRange.lastMonth)
        #expect(viewModel.selectedRouteId == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("JourneyHistoryViewModel loads privacy settings from UserDefaults")
    func testPrivacySettingsInitialization() async throws {
        // Clear any existing settings
        UserDefaults.standard.removeObject(forKey: "journey_tracking_enabled")
        UserDefaults.standard.removeObject(forKey: "anonymized_export_enabled")
        
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        // Should default to true when no previous setting exists
        #expect(viewModel.isTrackingEnabled == true)
        #expect(viewModel.isAnonymizedExportEnabled == true)
    }
    
    // MARK: - Data Loading Tests
    
    @Test("JourneyHistoryViewModel loads history successfully")
    func testLoadHistorySuccess() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        // Setup mock data
        let mockEntry = createMockJourneyHistoryEntry()
        mockService.mockHistoryEntries = [mockEntry]
        mockService.mockStatistics = createMockStatistics()
        
        await viewModel.loadHistory()
        
        #expect(viewModel.historyEntries.count == 1)
        #expect(viewModel.statistics != nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("JourneyHistoryViewModel handles load history error")
    func testLoadHistoryError() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        mockService.shouldThrowError = true
        
        await viewModel.loadHistory()
        
        #expect(viewModel.historyEntries.isEmpty)
        #expect(viewModel.statistics == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage!.contains("Failed to load journey history"))
    }
    
    @Test("JourneyHistoryViewModel skips loading when tracking disabled")
    func testLoadHistoryWhenTrackingDisabled() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        viewModel.isTrackingEnabled = false
        
        await viewModel.loadHistory()
        
        #expect(viewModel.historyEntries.isEmpty)
        #expect(viewModel.statistics == nil)
        #expect(viewModel.isLoading == false)
    }
    
    @Test("JourneyHistoryViewModel loads route-specific history")
    func testLoadRouteSpecificHistory() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        let routeId = UUID()
        let mockEntry = createMockJourneyHistoryEntry(routeId: routeId)
        mockService.mockHistoryEntries = [mockEntry]
        mockService.mockStatistics = createMockStatistics()
        
        viewModel.selectedRouteId = routeId
        await viewModel.loadHistory()
        
        #expect(viewModel.historyEntries.count == 1)
        #expect(viewModel.historyEntries.first?.routeId == routeId)
    }
    
    // MARK: - Route Statistics Tests
    
    @Test("JourneyHistoryViewModel loads route statistics")
    func testLoadRouteStatistics() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        let route1 = createMockRoute(name: "Route 1")
        let route2 = createMockRoute(name: "Route 2")
        let routes = [route1, route2]
        
        mockService.mockRouteStatistics = [
            route1.id: createMockStatistics(totalJourneys: 10),
            route2.id: createMockStatistics(totalJourneys: 5)
        ]
        
        await viewModel.loadRouteStatistics(for: routes)
        
        #expect(viewModel.routeStatistics.count == 2)
        #expect(viewModel.routeStatistics[route1.id]?.totalJourneys == 10)
        #expect(viewModel.routeStatistics[route2.id]?.totalJourneys == 5)
    }
    
    @Test("JourneyHistoryViewModel handles route statistics errors gracefully")
    func testLoadRouteStatisticsWithErrors() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        let route = createMockRoute(name: "Error Route")
        mockService.shouldThrowError = true
        
        await viewModel.loadRouteStatistics(for: [route])
        
        #expect(viewModel.routeStatistics.isEmpty)
    }
    
    // MARK: - Journey Recording Tests
    
    @Test("JourneyHistoryViewModel records journey successfully")
    func testRecordJourney() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        let entry = createMockJourneyHistoryEntry()
        
        await viewModel.recordJourney(entry)
        
        #expect(mockService.recordedEntries.count == 1)
        #expect(mockService.recordedEntries.first?.id == entry.id)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("JourneyHistoryViewModel skips recording when tracking disabled")
    func testRecordJourneyWhenTrackingDisabled() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        viewModel.isTrackingEnabled = false
        let entry = createMockJourneyHistoryEntry()
        
        await viewModel.recordJourney(entry)
        
        #expect(mockService.recordedEntries.isEmpty)
    }
    
    @Test("JourneyHistoryViewModel records journey from option")
    func testRecordJourneyFromOption() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        let option = createMockJourneyOption()
        let route = createMockRoute(name: "Test Route")
        
        await viewModel.recordJourneyFromOption(option, route: route, wasSuccessful: true)
        
        #expect(mockService.recordedJourneyOptions.count == 1)
        #expect(mockService.recordedJourneyOptions.first?.1.id == route.id)
        #expect(mockService.recordedJourneyOptions.first?.2 == true)
    }
    
    // MARK: - Data Management Tests
    
    @Test("JourneyHistoryViewModel exports history")
    func testExportHistory() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        viewModel.isAnonymizedExportEnabled = false
        
        let exportData = await viewModel.exportHistory()
        
        #expect(exportData != nil)
        let exportString = String(data: exportData!, encoding: .utf8)
        #expect(exportString == "Mock export data")
    }
    
    @Test("JourneyHistoryViewModel exports anonymized history")
    func testExportAnonymizedHistory() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        viewModel.isAnonymizedExportEnabled = true
        
        let exportData = await viewModel.exportHistory()
        
        #expect(exportData != nil)
        let exportString = String(data: exportData!, encoding: .utf8)
        #expect(exportString == "Mock anonymized export data")
    }
    
    @Test("JourneyHistoryViewModel clears history")
    func testClearHistory() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        // Setup initial data
        viewModel.historyEntries = [createMockJourneyHistoryEntry()]
        viewModel.statistics = createMockStatistics()
        viewModel.routeStatistics = [UUID(): createMockStatistics()]
        
        await viewModel.clearHistory()
        
        #expect(viewModel.historyEntries.isEmpty)
        #expect(viewModel.statistics == nil)
        #expect(viewModel.routeStatistics.isEmpty)
        #expect(mockService.mockHistoryEntries.isEmpty)
    }
    
    @Test("JourneyHistoryViewModel performs cleanup")
    func testPerformCleanup() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        // Setup old entries
        let oldEntry = createMockJourneyHistoryEntry(departureTime: Date().addingTimeInterval(-40 * 24 * 3600))
        let recentEntry = createMockJourneyHistoryEntry(departureTime: Date().addingTimeInterval(-10 * 24 * 3600))
        mockService.mockHistoryEntries = [oldEntry, recentEntry]
        
        await viewModel.performCleanup()
        
        // Old entry should be removed
        #expect(mockService.mockHistoryEntries.count == 1)
        #expect(mockService.mockHistoryEntries.first?.id == recentEntry.id)
    }
    
    // MARK: - Filtering and Selection Tests
    
    @Test("JourneyHistoryViewModel updates time range")
    func testUpdateTimeRange() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        await viewModel.updateTimeRange(TimeRange.lastWeek)
        
        #expect(viewModel.selectedTimeRange == TimeRange.lastWeek)
    }
    
    @Test("JourneyHistoryViewModel updates route filter")
    func testUpdateRouteFilter() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        let routeId = UUID()
        await viewModel.updateRouteFilter(routeId)
        
        #expect(viewModel.selectedRouteId == routeId)
    }
    
    @Test("JourneyHistoryViewModel clears error")
    func testClearError() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        viewModel.errorMessage = "Test error"
        viewModel.clearError()
        
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - Computed Properties Tests
    
    @Test("JourneyHistoryViewModel groups entries by date")
    func testGroupedEntries() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        let todayEntry = createMockJourneyHistoryEntry(departureTime: today)
        let yesterdayEntry = createMockJourneyHistoryEntry(departureTime: yesterday)
        
        viewModel.historyEntries = [todayEntry, yesterdayEntry]
        
        let grouped = viewModel.groupedEntries
        #expect(grouped.count == 2)
    }
    
    @Test("JourneyHistoryViewModel provides recent entries")
    func testRecentEntries() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        // Create 15 entries
        let entries = (0..<15).map { i in
            createMockJourneyHistoryEntry(departureTime: Date().addingTimeInterval(Double(-i * 3600)))
        }
        
        viewModel.historyEntries = entries
        
        let recent = viewModel.recentEntries
        #expect(recent.count == 10) // Should limit to 10
    }
    
    @Test("JourneyHistoryViewModel creates statistics summary")
    func testStatisticsSummary() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        let stats = createMockStatistics(
            totalJourneys: 50,
            averageDelayMinutes: 5.5,
            onTimePercentage: 85.0,
            reliabilityScore: 0.8,
            mostUsedRouteName: "Main Route",
            peakTravelHours: [8, 17]
        )
        
        viewModel.statistics = stats
        
        let summary = viewModel.statisticsSummary
        #expect(summary != nil)
        #expect(summary?.totalJourneys == 50)
        #expect(summary?.averageDelay == 5.5)
        #expect(summary?.onTimePercentage == 85.0)
        #expect(summary?.reliabilityScore == 0.8)
        #expect(summary?.mostUsedRoute == "Main Route")
        #expect(summary?.peakHours == [8, 17])
    }
    
    // MARK: - Privacy Tests
    
    @Test("JourneyHistoryViewModel handles tracking consent")
    func testTrackingConsent() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        viewModel.isTrackingEnabled = true
        let consent = viewModel.requestTrackingConsent()
        #expect(consent == true)
        
        viewModel.isTrackingEnabled = false
        let noConsent = viewModel.requestTrackingConsent()
        #expect(noConsent == false)
    }
    
    @Test("JourneyHistoryViewModel disables tracking and clears data")
    func testDisableTrackingAndClearData() async throws {
        let (mockService, mockSettings) = createWrappedServices()
        let viewModel = JourneyHistoryViewModel(historyService: mockService, settings: mockSettings)
        
        // Setup initial data
        viewModel.isTrackingEnabled = true
        viewModel.historyEntries = [createMockJourneyHistoryEntry()]
        
        await viewModel.disableTrackingAndClearData()
        
        #expect(viewModel.isTrackingEnabled == false)
        #expect(viewModel.historyEntries.isEmpty)
    }
}

// MARK: - Test Helpers

extension JourneyHistoryViewModelTests {

    private func createWrappedServices() -> (JourneyHistoryService, UserSettingsStore) {
        let mockService = MockJourneyHistoryService()
        let mockSettings = MockUserSettingsStore()
        return (JourneyHistoryServiceWrapper(mock: mockService), UserSettingsStoreWrapper(mock: mockSettings))
    }
    
    private func createMockJourneyHistoryEntry(
        routeId: UUID = UUID(),
        departureTime: Date = Date()
    ) -> JourneyHistoryEntry {
        return JourneyHistoryEntry(
            id: UUID(),
            routeId: routeId,
            routeName: "Test Route",
            departureTime: departureTime,
            arrivalTime: departureTime.addingTimeInterval(1800),
            actualDepartureTime: departureTime,
            actualArrivalTime: departureTime.addingTimeInterval(1800),
            delayMinutes: 0,
            wasSuccessful: true,
            createdAt: Date()
        )
    }
    
    private func createMockStatistics(
        totalJourneys: Int = 10,
        averageDelayMinutes: Double = 2.5,
        onTimePercentage: Double = 90.0,
        reliabilityScore: Double = 0.9,
        mostUsedRouteName: String? = "Test Route",
        peakTravelHours: [Int] = [8, 17]
    ) -> JourneyStatistics {
        return JourneyStatistics(
            totalJourneys: totalJourneys,
            averageDelayMinutes: averageDelayMinutes,
            mostUsedRouteId: nil,
            mostUsedRouteName: mostUsedRouteName,
            peakTravelHours: peakTravelHours,
            weeklyPattern: Array(repeating: totalJourneys / 7, count: 7),
            monthlyTrend: [:],
            reliabilityScore: reliabilityScore,
            onTimePercentage: onTimePercentage
        )
    }
    
    private func createMockRoute(name: String) -> Route {
        let origin = Place(rawId: "origin", name: "Origin", latitude: nil, longitude: nil)
        let destination = Place(rawId: "destination", name: "Destination", latitude: nil, longitude: nil)
        
        return Route(
            id: UUID(),
            name: name,
            origin: origin,
            destination: destination
        )
    }
    
    private func createMockJourneyOption() -> JourneyOption {
        return JourneyOption(
            departure: Date(),
            arrival: Date().addingTimeInterval(1800),
            lineName: "Test Line",
            platform: "1",
            delayMinutes: 0,
            totalMinutes: 30,
            warnings: nil
        )
    }
}