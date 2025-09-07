import Testing
@testable import TrainViewer

struct RouteEnhancementTests {
    
    let testPlace1 = Place(rawId: "test1", name: "Test Station 1", latitude: 52.5200, longitude: 13.4050)
    let testPlace2 = Place(rawId: "test2", name: "Test Station 2", latitude: 52.5170, longitude: 13.3888)
    
    // MARK: - RefreshInterval Tests
    
    @Test func refreshIntervalDisplayNames() {
        #expect(RefreshInterval.manual.displayName == "Manual Only")
        #expect(RefreshInterval.oneMinute.displayName == "1 Minute")
        #expect(RefreshInterval.fiveMinutes.displayName == "5 Minutes")
        #expect(RefreshInterval.tenMinutes.displayName == "10 Minutes")
        #expect(RefreshInterval.fifteenMinutes.displayName == "15 Minutes")
    }
    
    @Test func refreshIntervalTimeInterval() {
        #expect(RefreshInterval.manual.timeInterval == 0)
        #expect(RefreshInterval.oneMinute.timeInterval == 60)
        #expect(RefreshInterval.fiveMinutes.timeInterval == 300)
        #expect(RefreshInterval.tenMinutes.timeInterval == 600)
        #expect(RefreshInterval.fifteenMinutes.timeInterval == 900)
    }
    
    // MARK: - Route Model Tests
    
    @Test func routeInitializationWithEnhancedProperties() {
        let route = Route(
            name: "Test Route",
            origin: testPlace1,
            destination: testPlace2,
            customRefreshInterval: .oneMinute,
            usageCount: 5
        )
        
        #expect(route.customRefreshInterval == .oneMinute)
        #expect(route.usageCount == 5)
    }
    
    @Test func routeMarkAsUsed() {
        var route = Route(name: "Test", origin: testPlace1, destination: testPlace2, usageCount: 0)
        let initialUsageCount = route.usageCount
        
        route.markAsUsed()
        
        #expect(route.usageCount == initialUsageCount + 1)
    }
    
    @Test func routeToggleFavorite() {
        var route = Route(name: "Test", origin: testPlace1, destination: testPlace2, isFavorite: false)
        
        route.toggleFavorite()
        #expect(route.isFavorite == true)
        
        route.toggleFavorite()
        #expect(route.isFavorite == false)
    }
    
    @Test func routeUpdateRefreshInterval() {
        var route = Route(name: "Test", origin: testPlace1, destination: testPlace2)
        
        route.updateRefreshInterval(.tenMinutes)
        #expect(route.customRefreshInterval == .tenMinutes)
    }
    
    // MARK: - Usage Frequency Tests
    
    @Test func usageFrequencyDaily() {
        let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let route = Route(
            name: "Daily Route",
            origin: testPlace1,
            destination: testPlace2,
            createdAt: fiveDaysAgo,
            usageCount: 10 // 2 per day = daily
        )
        
        #expect(route.usageFrequency == .daily)
    }
    
    @Test func usageFrequencyWeekly() {
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let route = Route(
            name: "Weekly Route",
            origin: testPlace1,
            destination: testPlace2,
            createdAt: tenDaysAgo,
            usageCount: 4 // 0.4 per day = weekly
        )
        
        #expect(route.usageFrequency == .weekly)
    }
    
    @Test func usageFrequencyRarely() {
        let route = Route(
            name: "Rare Route",
            origin: testPlace1,
            destination: testPlace2,
            usageCount: 0
        )
        
        #expect(route.usageFrequency == .rarely)
    }
    
    // MARK: - UsageFrequency Enum Tests
    
    @Test func usageFrequencyDisplayNames() {
        #expect(UsageFrequency.daily.displayName == "Daily")
        #expect(UsageFrequency.weekly.displayName == "Weekly")
        #expect(UsageFrequency.monthly.displayName == "Monthly")
        #expect(UsageFrequency.rarely.displayName == "Rarely")
    }
    
    @Test func usageFrequencySortOrder() {
        #expect(UsageFrequency.daily.sortOrder == 0)
        #expect(UsageFrequency.weekly.sortOrder == 1)
        #expect(UsageFrequency.monthly.sortOrder == 2)
        #expect(UsageFrequency.rarely.sortOrder == 3)
    }
    
    // MARK: - RouteStatistics Tests
    
    @Test func routeStatisticsInitialization() {
        let routeId = UUID()
        let lastUsed = Date()
        let createdAt = Date().addingTimeInterval(-86400) // 1 day ago
        
        let statistics = RouteStatistics(
            routeId: routeId,
            usageCount: 5,
            usageFrequency: .weekly,
            lastUsed: lastUsed,
            createdAt: createdAt,
            averageDelayMinutes: 2.5,
            reliabilityScore: 0.85
        )
        
        #expect(statistics.routeId == routeId)
        #expect(statistics.usageCount == 5)
        #expect(statistics.usageFrequency == .weekly)
        #expect(statistics.lastUsed == lastUsed)
        #expect(statistics.createdAt == createdAt)
        #expect(statistics.averageDelayMinutes == 2.5)
        #expect(statistics.reliabilityScore == 0.85)
    }
    
    @Test func routeStatisticsWithDefaults() {
        let routeId = UUID()
        let lastUsed = Date()
        let createdAt = Date()
        
        let statistics = RouteStatistics(
            routeId: routeId,
            usageCount: 3,
            usageFrequency: .monthly,
            lastUsed: lastUsed,
            createdAt: createdAt
        )
        
        #expect(statistics.averageDelayMinutes == nil)
        #expect(statistics.reliabilityScore == 1.0)
    }
}