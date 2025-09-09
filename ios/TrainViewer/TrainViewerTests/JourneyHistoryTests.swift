import XCTest
@testable import TrainViewer

final class JourneyHistoryTests: XCTestCase {
    var historyService: JourneyHistoryService!
    var privacyManager: PrivacyManager!
    
    override func setUp() {
        super.setUp()
        
        // Use in-memory Core Data stack for testing
        let coreDataStack = CoreDataStack(inMemory: true)
        historyService = JourneyHistoryService(context: coreDataStack.context)
        privacyManager = PrivacyManager.shared
    }
    
    override func tearDown() {
        historyService = nil
        privacyManager = nil
        super.tearDown()
    }
    
    // MARK: - Journey History Entry Tests
    
    func testJourneyHistoryEntryCreation() {
        let routeId = UUID()
        let entry = JourneyHistoryEntry(
            routeId: routeId,
            routeName: "Test Route",
            departureTime: Date(),
            arrivalTime: Date().addingTimeInterval(1800), // 30 minutes later
            delayMinutes: 5
        )
        
        XCTAssertEqual(entry.routeId, routeId)
        XCTAssertEqual(entry.routeName, "Test Route")
        XCTAssertEqual(entry.delayMinutes, 5)
        XCTAssertTrue(entry.hadDelay)
        XCTAssertEqual(entry.delayCategory, .slightDelay)
    }
    
    func testJourneyHistoryTimeSlots() {
        let calendar = Calendar.current
        
        // Test early morning (7 AM)
        let earlyMorning = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!
        let earlyEntry = JourneyHistoryEntry(
            routeId: UUID(),
            routeName: "Early Route",
            departureTime: earlyMorning,
            arrivalTime: earlyMorning.addingTimeInterval(1800)
        )
        XCTAssertEqual(earlyEntry.timeSlot, .earlyMorning)
        
        // Test afternoon (3 PM)
        let afternoon = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: Date())!
        let afternoonEntry = JourneyHistoryEntry(
            routeId: UUID(),
            routeName: "Afternoon Route",
            departureTime: afternoon,
            arrivalTime: afternoon.addingTimeInterval(1800)
        )
        XCTAssertEqual(afternoonEntry.timeSlot, .afternoon)
    }
    
    func testDelayCategories() {
        // On time
        let onTimeEntry = JourneyHistoryEntry(
            routeId: UUID(),
            routeName: "On Time Route",
            departureTime: Date(),
            arrivalTime: Date().addingTimeInterval(1800),
            delayMinutes: 0
        )
        XCTAssertEqual(onTimeEntry.delayCategory, .onTime)
        XCTAssertFalse(onTimeEntry.hadDelay)
        
        // Slight delay
        let slightDelayEntry = JourneyHistoryEntry(
            routeId: UUID(),
            routeName: "Slight Delay Route",
            departureTime: Date(),
            arrivalTime: Date().addingTimeInterval(1800),
            delayMinutes: 3
        )
        XCTAssertEqual(slightDelayEntry.delayCategory, .slightDelay)
        XCTAssertTrue(slightDelayEntry.hadDelay)
        
        // Significant delay
        let significantDelayEntry = JourneyHistoryEntry(
            routeId: UUID(),
            routeName: "Significant Delay Route",
            departureTime: Date(),
            arrivalTime: Date().addingTimeInterval(1800),
            delayMinutes: 20
        )
        XCTAssertEqual(significantDelayEntry.delayCategory, .significantDelay)
        XCTAssertTrue(significantDelayEntry.hadDelay)
    }
    
    // MARK: - Journey History Service Tests
    
    func testRecordAndFetchJourney() async throws {
        let routeId = UUID()
        let entry = JourneyHistoryEntry(
            routeId: routeId,
            routeName: "Test Route",
            departureTime: Date(),
            arrivalTime: Date().addingTimeInterval(1800),
            delayMinutes: 2
        )
        
        // Record journey
        try await historyService.recordJourney(entry)
        
        // Fetch journey history
        let fetchedEntries = try await historyService.fetchHistory(for: .all)
        
        XCTAssertEqual(fetchedEntries.count, 1)
        XCTAssertEqual(fetchedEntries.first?.routeId, routeId)
        XCTAssertEqual(fetchedEntries.first?.routeName, "Test Route")
        XCTAssertEqual(fetchedEntries.first?.delayMinutes, 2)
    }
    
    func testFetchHistoryByTimeRange() async throws {
        let routeId = UUID()
        let calendar = Calendar.current
        
        // Create entries for different time periods
        let oldEntry = JourneyHistoryEntry(
            routeId: routeId,
            routeName: "Old Route",
            departureTime: calendar.date(byAdding: .month, value: -2, to: Date())!,
            arrivalTime: calendar.date(byAdding: .month, value: -2, to: Date())!.addingTimeInterval(1800)
        )
        
        let recentEntry = JourneyHistoryEntry(
            routeId: routeId,
            routeName: "Recent Route",
            departureTime: calendar.date(byAdding: .day, value: -5, to: Date())!,
            arrivalTime: calendar.date(byAdding: .day, value: -5, to: Date())!.addingTimeInterval(1800)
        )
        
        try await historyService.recordJourney(oldEntry)
        try await historyService.recordJourney(recentEntry)
        
        // Fetch last month only
        let lastMonthEntries = try await historyService.fetchHistory(for: .lastMonth)
        
        XCTAssertEqual(lastMonthEntries.count, 1)
        XCTAssertEqual(lastMonthEntries.first?.routeName, "Recent Route")
        
        // Fetch all entries
        let allEntries = try await historyService.fetchHistory(for: .all)
        XCTAssertEqual(allEntries.count, 2)
    }
    
    func testGenerateStatistics() async throws {
        let routeId1 = UUID()
        let routeId2 = UUID()
        
        // Create multiple journey entries
        let entries = [
            JourneyHistoryEntry(routeId: routeId1, routeName: "Route 1", departureTime: Date(), arrivalTime: Date().addingTimeInterval(1800), delayMinutes: 0),
            JourneyHistoryEntry(routeId: routeId1, routeName: "Route 1", departureTime: Date(), arrivalTime: Date().addingTimeInterval(1800), delayMinutes: 5),
            JourneyHistoryEntry(routeId: routeId2, routeName: "Route 2", departureTime: Date(), arrivalTime: Date().addingTimeInterval(1800), delayMinutes: 10),
        ]
        
        for entry in entries {
            try await historyService.recordJourney(entry)
        }
        
        // Generate statistics
        let statistics = try await historyService.generateStatistics(for: .all)
        
        XCTAssertEqual(statistics.totalJourneys, 3)
        XCTAssertEqual(statistics.averageDelayMinutes, 5.0) // (0 + 5 + 10) / 3
        XCTAssertEqual(statistics.mostUsedRouteId, routeId1) // Route 1 has 2 journeys
        XCTAssertEqual(statistics.mostUsedRouteName, "Route 1")
        XCTAssertEqual(statistics.onTimePercentage, 33.33, accuracy: 0.1) // 1 out of 3 on time (≤2 min delay)
    }
    
    // MARK: - Privacy Manager Tests
    
    func testPrivacyConsentManagement() async {
        // Initially no consent
        XCTAssertFalse(privacyManager.hasJourneyTrackingConsent)
        XCTAssertFalse(privacyManager.isJourneyTrackingEnabled)
        
        // Request consent
        let consentGranted = await privacyManager.requestJourneyTrackingConsent()
        XCTAssertTrue(consentGranted)
        XCTAssertTrue(privacyManager.hasJourneyTrackingConsent)
        XCTAssertTrue(privacyManager.isJourneyTrackingEnabled)
        
        // Revoke consent
        await privacyManager.revokeConsent()
        XCTAssertFalse(privacyManager.hasJourneyTrackingConsent)
        XCTAssertFalse(privacyManager.isJourneyTrackingEnabled)
    }
    
    func testDataRetentionSettings() {
        // Test default retention period
        XCTAssertEqual(privacyManager.dataRetentionMonths, 12)
        
        // Test setting custom retention period
        privacyManager.dataRetentionMonths = 6
        XCTAssertEqual(privacyManager.dataRetentionMonths, 6)
        
        // Test bounds checking
        privacyManager.dataRetentionMonths = 50 // Should be clamped to 36
        XCTAssertEqual(privacyManager.dataRetentionMonths, 36)
        
        privacyManager.dataRetentionMonths = 0 // Should be clamped to 1
        XCTAssertEqual(privacyManager.dataRetentionMonths, 1)
    }
    
    func testAnonymizedHistoryEntry() {
        let routeId = UUID()
        let calendar = Calendar.current
        let departureTime = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: Date())! // 2:30 PM
        
        let entry = JourneyHistoryEntry(
            routeId: routeId,
            routeName: "Test Route",
            departureTime: departureTime,
            arrivalTime: departureTime.addingTimeInterval(1800),
            delayMinutes: 8
        )
        
        let anonymized = AnonymizedHistoryEntry(from: entry)
        
        XCTAssertEqual(anonymized.routeHash, String(routeId.hashValue))
        XCTAssertEqual(anonymized.timeSlot, .afternoon)
        XCTAssertEqual(anonymized.delayCategory, .moderateDelay)
        
        let year = calendar.component(.year, from: departureTime)
        let month = calendar.component(.month, from: departureTime)
        let expectedMonthYear = String(format: "%04d-%02d", year, month)
        XCTAssertEqual(anonymized.monthYear, expectedMonthYear)
    }
    
    // MARK: - Integration Tests
    
    func testJourneyHistoryViewModelIntegration() async {
        let viewModel = JourneyHistoryViewModel(historyService: historyService)

        // Enable tracking
        await MainActor.run {
            viewModel.isTrackingEnabled = true
        }
        
        // Record a journey
        let entry = JourneyHistoryEntry(
            routeId: UUID(),
            routeName: "Integration Test Route",
            departureTime: Date(),
            arrivalTime: Date().addingTimeInterval(1800),
            delayMinutes: 3
        )
        
        await viewModel.recordJourney(entry)
        
        // Load history
        await viewModel.loadHistory()

        // Access MainActor properties on the main actor
        let historyCount = await MainActor.run { viewModel.historyEntries.count }
        let firstRouteName = await MainActor.run { viewModel.historyEntries.first?.routeName }
        let statistics = await MainActor.run { viewModel.statistics }

        XCTAssertEqual(historyCount, 1)
        XCTAssertEqual(firstRouteName, "Integration Test Route")
        XCTAssertNotNil(statistics)
        XCTAssertEqual(statistics?.totalJourneys, 1)
    }
}