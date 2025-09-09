# Design Document

## Overview

This design document outlines the architecture and implementation approach for completing the German Public Transport Departure App MVP. The app builds upon the existing TrainViewer foundation, transforming it into a comprehensive solution that provides students with instant access to departure times through an iOS app with widgets and semester ticket management.

The design leverages the existing SwiftUI architecture, Core Data persistence, and transport API integration while adding new features like map-based interface, enhanced widgets, and semester ticket functionality.

## Architecture

### High-Level Architecture

The app follows an MVVM (Model-View-ViewModel) architecture with the following layers:

```
┌─────────────────────────────────────────────────────────────┐
│                        Views Layer                          │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │   Map-based     │ │     Widget      │ │    Settings     ││
│  │   Main View     │ │     Views       │ │     Views       ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                     ViewModels Layer                        │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │   Routes        │ │    Semester     │ │   Location      ││
│  │   ViewModel     │ │ Ticket ViewModel│ │   ViewModel     ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                      Services Layer                         │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │   Transport     │ │    Location     │ │  Notification   ││
│  │     APIs        │ │    Service      │ │    Service      ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                            │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │   Core Data     │ │   Keychain      │ │   UserDefaults  ││
│  │   (Routes)      │ │  (Tickets)      │ │   (Settings)    ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Key Architectural Decisions

1. **Extend Existing Foundation**: Build upon the current TrainViewer architecture rather than rewriting
2. **Map-First Interface**: Transform the list-based UI to a map-centric experience
3. **Enhanced Widget System**: Expand the current widget implementation with multiple sizes and configurations
4. **Secure Ticket Storage**: Use Keychain for semester ticket data security
5. **Modular Services**: Maintain separation of concerns with dedicated service classes

## Components and Interfaces

### 1. Enhanced Models

#### Route Model (Extended)
```swift
struct Route: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var origin: Place
    var destination: Place
    var preparationBufferMinutes: Int
    var walkingSpeedMetersPerSecond: Double
    
    // New MVP features
    var isWidgetEnabled: Bool
    var widgetPriority: Int
    var color: RouteColor
    var isFavorite: Bool
    
    init(id: UUID = UUID(), name: String, origin: Place, destination: Place, 
         preparationBufferMinutes: Int = AppConstants.defaultPreparationBufferMinutes, 
         walkingSpeedMetersPerSecond: Double = AppConstants.defaultWalkingSpeedMetersPerSecond,
         isWidgetEnabled: Bool = false, widgetPriority: Int = 0, 
         color: RouteColor = .blue, isFavorite: Bool = false)
}

enum RouteColor: String, CaseIterable, Codable {
    case blue, green, orange, red, purple, pink
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .purple: return .purple
        case .pink: return .pink
        }
    }
}
```

#### Semester Ticket Model (New)
```swift
struct SemesterTicket: Identifiable, Codable {
    let id: UUID
    let studentId: String
    let university: University
    let validFrom: Date
    let validUntil: Date
    let ticketNumber: String
    let qrCodeData: String
    let zones: [TransportZone]
    let studentName: String
    let semester: String
    
    var isValid: Bool {
        let now = Date()
        return now >= validFrom && now <= validUntil
    }
    
    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: validUntil).day ?? 0
    }
}

struct University: Codable, Hashable {
    let id: String
    let name: String
    let shortName: String
    let ticketFormat: TicketFormat
    let supportedZones: [TransportZone]
}

struct TransportZone: Codable, Hashable {
    let id: String
    let name: String
    let region: String
    let boundary: [CLLocationCoordinate2D]
}

enum TicketFormat: String, Codable {
    case qrCode, barcode, nfc
}
```

### 2. Enhanced ViewModels

#### MapViewModel (New)
```swift
@MainActor
final class MapViewModel: ObservableObject {
    @Published var region: MKCoordinateRegion
    @Published var nearbyStations: [TransitStation] = []
    @Published var selectedRoute: Route?
    @Published var showingRouteOverlay: Bool = false
    @Published var userLocation: CLLocation?
    
    private let locationService: LocationService
    private let transportAPI: TransportAPI
    
    func loadNearbyStations()
    func selectRoute(_ route: Route)
    func centerOnUserLocation()
    func updateRouteOverlay()
}

struct TransitStation: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let type: StationType
    let nextDepartures: [JourneyOption]
}

enum StationType {
    case train, bus, tram, subway
}
```

#### SemesterTicketViewModel (New)
```swift
@MainActor
final class SemesterTicketViewModel: ObservableObject {
    @Published var tickets: [SemesterTicket] = []
    @Published var activeTicket: SemesterTicket?
    @Published var showingTicketDetail: Bool = false
    @Published var showingAddTicket: Bool = false
    
    private let ticketStore: SemesterTicketStore
    private let notificationService: NotificationService
    
    func loadTickets()
    func addTicket(_ ticket: SemesterTicket)
    func deleteTicket(_ ticketId: UUID)
    func scheduleExpiryReminders()
    func generateQRCode(for ticket: SemesterTicket) -> UIImage?
}
```

### 3. Enhanced Services

#### Enhanced LocationService
```swift
final class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isNearSavedLocation: Bool = false
    @Published var nearestSavedLocation: Place?
    
    private let locationManager = CLLocationManager()
    private let routeStore: RouteStore
    
    func requestPermission()
    func startLocationUpdates()
    func stopLocationUpdates()
    func checkProximityToSavedLocations()
    func calculateWalkingTime(to destination: CLLocation) -> TimeInterval
}
```

#### SemesterTicketStore (New)
```swift
final class SemesterTicketStore {
    private let keychain = Keychain(service: "com.trainviewer.tickets")
    
    func save(_ ticket: SemesterTicket) throws
    func fetchAll() -> [SemesterTicket]
    func delete(ticketId: UUID) throws
    func fetchActive() -> SemesterTicket?
}
```

#### Enhanced NotificationService
```swift
final class NotificationService {
    static let shared = NotificationService()
    
    func requestPermission() async -> Bool
    func scheduleLeaveReminder(for route: Route, leaveAt: Date)
    func scheduleTicketExpiryReminder(for ticket: SemesterTicket)
    func cancelAllReminders(for routeId: UUID)
    func scheduleDisruptionAlert(for route: Route, message: String)
}
```

### 4. Widget Architecture

#### Widget Configuration
```swift
struct RouteWidgetConfiguration: AppIntent {
    static var title: LocalizedStringResource = "Select Route"
    
    @Parameter(title: "Route")
    var route: RouteEntity
    
    @Parameter(title: "Widget Size")
    var size: WidgetSize
}

enum WidgetSize: String, CaseIterable, AppEnum {
    case small, medium, large
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Widget Size"
    }
    
    static var caseDisplayRepresentations: [WidgetSize: DisplayRepresentation] {
        [
            .small: "Small (Next Departure)",
            .medium: "Medium (Multiple Departures)",
            .large: "Large (Multiple Routes)"
        ]
    }
}
```

#### Widget Views
```swift
struct SmallWidgetView: View {
    let route: Route
    let status: RouteStatus?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(route.name)
                .font(.caption)
                .fontWeight(.medium)
            
            if let leaveIn = status?.leaveInMinutes {
                Text("Leave in \(leaveIn) min")
                    .font(.headline)
                    .foregroundColor(leaveIn <= 2 ? .red : .primary)
            }
            
            if let option = status?.options.first {
                Text("\(formattedTime(option.departure)) → \(formattedTime(option.arrival))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Updated \(relativeTime(status?.lastUpdated))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct MediumWidgetView: View {
    let route: Route
    let status: RouteStatus?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(route.name)
                    .font(.headline)
                
                if let options = status?.options.prefix(2) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                        DepartureRow(option: option, isNext: index == 0)
                    }
                }
            }
            
            Spacer()
            
            VStack {
                if let leaveIn = status?.leaveInMinutes {
                    Text("\(leaveIn)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("min")
                        .font(.caption)
                }
            }
        }
        .padding()
    }
}

struct LargeWidgetView: View {
    let routes: [Route]
    let statusByRouteId: [UUID: RouteStatus]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(routes.prefix(3)) { route in
                RouteWidgetRow(route: route, status: statusByRouteId[route.id])
                if route.id != routes.prefix(3).last?.id {
                    Divider()
                }
            }
        }
        .padding()
    }
}
```

## Data Models

### Core Data Schema Extensions

#### Enhanced RouteEntity
```swift
@objc(RouteEntity)
final class RouteEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var originId: String?
    @NSManaged var originName: String
    @NSManaged var originLat: NSNumber?
    @NSManaged var originLon: NSNumber?
    @NSManaged var destId: String?
    @NSManaged var destName: String
    @NSManaged var destLat: NSNumber?
    @NSManaged var destLon: NSNumber?
    @NSManaged var preparationBufferMinutes: Int16
    @NSManaged var walkingSpeedMetersPerSecond: Double
    
    // New MVP properties
    @NSManaged var isWidgetEnabled: Bool
    @NSManaged var widgetPriority: Int16
    @NSManaged var colorRawValue: String
    @NSManaged var isFavorite: Bool
    @NSManaged var createdAt: Date
    @NSManaged var lastUsed: Date
}
```

### Keychain Storage Schema

#### Semester Ticket Storage
```swift
struct TicketKeychainItem {
    let ticketId: String
    let encryptedData: Data
    let university: String
    let validUntil: Date
}
```

## Error Handling

### Error Types
```swift
enum AppError: LocalizedError {
    case networkUnavailable
    case apiRateLimitExceeded
    case invalidTicketData
    case locationPermissionDenied
    case coreDataError(Error)
    case keychainError(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network connection unavailable. Showing cached data."
        case .apiRateLimitExceeded:
            return "Too many requests. Please try again later."
        case .invalidTicketData:
            return "Invalid ticket data. Please check your ticket information."
        case .locationPermissionDenied:
            return "Location access required for automatic route detection."
        case .coreDataError(let error):
            return "Data storage error: \(error.localizedDescription)"
        case .keychainError(let status):
            return "Secure storage error: \(status)"
        }
    }
}
```

### Error Handling Strategy
1. **Graceful Degradation**: Show cached data when network fails
2. **User-Friendly Messages**: Clear, actionable error messages
3. **Retry Mechanisms**: Automatic retry for transient failures
4. **Offline Support**: Full functionality with cached data
5. **Error Logging**: Comprehensive logging for debugging

## Testing Strategy

### Unit Testing
- **ViewModels**: Test business logic and state management
- **Services**: Test API integration and data persistence
- **Models**: Test data validation and transformations
- **Utilities**: Test helper functions and extensions

### Integration Testing
- **API Integration**: Test real API responses and error handling
- **Core Data**: Test data persistence and migration
- **Keychain**: Test secure storage operations
- **Location Services**: Test location detection and calculations

### UI Testing
- **Navigation Flows**: Test complete user journeys
- **Widget Functionality**: Test widget configuration and updates
- **Accessibility**: Test VoiceOver and accessibility features
- **Dark Mode**: Test UI in both light and dark modes

### Widget Testing
- **Timeline Updates**: Test widget refresh mechanisms
- **Configuration**: Test widget setup and customization
- **Background Refresh**: Test data updates in background
- **Performance**: Test widget load times and memory usage

## Performance Considerations

### API Optimization
- **Request Batching**: Combine multiple route requests
- **Intelligent Caching**: Cache responses with appropriate TTL
- **Background Refresh**: Update data efficiently in background
- **Rate Limiting**: Respect API limits with exponential backoff

### Memory Management
- **Image Caching**: Efficient caching for map tiles and icons
- **Data Pagination**: Load large datasets incrementally
- **Memory Warnings**: Handle low memory situations gracefully
- **Widget Memory**: Minimize widget memory footprint

### Battery Optimization
- **Location Updates**: Use significant location changes only
- **Background Tasks**: Minimize background processing
- **Network Efficiency**: Batch network requests
- **Display Updates**: Optimize animation and refresh rates

## Security Considerations

### Data Protection
- **Keychain Storage**: Store sensitive ticket data in Keychain
- **Data Encryption**: Encrypt ticket QR codes and personal data
- **Biometric Authentication**: Optional Face ID/Touch ID for ticket access
- **Network Security**: Use certificate pinning for API calls

### Privacy Protection
- **Location Data**: Store location data locally only
- **Analytics**: Anonymize any usage analytics
- **Data Minimization**: Collect only necessary data
- **User Consent**: Clear consent for location and notification permissions

## Accessibility

### VoiceOver Support
- **Semantic Labels**: Proper accessibility labels for all UI elements
- **Navigation**: Logical focus order and navigation
- **Announcements**: Dynamic content announcements
- **Gestures**: Support for accessibility gestures

### Visual Accessibility
- **Dynamic Type**: Support for larger text sizes
- **High Contrast**: Ensure sufficient color contrast
- **Reduce Motion**: Respect motion reduction preferences
- **Color Independence**: Don't rely solely on color for information

## Internationalization

### Localization Support
- **German Primary**: German as primary language
- **English Secondary**: English as fallback language
- **Date/Time Formats**: Locale-appropriate formatting
- **Number Formats**: Regional number and currency formatting

### Cultural Considerations
- **Transport Terminology**: Use local transport terms
- **University Systems**: Support German university structures
- **Regional Variations**: Account for regional transport differences