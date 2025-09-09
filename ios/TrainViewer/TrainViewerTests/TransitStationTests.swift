import Testing
import CoreLocation
@testable import TrainViewer

struct TransitStationTests {
    
    @Test("TransitStation initializes with all properties correctly")
    func testTransitStationInitialization() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 52.5170, longitude: 13.3888)
        let departures = [createTestJourneyOption()]
        
        let station = TransitStation(
            id: "test-station-1",
            name: "Test Station",
            coordinate: coordinate,
            type: .train,
            nextDepartures: departures,
            distance: 150.0
        )
        
        #expect(station.id == "test-station-1")
        #expect(station.name == "Test Station")
        #expect(abs(station.coordinate.latitude - coordinate.latitude) < 0.001)
        #expect(abs(station.coordinate.longitude - coordinate.longitude) < 0.001)
        #expect(station.type == .train)
        #expect(station.nextDepartures.count == 1)
        #expect(station.distance == 150.0)
    }
    
    @Test("TransitStation initializes with default values correctly")
    func testTransitStationDefaultValues() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 52.5170, longitude: 13.3888)
        
        let station = TransitStation(
            id: "test-station-2",
            name: "Test Station 2",
            coordinate: coordinate,
            type: .bus
        )
        
        #expect(station.nextDepartures.isEmpty)
        #expect(station.distance == nil)
    }
    
    @Test("StationType display names are correct")
    func testStationTypeDisplayNames() async throws {
        #expect(StationType.train.displayName == "Train")
        #expect(StationType.bus.displayName == "Bus")
        #expect(StationType.tram.displayName == "Tram")
        #expect(StationType.subway.displayName == "Subway")
        #expect(StationType.ferry.displayName == "Ferry")
    }
    
    @Test("StationType icon names are correct")
    func testStationTypeIconNames() async throws {
        #expect(StationType.train.iconName == "train.side.front.car")
        #expect(StationType.bus.iconName == "bus")
        #expect(StationType.tram.iconName == "tram")
        #expect(StationType.subway.iconName == "train.side.middle.car")
        #expect(StationType.ferry.iconName == "ferry")
    }
    
    @Test("StationType raw values are correct")
    func testStationTypeRawValues() async throws {
        #expect(StationType.train.rawValue == "train")
        #expect(StationType.bus.rawValue == "bus")
        #expect(StationType.tram.rawValue == "tram")
        #expect(StationType.subway.rawValue == "subway")
        #expect(StationType.ferry.rawValue == "ferry")
    }
    
    @Test("StationType contains all expected cases")
    func testStationTypeCaseIterable() async throws {
        let allTypes = StationType.allCases
        #expect(allTypes.count == 5)
        #expect(allTypes.contains(.train))
        #expect(allTypes.contains(.bus))
        #expect(allTypes.contains(.tram))
        #expect(allTypes.contains(.subway))
        #expect(allTypes.contains(.ferry))
    }
    
    @Test("CLLocationCoordinate2D is properly Codable")
    func testCLLocationCoordinate2DCodable() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 52.5170, longitude: 13.3888)
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(coordinate)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedCoordinate = try decoder.decode(CLLocationCoordinate2D.self, from: data)
        
        #expect(abs(coordinate.latitude - decodedCoordinate.latitude) < 0.001)
        #expect(abs(coordinate.longitude - decodedCoordinate.longitude) < 0.001)
    }
    
    @Test("CLLocationCoordinate2D is properly Hashable")
    func testCLLocationCoordinate2DHashable() async throws {
        let coordinate1 = CLLocationCoordinate2D(latitude: 52.5170, longitude: 13.3888)
        let coordinate2 = CLLocationCoordinate2D(latitude: 52.5170, longitude: 13.3888)
        let coordinate3 = CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050)
        
        #expect(coordinate1 == coordinate2)
        #expect(coordinate1 != coordinate3)
        
        // Test in Set (requires Hashable)
        let coordinateSet: Set<CLLocationCoordinate2D> = [coordinate1, coordinate2, coordinate3]
        #expect(coordinateSet.count == 2) // coordinate1 and coordinate2 should be treated as same
    }
    
    @Test("TransitStation is properly Codable")
    func testTransitStationCodable() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 52.5170, longitude: 13.3888)
        let departures = [createTestJourneyOption()]
        
        let originalStation = TransitStation(
            id: "test-station-codable",
            name: "Codable Test Station",
            coordinate: coordinate,
            type: .train,
            nextDepartures: departures,
            distance: 200.0
        )
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalStation)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedStation = try decoder.decode(TransitStation.self, from: data)
        
        #expect(originalStation.id == decodedStation.id)
        #expect(originalStation.name == decodedStation.name)
        #expect(abs(originalStation.coordinate.latitude - decodedStation.coordinate.latitude) < 0.001)
        #expect(abs(originalStation.coordinate.longitude - decodedStation.coordinate.longitude) < 0.001)
        #expect(originalStation.type == decodedStation.type)
        #expect(originalStation.nextDepartures.count == decodedStation.nextDepartures.count)
        #expect(originalStation.distance == decodedStation.distance)
    }
    
    @Test("TransitStation is properly Hashable")
    func testTransitStationHashable() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 52.5170, longitude: 13.3888)
        
        let station1 = TransitStation(
            id: "station-1",
            name: "Station 1",
            coordinate: coordinate,
            type: .train
        )
        
        let station2 = TransitStation(
            id: "station-1", // Same ID
            name: "Station 1 Updated", // Different name
            coordinate: coordinate,
            type: .bus // Different type
        )
        
        let station3 = TransitStation(
            id: "station-2", // Different ID
            name: "Station 1",
            coordinate: coordinate,
            type: .train
        )
        
        // Stations with same ID should be equal (assuming ID is the primary identifier)
        #expect(station1.id == station2.id)
        #expect(station1.id != station3.id)
        
        // Test in Set
        let stationSet: Set<TransitStation> = [station1, station2, station3]
        #expect(stationSet.count == 2) // station1 and station2 have same ID, so should be treated as same
    }
    
    // MARK: - Helper Methods
    
    private func createTestJourneyOption() -> JourneyOption {
        return JourneyOption(
            departure: Date(),
            arrival: Date().addingTimeInterval(1800), // 30 minutes later
            lineName: "S1",
            platform: "1",
            delayMinutes: 0,
            totalMinutes: 30,
            warnings: nil
        )
    }
}