import Testing
import CoreLocation
import SwiftUI
@testable import TrainViewer

// MARK: - Mock Services and Models

final class TestMockUserSettingsStore {
    var homePlace: Place?
    var campusPlace: Place?
    var smartWidgetEnabled: Bool = true
    var useTimeBasedFallback: Bool = true
    var vacationModeEnabled: Bool = false
    var locationSensitivity: Double = 300.0
    var homeDetectionRadius: Double = 300.0
    var campusDetectionRadius: Double = 500.0

    func resetSmartWidgetSettings() {
        homePlace = nil
        campusPlace = nil
        smartWidgetEnabled = true
        useTimeBasedFallback = true
        vacationModeEnabled = false
        locationSensitivity = 300.0
        homeDetectionRadius = 300.0
        campusDetectionRadius = 500.0
    }
}

final class TestTestMockSharedStore {
    var currentLocation: CLLocationCoordinate2D?
    var locationTimestamp: Date?

    func saveLocationForSmartWidget(latitude: Double, longitude: Double) {
        currentLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        locationTimestamp = Date()
    }

    func getCurrentLocationFromSharedStorage() -> CLLocationCoordinate2D? {
        return currentLocation
    }
}

struct MockWidgetDataLoader {
    static func requestMainAppRefresh() {
        // Mock implementation - no-op for testing
    }
}

// MARK: - Smart Widget Setup Step View Tests

struct SmartWidgetSetupStepViewTests {

    // MARK: - Location Search Tests

    @Test("SmartWidgetSetupStepView searches locations correctly")
    func testLocationSearch() async throws {
        // Given
        let mockSettings = TestTestMockUserSettingsStore()
        let viewModel = SmartWidgetSetupViewModel(settings: mockSettings)

        // When
        viewModel.searchLocations(query: "München", for: .home)

        // Then
        #expect(viewModel.homeResults.count > 0)
        #expect(viewModel.homeResults.contains { $0.name.contains("München") })
    }

    @Test("SmartWidgetSetupStepView filters search results by query")
    func testLocationSearchFiltering() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let viewModel = SmartWidgetSetupViewModel(settings: mockSettings)

        // When
        viewModel.searchLocations(query: "Berlin", for: .home)

        // Then
        #expect(viewModel.homeResults.allSatisfy { $0.name.contains("Berlin") })
    }

    @Test("SmartWidgetSetupStepView handles empty query")
    func testEmptyQueryHandling() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let viewModel = SmartWidgetSetupViewModel(settings: mockSettings)

        // When
        viewModel.searchLocations(query: "", for: .home)

        // Then
        #expect(viewModel.homeResults.isEmpty)
    }

    @Test("SmartWidgetSetupStepView handles short query")
    func testShortQueryHandling() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let viewModel = SmartWidgetSetupViewModel(settings: mockSettings)

        // When
        viewModel.searchLocations(query: "M", for: .home)

        // Then
        #expect(viewModel.homeResults.isEmpty)
    }

    // MARK: - Location Selection Tests

    @Test("SmartWidgetSetupStepView selects home location correctly")
    func testHomeLocationSelection() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let viewModel = SmartWidgetSetupViewModel(settings: mockSettings)
        let testPlace = createMockPlace(name: "München Hauptbahnhof")

        // When
        viewModel.selectHomeLocation(testPlace)

        // Then
        #expect(viewModel.selectedHome == testPlace)
        #expect(viewModel.homeQuery == testPlace.name)
        #expect(viewModel.homeResults.isEmpty)
    }

    @Test("SmartWidgetSetupStepView selects campus location correctly")
    func testCampusLocationSelection() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let viewModel = SmartWidgetSetupViewModel(settings: mockSettings)
        let testPlace = createMockPlace(name: "TU München")

        // When
        viewModel.selectCampusLocation(testPlace)

        // Then
        #expect(viewModel.selectedCampus == testPlace)
        #expect(viewModel.campusQuery == testPlace.name)
        #expect(viewModel.campusResults.isEmpty)
    }

    // MARK: - Validation Tests

    @Test("SmartWidgetSetupStepView validates complete setup")
    func testCompleteSetupValidation() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let viewModel = SmartWidgetSetupViewModel(settings: mockSettings)
        let homePlace = createMockPlace(name: "Home Station")
        let campusPlace = createMockPlace(name: "Campus Station")

        // When
        viewModel.selectHomeLocation(homePlace)
        viewModel.selectCampusLocation(campusPlace)

        // Then
        #expect(viewModel.isSetupComplete == true)
        #expect(viewModel.setupStatusMessage.contains("Smart Widget Ready"))
    }

    @Test("SmartWidgetSetupStepView validates incomplete home setup")
    func testIncompleteHomeSetup() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let viewModel = SmartWidgetSetupViewModel(settings: mockSettings)
        let campusPlace = createMockPlace(name: "Campus Station")

        // When
        viewModel.selectCampusLocation(campusPlace)

        // Then
        #expect(viewModel.isSetupComplete == false)
        #expect(viewModel.selectedHome == nil)
    }

    @Test("SmartWidgetSetupStepView validates incomplete campus setup")
    func testIncompleteCampusSetup() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let viewModel = SmartWidgetSetupViewModel(settings: mockSettings)
        let homePlace = createMockPlace(name: "Home Station")

        // When
        viewModel.selectHomeLocation(homePlace)

        // Then
        #expect(viewModel.isSetupComplete == false)
        #expect(viewModel.selectedCampus == nil)
    }

    // MARK: - Settings Persistence Tests

    @Test("SmartWidgetSetupStepView saves locations to settings")
    func testSettingsPersistence() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let viewModel = SmartWidgetSetupViewModel(settings: mockSettings)
        let homePlace = createMockPlace(name: "Home Station")
        let campusPlace = createMockPlace(name: "Campus Station")

        // When
        viewModel.selectHomeLocation(homePlace)
        viewModel.selectCampusLocation(campusPlace)
        viewModel.saveLocations()

        // Then
        #expect(mockSettings.homePlace?.id == homePlace.id)
        #expect(mockSettings.campusPlace?.id == campusPlace.id)
    }

    @Test("SmartWidgetSetupStepView handles save with incomplete setup")
    func testSaveIncompleteSetup() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let viewModel = SmartWidgetSetupViewModel(settings: mockSettings)
        let homePlace = createMockPlace(name: "Home Station")

        // When
        viewModel.selectHomeLocation(homePlace)
        viewModel.saveLocations()

        // Then
        #expect(mockSettings.homePlace?.id == homePlace.id)
        #expect(mockSettings.campusPlace == nil)
    }
}

// MARK: - Smart Widget Provider Tests

struct SmartWidgetProviderTests {

    // MARK: - Location Context Tests

    @Test("SmartWidgetProvider determines location context at home")
    func testLocationContextAtHome() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let homePlace = createMockPlace(name: "Home", lat: 48.1351, lon: 11.5820) // München
        let campusPlace = createMockPlace(name: "Campus", lat: 48.1500, lon: 11.5800) // Different location

        mockSettings.homePlace = homePlace
        mockSettings.campusPlace = campusPlace

        // User is at home location
        mockShared.saveLocationForSmartWidget(latitude: 48.1351, longitude: 11.5820)

        // When
        let context = provider.determineLocationContext(homePlace: homePlace, campusPlace: campusPlace)

        // Then
        #expect(context.location == .atHome)
        #expect(context.confidence == .high)
    }

    @Test("SmartWidgetProvider determines location context at campus")
    func testLocationContextAtCampus() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let homePlace = createMockPlace(name: "Home", lat: 48.1351, lon: 11.5820)
        let campusPlace = createMockPlace(name: "Campus", lat: 48.1500, lon: 11.5800)

        mockSettings.homePlace = homePlace
        mockSettings.campusPlace = campusPlace

        // User is at campus location
        mockShared.saveLocationForSmartWidget(latitude: 48.1500, longitude: 11.5800)

        // When
        let context = provider.determineLocationContext(homePlace: homePlace, campusPlace: campusPlace)

        // Then
        #expect(context.location == .atCampus)
        #expect(context.confidence == .high)
    }

    @Test("SmartWidgetProvider determines location context near home")
    func testLocationContextNearHome() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let homePlace = createMockPlace(name: "Home", lat: 48.1351, lon: 11.5820)
        let campusPlace = createMockPlace(name: "Campus", lat: 48.1500, lon: 11.5800)

        mockSettings.homePlace = homePlace
        mockSettings.campusPlace = campusPlace

        // User is near home (within 1km but outside detection radius)
        mockShared.saveLocationForSmartWidget(latitude: 48.1450, longitude: 11.5820)

        // When
        let context = provider.determineLocationContext(homePlace: homePlace, campusPlace: campusPlace)

        // Then
        #expect(context.location == .nearHome)
        #expect(context.confidence == .medium)
    }

    @Test("SmartWidgetProvider determines location context near campus")
    func testLocationContextNearCampus() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let homePlace = createMockPlace(name: "Home", lat: 48.1351, lon: 11.5820)
        let campusPlace = createMockPlace(name: "Campus", lat: 48.1500, lon: 11.5800)

        mockSettings.homePlace = homePlace
        mockSettings.campusPlace = campusPlace

        // User is near campus (within 1km but outside detection radius)
        mockShared.saveLocationForSmartWidget(latitude: 48.1400, longitude: 11.5800)

        // When
        let context = provider.determineLocationContext(homePlace: homePlace, campusPlace: campusPlace)

        // Then
        #expect(context.location == .nearCampus)
        #expect(context.confidence == .medium)
    }

    @Test("SmartWidgetProvider falls back to time-based context when location unknown")
    func testLocationContextUnknown() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let homePlace = createMockPlace(name: "Home", lat: 48.1351, lon: 11.5820)
        let campusPlace = createMockPlace(name: "Campus", lat: 48.1500, lon: 11.5800)

        mockSettings.homePlace = homePlace
        mockSettings.campusPlace = campusPlace

        // No location data available
        mockShared.currentLocation = nil

        // When
        let context = provider.determineLocationContext(homePlace: homePlace, campusPlace: campusPlace)

        // Then
        #expect(context.location == .unknown)
        #expect(context.confidence == .low)
    }

    // MARK: - Time-Based Context Tests

    @Test("SmartWidgetProvider determines morning time-based context")
    func testTimeBasedContextMorning() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        // Set time to 8 AM (typical morning commute)
        let morningTime = createDate(hour: 8, minute: 0)

        // When
        let context = provider.determineTimeBasedContext(at: morningTime)

        // Then
        #expect(context.location == .atHome)
        #expect(context.confidence == .low)
    }

    @Test("SmartWidgetProvider determines evening time-based context")
    func testTimeBasedContextEvening() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        // Set time to 6 PM (typical evening commute)
        let eveningTime = createDate(hour: 18, minute: 0)

        // When
        let context = provider.determineTimeBasedContext(at: eveningTime)

        // Then
        #expect(context.location == .atCampus)
        #expect(context.confidence == .low)
    }

    @Test("SmartWidgetProvider determines midday time-based context")
    func testTimeBasedContextMidday() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        // Set time to 2 PM (midday - ambiguous)
        let middayTime = createDate(hour: 14, minute: 0)

        // When
        let context = provider.determineTimeBasedContext(at: middayTime)

        // Then
        #expect(context.location == .unknown)
        #expect(context.confidence == .low)
    }

    // MARK: - Route Selection Tests

    @Test("SmartWidgetProvider finds smart route for home to campus")
    func testSmartRouteSelectionHomeToCampus() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let homePlace = createMockPlace(name: "Home", lat: 48.1351, lon: 11.5820)
        let campusPlace = createMockPlace(name: "Campus", lat: 48.1500, lon: 11.5800)
        let routes = createMockRoutes(homePlace: homePlace, campusPlace: campusPlace)

        mockSettings.homePlace = homePlace
        mockSettings.campusPlace = campusPlace

        // User is at home
        mockShared.saveLocationForSmartWidget(latitude: 48.1351, longitude: 11.5820)

        // When
        let smartRoute = provider.findSmartRoute(routes: routes, context: .atHome)

        // Then
        #expect(smartRoute != nil)
        #expect(smartRoute?.origin.id == homePlace.id)
        #expect(smartRoute?.destination.id == campusPlace.id)
    }

    @Test("SmartWidgetProvider finds smart route for campus to home")
    func testSmartRouteSelectionCampusToHome() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let homePlace = createMockPlace(name: "Home", lat: 48.1351, lon: 11.5820)
        let campusPlace = createMockPlace(name: "Campus", lat: 48.1500, lon: 11.5800)
        let routes = createMockRoutes(homePlace: homePlace, campusPlace: campusPlace)

        mockSettings.homePlace = homePlace
        mockSettings.campusPlace = campusPlace

        // User is at campus
        mockShared.saveLocationForSmartWidget(latitude: 48.1500, longitude: 11.5800)

        // When
        let smartRoute = provider.findSmartRoute(routes: routes, context: .atCampus)

        // Then
        #expect(smartRoute != nil)
        #expect(smartRoute?.origin.id == campusPlace.id)
        #expect(smartRoute?.destination.id == homePlace.id)
    }

    @Test("SmartWidgetProvider falls back to default route when no smart route found")
    func testSmartRouteFallback() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let routes = createMockRoutes(homePlace: nil, campusPlace: nil)

        // When
        let smartRoute = provider.findSmartRoute(routes: routes, context: .unknown)

        // Then
        #expect(smartRoute == routes.first)
    }

    // MARK: - Widget Entry Generation Tests

    @Test("SmartWidgetProvider generates widget entry for home to campus route")
    func testWidgetEntryGenerationHomeToCampus() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let homePlace = createMockPlace(name: "Home", lat: 48.1351, lon: 11.5820)
        let campusPlace = createMockPlace(name: "Campus", lat: 48.1500, lon: 11.5800)
        let route = createMockRoute(origin: homePlace, destination: campusPlace)

        mockSettings.homePlace = homePlace
        mockSettings.campusPlace = campusPlace

        // When
        let entry = provider.getSmartRouteEntry(
            for: route,
            context: .atHome,
            homePlace: homePlace,
            campusPlace: campusPlace
        )

        // Then
        #expect(entry.routeName == "Home → Campus")
        #expect(entry.platform == "Platform 1")
        #expect(entry.direction == "towards Campus")
        #expect(entry.status == .onTime)
    }

    @Test("SmartWidgetProvider generates widget entry for campus to home route")
    func testWidgetEntryGenerationCampusToHome() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let homePlace = createMockPlace(name: "Home", lat: 48.1351, lon: 11.5820)
        let campusPlace = createMockPlace(name: "Campus", lat: 48.1500, lon: 11.5800)
        let route = createMockRoute(origin: campusPlace, destination: homePlace)

        mockSettings.homePlace = homePlace
        mockSettings.campusPlace = campusPlace

        // When
        let entry = provider.getSmartRouteEntry(
            for: route,
            context: .atCampus,
            homePlace: homePlace,
            campusPlace: campusPlace
        )

        // Then
        #expect(entry.routeName == "Campus → Home")
        #expect(entry.platform == "Platform 1")
        #expect(entry.direction == "towards Home")
        #expect(entry.status == .onTime)
    }

    // MARK: - Error Handling Tests

    @Test("SmartWidgetProvider handles missing home location")
    func testMissingHomeLocationError() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let campusPlace = createMockPlace(name: "Campus", lat: 48.1500, lon: 11.5800)
        mockSettings.campusPlace = campusPlace

        // When
        let context = provider.determineLocationContext(homePlace: nil, campusPlace: campusPlace)

        // Then
        #expect(context.location == .unknown)
        #expect(context.confidence == .low)
    }

    @Test("SmartWidgetProvider handles missing campus location")
    func testMissingCampusLocationError() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let homePlace = createMockPlace(name: "Home", lat: 48.1351, lon: 11.5820)
        mockSettings.homePlace = homePlace

        // When
        let context = provider.determineLocationContext(homePlace: homePlace, campusPlace: nil)

        // Then
        #expect(context.location == .unknown)
        #expect(context.confidence == .low)
    }

    @Test("SmartWidgetProvider handles routes without coordinates")
    func testRoutesWithoutCoordinates() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let homePlace = createMockPlace(name: "Home", lat: nil, lon: nil)
        let campusPlace = createMockPlace(name: "Campus", lat: nil, lon: nil)
        let routes = createMockRoutes(homePlace: homePlace, campusPlace: campusPlace)

        mockSettings.homePlace = homePlace
        mockSettings.campusPlace = campusPlace

        // When
        let smartRoute = provider.findSmartRoute(routes: routes, context: .atHome)

        // Then
        #expect(smartRoute == nil)
    }

    // MARK: - Refresh Interval Tests

    @Test("SmartWidgetProvider calculates refresh interval for high confidence")
    func testRefreshIntervalHighConfidence() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let entry = createMockWidgetEntry(leaveInMinutes: 10)
        let context = LocationContext(location: .atHome, confidence: .high)

        // When
        let refreshInterval = provider.calculateRefreshInterval(for: entry, context: context)

        // Then
        #expect(refreshInterval == 60) // Should be 1 minute for high confidence, 10 min leave time
    }

    @Test("SmartWidgetProvider calculates refresh interval for medium confidence")
    func testRefreshIntervalMediumConfidence() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let entry = createMockWidgetEntry(leaveInMinutes: 10)
        let context = LocationContext(location: .nearHome, confidence: .medium)

        // When
        let refreshInterval = provider.calculateRefreshInterval(for: entry, context: context)

        // Then
        #expect(refreshInterval == 90) // Should be 1.5 minutes for medium confidence, 10 min leave time
    }

    @Test("SmartWidgetProvider calculates refresh interval for urgent departure")
    func testRefreshIntervalUrgentDeparture() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let entry = createMockWidgetEntry(leaveInMinutes: 3)
        let context = LocationContext(location: .atHome, confidence: .high)

        // When
        let refreshInterval = provider.calculateRefreshInterval(for: entry, context: context)

        // Then
        #expect(refreshInterval == 30) // Should be 30 seconds for urgent departure
    }

    // MARK: - Smart Fallback Time Calculation Tests

    @Test("SmartWidgetProvider calculates different fallback departure times for different contexts")
    func testSmartFallbackDepartureTimeVariation() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let now = Date()
        let homeContext = LocationContext(location: .atHome, confidence: .high)
        let campusContext = LocationContext(location: .atCampus, confidence: .high)
        let nearHomeContext = LocationContext(location: .nearHome, confidence: .medium)
        let nearCampusContext = LocationContext(location: .nearCampus, confidence: .medium)

        // When
        let homeDeparture = provider.calculateSmartFallbackDepartureTime(now, for: homeContext)
        let campusDeparture = provider.calculateSmartFallbackDepartureTime(now, for: campusContext)
        let nearHomeDeparture = provider.calculateSmartFallbackDepartureTime(now, for: nearHomeContext)
        let nearCampusDeparture = provider.calculateSmartFallbackDepartureTime(now, for: nearCampusContext)

        // Then - All departure times should be different and in the future
        #expect(homeDeparture > now)
        #expect(campusDeparture > now)
        #expect(nearHomeDeparture > now)
        #expect(nearCampusDeparture > now)

        // Convert to minutes for comparison (allowing for some variation)
        let homeMinutes = Int(homeDeparture.timeIntervalSince(now) / 60)
        let campusMinutes = Int(campusDeparture.timeIntervalSince(now) / 60)
        let nearHomeMinutes = Int(nearHomeDeparture.timeIntervalSince(now) / 60)
        let nearCampusMinutes = Int(nearCampusDeparture.timeIntervalSince(now) / 60)

        // They should be reasonably close but not identical (within 10 minutes of each other)
        let departures = [homeMinutes, campusMinutes, nearHomeMinutes, nearCampusMinutes]
        let minDeparture = departures.min()!
        let maxDeparture = departures.max()!

        #expect(maxDeparture - minDeparture <= 10) // All within 10 minutes of each other
        #expect(maxDeparture - minDeparture > 0) // But not all identical
    }

    @Test("SmartWidgetProvider estimates realistic trip durations")
    func testTripDurationEstimation() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let sBahnRoute = createMockWidgetRoute(name: "S-Bahn München")
        let iceRoute = createMockWidgetRoute(name: "ICE Berlin-München")
        let context = LocationContext(location: .atHome, confidence: .high)

        // When
        let sBahnDuration = provider.estimateTripDuration(sBahnRoute, context)
        let iceDuration = provider.estimateTripDuration(iceRoute, context)

        // Then
        #expect(sBahnDuration > 0)
        #expect(iceDuration > 0)
        #expect(sBahnDuration < iceDuration) // S-Bahn should be shorter than ICE

        // S-Bahn should be around 20 minutes (with randomization)
        let sBahnMinutes = sBahnDuration / 60
        #expect(sBahnMinutes >= 16) // 20 * 0.8 (context multiplier)
        #expect(sBahnMinutes <= 30) // With randomization

        // ICE should be around 60 minutes (with randomization)
        let iceMinutes = iceDuration / 60
        #expect(iceMinutes >= 48) // 60 * 0.8 (context multiplier)
        #expect(iceMinutes <= 90) // With randomization
    }

    @Test("SmartWidgetProvider calculates leave in minutes correctly")
    func testLeaveInMinutesCalculation() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let now = Date()
        let departureIn5Min = now.addingTimeInterval(300) // 5 minutes from now
        let departureIn2Min = now.addingTimeInterval(120) // 2 minutes from now

        // When
        let leaveIn5Min = provider.calculateLeaveInMinutes(departureIn5Min, now)
        let leaveIn2Min = provider.calculateLeaveInMinutes(departureIn2Min, now)

        // Then
        #expect(leaveIn5Min == 5)
        #expect(leaveIn2Min >= 3) // Should be at least 3 minutes minimum
    }

    @Test("SmartWidgetProvider context variation offsets are different")
    func testContextVariationOffsets() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        // When
        let homeOffset = provider.contextVariationOffset(for: LocationContext(location: .atHome, confidence: .high))
        let campusOffset = provider.contextVariationOffset(for: LocationContext(location: .atCampus, confidence: .high))
        let nearHomeOffset = provider.contextVariationOffset(for: LocationContext(location: .nearHome, confidence: .medium))
        let nearCampusOffset = provider.contextVariationOffset(for: LocationContext(location: .nearCampus, confidence: .medium))
        let unknownOffset = provider.contextVariationOffset(for: LocationContext(location: .unknown, confidence: .low))

        // Then
        #expect(homeOffset == 1)
        #expect(campusOffset == 3)
        #expect(nearHomeOffset == 2)
        #expect(nearCampusOffset == 4)
        #expect(unknownOffset == 0)

        // All offsets should be different except unknown
        let offsets = [homeOffset, campusOffset, nearHomeOffset, nearCampusOffset]
        #expect(Set(offsets).count == 4) // All unique
    }
}

// MARK: - Integration Tests

struct SmartWidgetIntegrationTests {

    @Test("Complete smart widget workflow from setup to display")
    func testCompleteSmartWidgetWorkflow() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let setupViewModel = SmartWidgetSetupViewModel(settings: mockSettings)
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        // Setup locations
        let homePlace = createMockPlace(name: "München Hauptbahnhof", lat: 48.1402, lon: 11.5580)
        let campusPlace = createMockPlace(name: "TU München", lat: 48.1500, lon: 11.5800)

        // 1. Complete setup
        setupViewModel.selectHomeLocation(homePlace)
        setupViewModel.selectCampusLocation(campusPlace)
        setupViewModel.saveLocations()

        // 2. Simulate user at home
        mockShared.saveLocationForSmartWidget(latitude: 48.1402, longitude: 11.5580)

        // 3. Create routes
        let routes = createMockRoutes(homePlace: homePlace, campusPlace: campusPlace)

        // When
        let context = provider.determineLocationContext(homePlace: homePlace, campusPlace: campusPlace)
        let smartRoute = provider.findSmartRoute(routes: routes, context: context.location)

        // Then
        #expect(context.location == .atHome)
        #expect(smartRoute != nil)
        #expect(smartRoute?.origin.id == homePlace.id)
        #expect(smartRoute?.destination.id == campusPlace.id)

        // 4. Generate widget entry
        if let route = smartRoute {
            let entry = provider.getSmartRouteEntry(
                for: route,
                context: context.location,
                homePlace: homePlace,
                campusPlace: campusPlace
            )

            #expect(entry.routeName == "Home → Campus")
            #expect(entry.status == .onTime)
        }
    }

    @Test("Smart widget handles location permission changes")
    func testLocationPermissionHandling() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let homePlace = createMockPlace(name: "Home", lat: 48.1351, lon: 11.5820)
        let campusPlace = createMockPlace(name: "Campus", lat: 48.1500, lon: 11.5800)

        mockSettings.homePlace = homePlace
        mockSettings.campusPlace = campusPlace

        // Simulate location permission denied
        mockShared.currentLocation = nil

        // When
        let context = provider.determineLocationContext(homePlace: homePlace, campusPlace: campusPlace)

        // Then
        #expect(context.location == .unknown)
        #expect(context.confidence == .low)
    }

    @Test("Smart widget handles vacation mode")
    func testVacationModeHandling() async throws {
        // Given
        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        mockSettings.vacationModeEnabled = true

        // When
        let shouldUseSmartLogic = provider.shouldUseSmartWidgetLogic()

        // Then
        #expect(shouldUseSmartLogic == false)
    }
}

// MARK: - Test Helper Extensions and Functions

extension SmartWidgetSetupStepViewTests {

    func createMockPlace(name: String, lat: Double? = nil, lon: Double? = nil) -> Place {
        return Place(
            id: UUID().uuidString,
            name: name,
            coordinate: lat != nil && lon != nil ?
                CLLocationCoordinate2D(latitude: lat!, longitude: lon!) : nil
        )
    }
}

extension SmartWidgetProviderTests {

    func createDate(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let components = DateComponents(hour: hour, minute: minute)
        return calendar.date(from: components) ?? Date()
    }

    func createMockRoutes(homePlace: Place?, campusPlace: Place?) -> [Route] {
        var routes: [Route] = []

        if let home = homePlace, let campus = campusPlace {
            // Home to Campus route
            routes.append(createMockRoute(origin: home, destination: campus))

            // Campus to Home route
            routes.append(createMockRoute(origin: campus, destination: home))
        }

        return routes
    }

    func createMockRoute(origin: Place, destination: Place) -> Route {
        return Route(
            id: UUID(),
            name: "\(origin.name) → \(destination.name)",
            origin: origin,
            destination: destination
        )
    }

    func createMockWidgetEntry(leaveInMinutes: Int) -> WidgetEntry {
        return WidgetEntry(
            date: Date(),
            routeName: "Test Route",
            departureTime: Date().addingTimeInterval(TimeInterval(leaveInMinutes * 60)),
            platform: "Platform 1",
            direction: "Test Direction",
            leaveInMinutes: leaveInMinutes,
            walkingTime: 5,
            status: .onTime,
            lastUpdated: Date()
        )
    }
}

extension SmartWidgetIntegrationTests {

    func createMockPlace(name: String, lat: Double? = nil, lon: Double? = nil) -> Place {
        return Place(
            id: UUID().uuidString,
            name: name,
            coordinate: lat != nil && lon != nil ?
                CLLocationCoordinate2D(latitude: lat!, longitude: lon!) : nil
        )
    }

    func createMockRoutes(homePlace: Place?, campusPlace: Place?) -> [Route] {
        var routes: [Route] = []

        if let home = homePlace, let campus = campusPlace {
            // Home to Campus route
            routes.append(createMockRoute(origin: home, destination: campus))

            // Campus to Home route
            routes.append(createMockRoute(origin: campus, destination: home))
        }

        return routes
    }

    func createMockRoute(origin: Place, destination: Place) -> Route {
        return Route(
            id: UUID(),
            name: "\(origin.name) → \(destination.name)",
            origin: origin,
            destination: destination
        )
    }

    func createMockWidgetRoute(name: String) -> WidgetRoute {
        let origin = WidgetPlace(rawId: UUID().uuidString, name: "Origin", latitude: 48.1351, longitude: 11.5820)
        let destination = WidgetPlace(rawId: UUID().uuidString, name: "Destination", latitude: 48.1500, longitude: 11.5800)

        return WidgetRoute(
            id: UUID(),
            name: name,
            origin: origin,
            destination: destination
        )
    }
}

// MARK: - Shared Helper Functions

func createMockPlace(name: String, lat: Double? = nil, lon: Double? = nil) -> Place {
    return Place(
        id: UUID().uuidString,
        name: name,
        coordinate: lat != nil && lon != nil ?
            CLLocationCoordinate2D(latitude: lat!, longitude: lon!) : nil
    )
}

// MARK: - Mock View Model for Testing

class SmartWidgetSetupViewModel {
    private let settings: TestMockUserSettingsStore

    var homeQuery: String = ""
    var campusQuery: String = ""
    var homeResults: [Place] = []
    var campusResults: [Place] = []
    var selectedHome: Place?
    var selectedCampus: Place?

    var isSetupComplete: Bool {
        return selectedHome != nil && selectedCampus != nil
    }

    var setupStatusMessage: String {
        if isSetupComplete {
            return "🎯 Smart Widget Ready!"
        } else if selectedHome != nil {
            return "Please select your campus/work location"
        } else if selectedCampus != nil {
            return "Please select your home location"
        } else {
            return "Set up your home and campus locations"
        }
    }

    init(settings: TestMockUserSettingsStore) {
        self.settings = settings
    }

    func searchLocations(query: String, for type: LocationType) {
        guard query.count >= 2 else {
            if type == .home {
                homeResults = []
            } else {
                campusResults = []
            }
            return
        }

        let sampleLocations = [
            createMockPlace(name: "München Hauptbahnhof", lat: 48.1402, lon: 11.5580),
            createMockPlace(name: "München Ostbahnhof", lat: 48.1270, lon: 11.6040),
            createMockPlace(name: "TU München", lat: 48.1500, lon: 11.5800),
            createMockPlace(name: "Berlin Hauptbahnhof", lat: 52.5250, lon: 13.3690)
        ]

        let filtered = sampleLocations.filter { place in
            place.name.localizedCaseInsensitiveContains(query)
        }

        if type == .home {
            homeResults = filtered
        } else {
            campusResults = filtered
        }
    }

    func selectHomeLocation(_ place: Place) {
        selectedHome = place
        homeQuery = place.name
        homeResults = []
    }

    func selectCampusLocation(_ place: Place) {
        selectedCampus = place
        campusQuery = place.name
        campusResults = []
    }

    func saveLocations() {
        settings.homePlace = selectedHome
        settings.campusPlace = selectedCampus
    }

    enum LocationType {
        case home, campus
    }
}

// MARK: - Mock Smart Widget Provider

class SmartWidgetProvider {
    private let settings: TestMockUserSettingsStore
    private let shared: TestMockSharedStore

    init(settings: TestMockUserSettingsStore, shared: TestMockSharedStore) {
        self.settings = settings
        self.shared = shared
    }

    func determineLocationContext(homePlace: Place?, campusPlace: Place?) -> LocationContext {
        guard let currentLocation = shared.getCurrentLocationFromSharedStorage(),
              let home = homePlace,
              let campus = campusPlace else {
            return LocationContext(location: .unknown, confidence: .low)
        }

        let homeDistance = distanceBetween(currentLocation, home.coordinate!)
        let campusDistance = distanceBetween(currentLocation, campus.coordinate!)

        let homeRadius = settings.homeDetectionRadius
        let campusRadius = settings.campusDetectionRadius
        let proximityRadius: CLLocationDistance = 1000

        if homeDistance <= homeRadius && homeDistance < campusDistance {
            return LocationContext(location: .atHome, confidence: .high)
        } else if campusDistance <= campusRadius && campusDistance < homeDistance {
            return LocationContext(location: .atCampus, confidence: .high)
        } else if homeDistance <= homeRadius && campusDistance <= campusRadius {
            return homeDistance <= campusDistance ?
                LocationContext(location: .atHome, confidence: .high) :
                LocationContext(location: .atCampus, confidence: .high)
        } else if min(homeDistance, campusDistance) <= proximityRadius {
            return homeDistance < campusDistance ?
                LocationContext(location: .nearHome, confidence: .medium) :
                LocationContext(location: .nearCampus, confidence: .medium)
        }

        return determineTimeBasedContext(at: Date())
    }

    func determineTimeBasedContext(at date: Date) -> LocationContext {
        let hour = Calendar.current.component(.hour, from: date)

        // Morning hours (6-11): likely at home heading to campus
        if hour >= 6 && hour <= 11 {
            return LocationContext(location: .atHome, confidence: .low)
        }
        // Evening hours (15-20): likely at campus heading home
        else if hour >= 15 && hour <= 20 {
            return LocationContext(location: .atCampus, confidence: .low)
        }
        // Other hours: unknown
        else {
            return LocationContext(location: .unknown, confidence: .low)
        }
    }

    func findSmartRoute(routes: [Route], context: LocationContext.LocationType) -> Route? {
        guard let homePlace = settings.homePlace,
              let campusPlace = settings.campusPlace else {
            return routes.first
        }

        switch context {
        case .atHome:
            return routes.first { isRouteFromTo($0, from: homePlace, to: campusPlace) }
        case .atCampus:
            return routes.first { isRouteFromTo($0, from: campusPlace, to: homePlace) }
        case .nearHome:
            return routes.first { isRouteFromTo($0, from: homePlace, to: campusPlace) }
        case .nearCampus:
            return routes.first { isRouteFromTo($0, from: campusPlace, to: homePlace) }
        case .unknown:
            return routes.first
        }
    }

    func getSmartRouteEntry(
        for route: Route,
        context: LocationContext.LocationType,
        homePlace: Place,
        campusPlace: Place
    ) -> WidgetEntry {
        let routeName: String
        let direction: String

        switch context {
        case .atHome:
            routeName = "Home → Campus"
            direction = "towards Campus"
        case .atCampus:
            routeName = "Campus → Home"
            direction = "towards Home"
        case .nearHome:
            routeName = "Near Home → Campus"
            direction = "towards Campus"
        case .nearCampus:
            routeName = "Near Campus → Home"
            direction = "towards Home"
        case .unknown:
            routeName = route.name
            direction = "Unknown direction"
        }

        return WidgetEntry(
            date: Date(),
            routeName: routeName,
            departureTime: Date().addingTimeInterval(600), // 10 minutes from now
            platform: "Platform 1",
            direction: direction,
            leaveInMinutes: 10,
            walkingTime: 5,
            status: .onTime,
            lastUpdated: Date()
        )
    }

    func calculateRefreshInterval(for entry: WidgetEntry, context: LocationContext) -> TimeInterval {
        let confidence = context.confidence
        let leaveInMinutes = entry.leaveInMinutes

        switch confidence {
        case .high:
            if leaveInMinutes <= 5 { return 30 }
            else if leaveInMinutes <= 15 { return 60 }
            else { return 300 }
        case .medium:
            if leaveInMinutes <= 5 { return 45 }
            else if leaveInMinutes <= 15 { return 90 }
            else { return 600 }
        case .low:
            if leaveInMinutes <= 5 { return 30 }
            else { return 120 }
        }
    }

    func shouldUseSmartWidgetLogic() -> Bool {
        return !settings.vacationModeEnabled && settings.smartWidgetEnabled
    }

    private func isRouteFromTo(_ route: Route, from: Place, to: Place) -> Bool {
        return route.origin.id == from.id && route.destination.id == to.id
    }
}

// MARK: - Mock Models

struct LocationContext {
    let location: LocationType
    let confidence: ConfidenceLevel

    enum LocationType {
        case atHome, atCampus, nearHome, nearCampus, unknown
    }

    enum ConfidenceLevel {
        case high, medium, low
    }
}

struct WidgetEntry {
    let date: Date
    let routeName: String
    let departureTime: Date
    let platform: String
    let direction: String
    let leaveInMinutes: Int
    let walkingTime: Int
    let status: WidgetStatus
    let lastUpdated: Date

    enum WidgetStatus {
        case onTime, delayed, cancelled, departNow
    }
}

func distanceBetween(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> CLLocationDistance {
    let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
    let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
    return location1.distance(from: location2)
}
