import Testing
import CoreLocation
import SwiftUI
@testable import TrainViewer

// MARK: - Interactive Smart Switching Test Scenarios

struct SmartWidgetInteractiveTests {

    // MARK: - Location Test Scenarios

    @Test("Interactive: Test smart switching at home location")
    func testSmartSwitchingAtHome() async throws {
        print("🧪 Testing Smart Switching: At Home Location")
        print("📍 Location: München Home (48.1351, 11.5820)")

        // Setup mock services
        let mockSettings = TestTestMockUserSettingsStore()
        let mockShared = TestTestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        // Configure home and campus locations
        let homePlace = createMockPlace(name: "Home - München", lat: 48.1351, lon: 11.5820)
        let campusPlace = createMockPlace(name: "Campus - TU München", lat: 48.1500, lon: 11.5800)

        mockSettings.homePlace = homePlace
        mockSettings.campusPlace = campusPlace

        // Simulate being at home location
        mockShared.saveLocationForSmartWidget(latitude: 48.1351, longitude: 11.5820)

        // Test location context determination
        let context = provider.determineLocationContext(homePlace: homePlace, campusPlace: campusPlace)

        print("🎯 Expected: .atHome (within home detection radius)")
        print("📊 Actual: \(context.location)")
        print("🎚️ Confidence: \(context.confidence)")

        #expect(context.location == LocationContext.LocationType.atHome)
        #expect(context.confidence == LocationContext.ConfidenceLevel.high)

        // Test smart route selection
        let smartRoute = provider.findSmartRoute(routes: [], context: context.location)
        print("🚆 Smart Route Selected: \(smartRoute?.name ?? "None")")

        if let route = smartRoute {
            print("✅ Route: \(route.name)")
            print("🏠 Origin matches home: \(route.origin.id == homePlace.id)")
            print("🏫 Destination matches campus: \(route.destination.id == campusPlace.id)")
        }
    }

    @Test("Interactive: Test smart switching at campus location")
    func testSmartSwitchingAtCampus() async throws {
        print("🧪 Testing Smart Switching: At Campus Location")
        print("📍 Location: TU München Campus (48.1500, 11.5800)")

        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let homePlace = createMockPlace(name: "Home - München", lat: 48.1351, lon: 11.5820)
        let campusPlace = createMockPlace(name: "Campus - TU München", lat: 48.1500, lon: 11.5800)

        mockSettings.homePlace = homePlace
        mockSettings.campusPlace = campusPlace

        // Simulate being at campus
        mockShared.saveLocationForSmartWidget(latitude: 48.1500, longitude: 11.5800)

        let context = provider.determineLocationContext(homePlace: homePlace, campusPlace: campusPlace)

        print("🎯 Expected: .atCampus (within campus detection radius)")
        print("📊 Actual: \(context.location)")
        print("🎚️ Confidence: \(context.confidence)")

        #expect(context.location == LocationContext.LocationType.atCampus)
        #expect(context.confidence == LocationContext.ConfidenceLevel.high)

        let smartRoute = provider.findSmartRoute(routes: [], context: context.location)
        print("🚆 Smart Route Selected: \(smartRoute?.name ?? "None")")
    }

    @Test("Interactive: Test smart switching near home")
    func testSmartSwitchingNearHome() async throws {
        print("🧪 Testing Smart Switching: Near Home Location")
        print("📍 Location: Near München Home (48.1450, 11.5820) - ~1km away")

        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let homePlace = createMockPlace(name: "Home - München", lat: 48.1351, lon: 11.5820)
        let campusPlace = createMockPlace(name: "Campus - TU München", lat: 48.1500, lon: 11.5800)

        mockSettings.homePlace = homePlace
        mockSettings.campusPlace = campusPlace

        // Simulate being near home (within 1km but outside detection radius)
        mockShared.saveLocationForSmartWidget(latitude: 48.1450, longitude: 11.5820)

        let context = provider.determineLocationContext(homePlace: homePlace, campusPlace: campusPlace)

        print("🎯 Expected: .nearHome (within 1km proximity)")
        print("📊 Actual: \(context.location)")
        print("🎚️ Confidence: \(context.confidence)")

        #expect(context.location == LocationContext.LocationType.nearHome)
        #expect(context.confidence == LocationContext.ConfidenceLevel.medium)
    }

    @Test("Interactive: Test smart switching - unknown location")
    func testSmartSwitchingUnknownLocation() async throws {
        print("🧪 Testing Smart Switching: Unknown Location (No GPS)")
        print("📍 Location: No location data available")

        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let homePlace = createMockPlace(name: "Home - München", lat: 48.1351, lon: 11.5820)
        let campusPlace = createMockPlace(name: "Campus - TU München", lat: 48.1500, lon: 11.5800)

        mockSettings.homePlace = homePlace
        mockSettings.campusPlace = campusPlace

        // No location data available (simulates GPS off)
        mockShared.currentLocation = nil

        let context = provider.determineLocationContext(homePlace: homePlace, campusPlace: campusPlace)

        print("🎯 Expected: .unknown (fallback to time-based logic)")
        print("📊 Actual: \(context.location)")
        print("🎚️ Confidence: \(context.confidence)")

        #expect(context.location == LocationContext.LocationType.unknown)
        #expect(context.confidence == LocationContext.ConfidenceLevel.low)
    }

    // MARK: - Time-Based Test Scenarios

    @Test("Interactive: Test morning time-based context")
    func testMorningTimeBasedContext() async throws {
        print("🧪 Testing Time-Based Context: Morning Commute")
        print("⏰ Time: 8:00 AM - Expected: At Home (planning to go to campus)")

        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        // Set time to 8 AM (morning)
        let morningTime = createDate(hour: 8, minute: 0)
        let context = provider.determineTimeBasedContext(at: morningTime)

        print("🎯 Expected: .atHome (morning commute time)")
        print("📊 Actual: \(context.location)")
        print("🎚️ Confidence: \(context.confidence)")

        #expect(context.location == LocationContext.LocationType.atHome)
        #expect(context.confidence == LocationContext.ConfidenceLevel.low)
    }

    @Test("Interactive: Test evening time-based context")
    func testEveningTimeBasedContext() async throws {
        print("🧪 Testing Time-Based Context: Evening Commute")
        print("⏰ Time: 6:00 PM - Expected: At Campus (planning to go home)")

        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        // Set time to 6 PM (evening)
        let eveningTime = createDate(hour: 18, minute: 0)
        let context = provider.determineTimeBasedContext(at: eveningTime)

        print("🎯 Expected: .atCampus (evening commute time)")
        print("📊 Actual: \(context.location)")
        print("🎚️ Confidence: \(context.confidence)")

        #expect(context.location == LocationContext.LocationType.atCampus)
        #expect(context.confidence == LocationContext.ConfidenceLevel.low)
    }

    @Test("Interactive: Test weekend time-based context")
    func testWeekendTimeBasedContext() async throws {
        print("🧪 Testing Time-Based Context: Weekend")
        print("⏰ Time: Saturday 2:00 PM - Expected: Near Campus (leisure time)")

        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        // Set time to Saturday afternoon
        let weekendTime = createDateForWeekday(weekday: 7, hour: 14, minute: 0) // Saturday = 7
        let context = provider.determineTimeBasedContext(at: weekendTime)

        print("🎯 Expected: .nearCampus (weekend - leisure activities)")
        print("📊 Actual: \(context.location)")
        print("🎚️ Confidence: \(context.confidence)")

        #expect(context.location == LocationContext.LocationType.nearCampus)
        #expect(context.confidence == LocationContext.ConfidenceLevel.low)
    }

    // MARK: - Smart Route Selection Scenarios

    @Test("Interactive: Test weekday route preference")
    func testWeekdayRoutePreference() async throws {
        print("🧪 Testing Route Selection: Weekday Route Preference")
        print("📅 Day: Monday - Should prefer Monday-specific route if available")

        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let homePlace = createMockPlace(name: "Home", lat: 48.1351, lon: 11.5820)
        let campusPlace = createMockPlace(name: "Campus", lat: 48.1500, lon: 11.5800)

        mockSettings.homePlace = homePlace
        mockSettings.campusPlace = campusPlace

        // Create routes
        let routes = createMockRoutes(homePlace: homePlace, campusPlace: campusPlace)
        mockSettings.routes = routes

        // Set Monday as preferred weekday for the first route
        let mondayRouteId = routes[0].id
        mockSettings.setWeekdayRoute(weekday: 2, routeId: mondayRouteId) // Monday = 2

        // Set current location to home
        mockShared.saveLocationForSmartWidget(latitude: 48.1351, longitude: 11.5820)

        // Set time to Monday morning
        let mondayMorning = createDateForWeekday(weekday: 2, hour: 8, minute: 0)
        let context = provider.determineLocationContext(homePlace: homePlace, campusPlace: campusPlace)

        print("🎯 Expected: Route with Monday preference")
        print("📊 Selected Route: \(provider.findSmartRoute(for: context.location)?.name ?? "None")")

        let smartRoute = provider.findSmartRoute(for: context.location)
        #expect(smartRoute?.id == mondayRouteId)
    }

    @Test("Interactive: Test fallback route selection")
    func testFallbackRouteSelection() async throws {
        print("🧪 Testing Route Selection: Fallback Logic")
        print("📊 Testing most recently used route fallback")

        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let homePlace = createMockPlace(name: "Home", lat: 48.1351, lon: 11.5820)
        let campusPlace = createMockPlace(name: "Campus", lat: 48.1500, lon: 11.5800)

        mockSettings.homePlace = homePlace
        mockSettings.campusPlace = campusPlace

        // Create routes with usage tracking
        let routes = createMockRoutes(homePlace: homePlace, campusPlace: campusPlace)
        mockSettings.routes = routes

        // Simulate usage (route 1 used more recently than route 0)
        mockSettings.updateRouteUsage(routeId: routes[1].id, timestamp: Date())
        mockSettings.updateRouteUsage(routeId: routes[0].id, timestamp: Date().addingTimeInterval(-3600))

        // Set location to unknown (will trigger fallback)
        mockShared.currentLocation = nil

        let context = provider.determineLocationContext(homePlace: homePlace, campusPlace: campusPlace)

        print("🎯 Expected: Most recently used route (route 1)")
        print("📊 Selected Route: \(provider.findSmartRoute(for: context.location)?.name ?? "None")")

        let smartRoute = provider.findSmartRoute(for: context.location)
        #expect(smartRoute?.id == routes[1].id)
    }

    // MARK: - Edge Cases

    @Test("Interactive: Test overlapping detection radii")
    func testOverlappingDetectionRadii() async throws {
        print("🧪 Testing Edge Case: Overlapping Detection Radii")
        print("📍 Location: Between home and campus (both within detection radius)")

        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        // Set smaller detection radii to create overlap scenario
        mockSettings.homeDetectionRadius = 1000.0  // 1km
        mockSettings.campusDetectionRadius = 1000.0 // 1km

        let homePlace = createMockPlace(name: "Home", lat: 48.1351, lon: 11.5820)
        let campusPlace = createMockPlace(name: "Campus", lat: 48.1450, lon: 11.5820) // Close together

        mockSettings.homePlace = homePlace
        mockSettings.campusPlace = campusPlace

        // Position exactly between home and campus
        mockShared.saveLocationForSmartWidget(latitude: 48.1400, longitude: 11.5820)

        let context = provider.determineLocationContext(homePlace: homePlace, campusPlace: campusPlace)

        print("🎯 Expected: Closer location wins (should be .atHome or .atCampus)")
        print("📊 Actual: \(context.location)")
        print("📏 Home Distance: ~500m, Campus Distance: ~500m")

        // Should choose the closer one (home in this case)
        #expect(context.location == LocationContext.LocationType.atHome || context.location == LocationContext.LocationType.atCampus)
        #expect(context.confidence == LocationContext.ConfidenceLevel.high)
    }

    @Test("Interactive: Test location timeout scenario")
    func testLocationTimeoutScenario() async throws {
        print("🧪 Testing Edge Case: Location Data Timeout")
        print("📍 Location: Old location data (>30 minutes)")

        let mockSettings = TestMockUserSettingsStore()
        let mockShared = TestMockSharedStore()
        let provider = SmartWidgetProvider(settings: mockSettings, shared: mockShared)

        let homePlace = createMockPlace(name: "Home", lat: 48.1351, lon: 11.5820)
        let campusPlace = createMockPlace(name: "Campus", lat: 48.1500, lon: 11.5800)

        mockSettings.homePlace = homePlace
        mockSettings.campusPlace = campusPlace

        // Set old location data (35 minutes ago)
        mockShared.saveLocationForSmartWidget(latitude: 48.1351, longitude: 11.5820)
        mockShared.locationTimestamp = Date().addingTimeInterval(-2100) // 35 minutes ago

        let context = provider.determineLocationContext(homePlace: homePlace, campusPlace: campusPlace)

        print("🎯 Expected: .unknown (old location data rejected)")
        print("📊 Actual: \(context.location)")
        print("⏰ Location Age: 35 minutes (>30 min threshold)")

        #expect(context.location == LocationContext.LocationType.unknown)
        #expect(context.confidence == LocationContext.ConfidenceLevel.low)
    }
}

// MARK: - Test Helper Extensions

extension SmartWidgetInteractiveTests {

    func createDate(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let components = DateComponents(hour: hour, minute: minute)
        return calendar.date(from: components) ?? Date()
    }

    func createDateForWeekday(weekday: Int, hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekday = weekday
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? Date()
    }

    func createMockPlace(name: String, lat: Double? = nil, lon: Double? = nil) -> Place {
        return Place(
            rawId: UUID().uuidString,
            name: name,
            latitude: lat,
            longitude: lon
        )
    }

    func createMockRoutes(homePlace: Place?, campusPlace: Place?) -> [Route] {
        var routes: [Route] = []

        if let home = homePlace, let campus = campusPlace {
            // Home to Campus route
            routes.append(Route(
                id: UUID(),
                name: "\(home.name) → \(campus.name)",
                origin: home,
                destination: campus
            ))

            // Campus to Home route
            routes.append(Route(
                id: UUID(),
                name: "\(campus.name) → \(home.name)",
                origin: campus,
                destination: home
            ))
        }

        return routes
    }
}

// MARK: - Enhanced Mock Classes for Interactive Testing

// Note: TestMockUserSettingsStore and TestMockSharedStore are defined in SmartWidgetTests.swift
// We can extend them here if needed, but for now we'll use them as-is
