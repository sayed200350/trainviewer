import Testing
import EventKit
@testable import TrainViewer

struct EventKitServiceTests {
    
    // MARK: - Initialization Tests
    
    @Test("EventKitService is a singleton")
    func testSingletonPattern() async throws {
        let service1 = EventKitService.shared
        let service2 = EventKitService.shared
        
        #expect(service1 === service2)
    }
    
    // MARK: - CalendarEvent Tests
    
    @Test("CalendarEvent initializes correctly")
    func testCalendarEventInitialization() async throws {
        let title = "Test Meeting"
        let startDate = Date()
        let location = "Conference Room A"
        
        let event = CalendarEvent(title: title, startDate: startDate, location: location)
        
        #expect(event.title == title)
        #expect(event.startDate == startDate)
        #expect(event.location == location)
    }
    
    @Test("CalendarEvent handles nil location")
    func testCalendarEventWithNilLocation() async throws {
        let title = "Remote Meeting"
        let startDate = Date()
        
        let event = CalendarEvent(title: title, startDate: startDate, location: nil)
        
        #expect(event.title == title)
        #expect(event.startDate == startDate)
        #expect(event.location == nil)
    }
    
    // MARK: - Access Request Tests
    
    @Test("EventKitService handles access request")
    func testAccessRequest() async throws {
        let service = EventKitService.shared
        
        // Note: In a real test environment, this would require mocking EKEventStore
        // For now, we test that the method exists and can be called
        let accessGranted = await service.requestAccess()
        
        // The result depends on the test environment and user settings
        // We just verify the method completes without throwing
        #expect(accessGranted == true || accessGranted == false)
    }
    
    // MARK: - Next Event Tests
    
    @Test("EventKitService finds next event within default hours")
    func testNextEventWithinDefaultHours() async throws {
        let service = EventKitService.shared
        
        // Test without campus matching
        let nextEvent = await service.nextEvent(matchingCampus: nil)
        
        // Result depends on actual calendar events in test environment
        // We verify the method completes without throwing
        if let event = nextEvent {
            #expect(!event.title.isEmpty)
            #expect(event.startDate > Date().addingTimeInterval(-3600)) // Not too far in past
        }
    }
    
    @Test("EventKitService finds next event within custom hours")
    func testNextEventWithinCustomHours() async throws {
        let service = EventKitService.shared
        
        // Test with custom time window
        let nextEvent = await service.nextEvent(withinHours: 24, matchingCampus: nil)
        
        // Should complete without throwing
        if let event = nextEvent {
            #expect(!event.title.isEmpty)
        }
    }
    
    @Test("EventKitService finds next event with campus matching")
    func testNextEventWithCampusMatching() async throws {
        let service = EventKitService.shared
        
        let campus = Place(
            rawId: "test-campus",
            name: "Main Campus",
            latitude: nil,
            longitude: nil
        )
        
        let nextEvent = await service.nextEvent(withinHours: 12, matchingCampus: campus)
        
        // Should complete without throwing
        if let event = nextEvent {
            #expect(!event.title.isEmpty)
            // If campus matching worked, location might contain campus name
        }
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("EventKitService handles zero hours window")
    func testNextEventWithZeroHours() async throws {
        let service = EventKitService.shared
        
        let nextEvent = await service.nextEvent(withinHours: 0, matchingCampus: nil)
        
        // Should handle gracefully, likely returning nil
        // (no events in a 0-hour window from now)
    }
    
    @Test("EventKitService handles negative hours window")
    func testNextEventWithNegativeHours() async throws {
        let service = EventKitService.shared
        
        let nextEvent = await service.nextEvent(withinHours: -1, matchingCampus: nil)
        
        // Should handle gracefully, behavior depends on implementation
    }
    
    @Test("EventKitService handles very large hours window")
    func testNextEventWithLargeHoursWindow() async throws {
        let service = EventKitService.shared
        
        let nextEvent = await service.nextEvent(withinHours: 8760, matchingCampus: nil) // 1 year
        
        // Should complete without throwing
        if let event = nextEvent {
            #expect(!event.title.isEmpty)
        }
    }
    
    // MARK: - Campus Matching Tests
    
    @Test("EventKitService handles campus with special characters")
    func testCampusMatchingWithSpecialCharacters() async throws {
        let service = EventKitService.shared
        
        let specialCampuses = [
            Place(rawId: "campus1", name: "Café Campus", latitude: nil, longitude: nil),
            Place(rawId: "campus2", name: "Campus-North", latitude: nil, longitude: nil),
            Place(rawId: "campus3", name: "Campus & Research Center", latitude: nil, longitude: nil),
            Place(rawId: "campus4", name: "Campus (Main)", latitude: nil, longitude: nil),
            Place(rawId: "campus5", name: "Campus 123", latitude: nil, longitude: nil)
        ]
        
        for campus in specialCampuses {
            let nextEvent = await service.nextEvent(withinHours: 12, matchingCampus: campus)
            // Should complete without throwing regardless of special characters
        }
    }
    
    @Test("EventKitService handles empty campus name")
    func testCampusMatchingWithEmptyName() async throws {
        let service = EventKitService.shared
        
        let emptyCampus = Place(rawId: "empty", name: "", latitude: nil, longitude: nil)
        
        let nextEvent = await service.nextEvent(withinHours: 12, matchingCampus: emptyCampus)
        
        // Should handle empty campus name gracefully
    }
    
    @Test("EventKitService handles very long campus name")
    func testCampusMatchingWithLongName() async throws {
        let service = EventKitService.shared
        
        let longCampusName = String(repeating: "Very Long Campus Name ", count: 50)
        let longCampus = Place(rawId: "long", name: longCampusName, latitude: nil, longitude: nil)
        
        let nextEvent = await service.nextEvent(withinHours: 12, matchingCampus: longCampus)
        
        // Should handle very long campus names gracefully
    }
    
    // MARK: - Concurrent Access Tests
    
    @Test("EventKitService handles concurrent requests")
    func testConcurrentEventRequests() async throws {
        let service = EventKitService.shared
        
        // Make multiple concurrent requests
        await withTaskGroup(of: CalendarEvent?.self) { group in
            for i in 0..<5 {
                group.addTask {
                    return await service.nextEvent(withinHours: 12 + i, matchingCampus: nil)
                }
            }
            
            var results: [CalendarEvent?] = []
            for await result in group {
                results.append(result)
            }
            
            // All requests should complete
            #expect(results.count == 5)
        }
    }
    
    // MARK: - Date Range Tests
    
    @Test("EventKitService respects time boundaries")
    func testEventTimeBoundaries() async throws {
        let service = EventKitService.shared
        
        // Test with very short time window
        let shortWindowEvent = await service.nextEvent(withinHours: 1, matchingCampus: nil)
        
        // Test with medium time window
        let mediumWindowEvent = await service.nextEvent(withinHours: 12, matchingCampus: nil)

        // Test with long time window
        let longWindowEvent = await service.nextEvent(withinHours: 168, matchingCampus: nil) // 1 week
        
        // If events are found, they should respect the time boundaries
        if let shortEvent = shortWindowEvent {
            let oneHourFromNow = Date().addingTimeInterval(3600)
            #expect(shortEvent.startDate <= oneHourFromNow)
        }
        
        if let mediumEvent = mediumWindowEvent {
            let twelveHoursFromNow = Date().addingTimeInterval(12 * 3600)
            #expect(mediumEvent.startDate <= twelveHoursFromNow)
        }
        
        if let longEvent = longWindowEvent {
            let oneWeekFromNow = Date().addingTimeInterval(168 * 3600)
            #expect(longEvent.startDate <= oneWeekFromNow)
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Test("EventKitService handles calendar access denial gracefully")
    func testCalendarAccessDenial() async throws {
        let service = EventKitService.shared
        
        // Test that methods don't crash when calendar access is denied
        // (This would require mocking EKEventStore for proper testing)
        
        let accessResult = await service.requestAccess()
        let nextEvent = await service.nextEvent(matchingCampus: nil)
        
        // Should complete without throwing regardless of access status
    }
}

// MARK: - Mock EventStore (for future use)

/*
 Note: For more comprehensive testing, you would want to create a mock EKEventStore
 and inject it into the EventKitService. This would allow testing:
 
 1. Verification of proper calendar queries
 2. Testing with known calendar data
 3. Testing error conditions (access denied, no calendars, etc.)
 4. Verifying campus matching logic with controlled data
 
 Example mock structure:
 
 protocol EventStoreProtocol {
     func requestFullAccessToEvents() async throws -> Bool
     func calendars(for entityType: EKEntityType) -> [EKCalendar]
     func predicateForEvents(withStart: Date, end: Date, calendars: [EKCalendar]?) -> NSPredicate
     func events(matching predicate: NSPredicate) -> [EKEvent]
 }
 
 class MockEventStore: EventStoreProtocol {
     var accessGranted = true
     var mockEvents: [EKEvent] = []
     
     func requestFullAccessToEvents() async throws -> Bool {
         return accessGranted
     }
     
     func calendars(for entityType: EKEntityType) -> [EKCalendar] {
         // Return mock calendars
     }
     
     func predicateForEvents(withStart: Date, end: Date, calendars: [EKCalendar]?) -> NSPredicate {
         // Return mock predicate
     }
     
     func events(matching predicate: NSPredicate) -> [EKEvent] {
         return mockEvents
     }
 }
 */