import Testing
import CoreLocation
import SwiftUI
@testable import TrainViewer

struct CompilationTest {

    @Test("Test mock class instantiation")
    func testMockClasses() async throws {
        // Test MockUserSettingsStore instantiation
        let mockSettings = TestMockUserSettingsStore()
        #expect(mockSettings.smartWidgetEnabled == true)

        // Test MockSharedStore instantiation
        let mockShared = TestMockSharedStore()
        #expect(mockShared.currentLocation == nil)

        // Test WidgetRoute creation
        let origin = WidgetPlace(rawId: "test", name: "Test Origin", latitude: 48.1351, longitude: 11.5820)
        let destination = WidgetPlace(rawId: "test2", name: "Test Destination", latitude: 48.1500, longitude: 11.5800)
        let widgetRoute = WidgetRoute(id: UUID(), name: "Test Route", origin: origin, destination: destination)
        #expect(widgetRoute.name == "Test Route")

        // Test Place creation
        let place = Place(rawId: "test", name: "Test Place", latitude: 48.1351, longitude: 11.5820)
        #expect(place.name == "Test Place")

        print("✅ All mock classes compile successfully!")
    }
}
