# Implementation Plan

- [x] 1. Enhance Core Data Models and Route Management
  - Extend RouteEntity with new MVP properties (isWidgetEnabled, widgetPriority, colorRawValue, isFavorite, createdAt, lastUsed)
  - Update CoreDataStack to include new Route properties in the model
  - Implement RouteColor enum with SwiftUI Color support
  - Add Core Data migration logic for existing routes
  - Write unit tests for enhanced Route model and Core Data operations
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 2. Implement Semester Ticket Models and Secure Storage
  - Create SemesterTicket, University, and TransportZone model structs
  - Implement SemesterTicketStore using Keychain Services for secure storage
  - Add TicketFormat enum and QR code generation utilities
  - Create ticket validation logic (isValid, daysUntilExpiry)
  - Write unit tests for ticket models and Keychain storage operations
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8_

- [ ] 3. Create SemesterTicketViewModel and Ticket Management
  - Implement SemesterTicketViewModel with @Published properties for tickets and UI state
  - Add methods for loading, adding, and deleting tickets
  - Implement QR code generation using Core Image framework
  - Add ticket expiry reminder scheduling logic
  - Create unit tests for SemesterTicketViewModel business logic
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_

- [x] 4. Enhance Location Services with Proximity Detection
  - Extend LocationService with proximity detection for saved locations
  - Add methods for calculating walking time to destinations
  - Implement automatic location detection when user is near saved places
  - Add location permission handling with user-friendly messaging
  - Write unit tests for location calculations and proximity detection
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [x] 5. Create Map-Based Interface Components
  - Implement MapViewModel with MKCoordinateRegion and nearby stations
  - Create TransitStation model for displaying nearby transport stops
  - Add map region management and user location centering
  - Implement route overlay display on map with colored lines
  - Write unit tests for MapViewModel state management
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 6. Build Dark Mode Map View Interface
  - Create new MapView using SwiftUI Map with dark mode styling
  - Implement nearby station pins with real-time departure info
  - Add route overlay visualization with RouteColor support
  - Create sliding bottom sheet for departure information display
  - Implement location button for centering map on user position
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7_

- [ ] 7. Implement Enhanced Widget System Architecture
  - Create RouteWidgetConfiguration with AppIntent for widget setup
  - Implement WidgetSize enum for small/medium/large widget types
  - Add widget configuration UI for route selection and size preferences
  - Create widget timeline provider with background refresh logic
  - Write unit tests for widget configuration and timeline management
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [ ] 8. Build Small and Medium Widget Views
  - Create SmallWidgetView showing next departure for one route
  - Implement MediumWidgetView displaying 2-3 departures for one route
  - Add proper widget styling with dark mode support and specified colors
  - Implement relative time formatting and departure countdown display
  - Add widget deep-linking to route details in main app
  - _Requirements: 3.1, 3.2, 3.4, 3.6_

- [ ] 9. Create Large Widget and Multi-Route Display
  - Implement LargeWidgetView showing multiple favorite routes
  - Create RouteWidgetRow component for compact route display in large widget
  - Add route prioritization logic for widget display order
  - Implement widget refresh scheduling with background app refresh
  - Write widget UI tests for all three sizes
  - _Requirements: 3.3, 3.4, 3.5_

- [ ] 10. Enhance Notification System with Smart Alerts
  - Extend NotificationService with "time to leave" reminder scheduling
  - Implement ticket expiry reminder notifications
  - Add disruption alert notifications for route delays/cancellations
  - Create notification permission handling with clear user messaging
  - Write unit tests for notification scheduling and cancellation logic
  - _Requirements: 4.4, 5.6, 2.5_

- [ ] 11. Build Semester Ticket Display Interface
  - Create SemesterTicketView with full-screen ticket display
  - Implement QR code display with proper sizing and contrast
  - Add ticket validity status display with days remaining
  - Create ticket zone coverage visualization
  - Implement swipe-down quick access from floating action button
  - _Requirements: 5.1, 5.2, 5.3, 5.7, 5.8_

- [ ] 12. Create Add/Edit Semester Ticket Interface
  - Build AddSemesterTicketView with university selection and ticket input
  - Implement university picker with German universities database
  - Add ticket validation and QR code scanning functionality
  - Create ticket editing interface for updating expiry dates
  - Add form validation and error handling for ticket data
  - _Requirements: 5.1, 5.3, 5.4_

- [ ] 13. Integrate Map View into Main Interface
  - Replace existing MainView list interface with map-based design
  - Add floating semester ticket button with quick access
  - Implement bottom sheet with route departure information
  - Create smooth transitions between map and route detail views
  - Add route quick actions (add, edit, delete) accessible from map
  - _Requirements: 6.1, 6.2, 6.4, 6.5, 5.8_

- [ ] 14. Enhance Route Management with New Features
  - Add route color selection and favorite marking in AddRouteView
  - Implement widget enablement toggle for each route
  - Add route priority setting for widget display order
  - Create route usage tracking (lastUsed timestamp updates)
  - Update EditRouteView with new route properties
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 3.4_

- [ ] 15. Implement Smart Features and Calculations
  - Add walking time calculation integration in departure time display
  - Implement preparation buffer time configuration per route
  - Create smart "Leave in X minutes" countdown with buffer inclusion
  - Add automatic route suggestions based on location proximity
  - Write integration tests for smart timing calculations
  - _Requirements: 4.1, 4.2, 4.3, 2.2, 2.3_

- [ ] 16. Create User Onboarding Flow
  - Build welcome screen explaining app purpose and features
  - Implement guided first route setup (home → university)
  - Add location permission request with clear explanation
  - Create widget setup tutorial with step-by-step guidance
  - Add contextual help and tooltips throughout the app
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7_

- [ ] 17. Implement Error Handling and Offline Support
  - Create AppError enum with user-friendly error messages
  - Add graceful degradation when network is unavailable
  - Implement retry mechanisms for transient API failures
  - Create offline indicator UI with cached data timestamps
  - Add comprehensive error logging for debugging
  - _Requirements: 2.7, 7.4, 7.5, 7.6_

- [ ] 18. Add Performance Optimizations
  - Implement intelligent API request caching with appropriate TTL
  - Add request batching for multiple route updates
  - Optimize widget background refresh scheduling
  - Implement memory management for map tiles and images
  - Add battery optimization for location updates
  - _Requirements: 7.1, 7.2, 7.3, 7.6, 7.7_

- [ ] 19. Implement Accessibility and Internationalization
  - Add VoiceOver labels and accessibility hints to all UI elements
  - Implement Dynamic Type support for larger text sizes
  - Add German localization for all user-facing strings
  - Create high contrast mode support with proper color ratios
  - Test and fix accessibility navigation and focus order
  - _Requirements: 6.7, 8.6_

- [ ] 20. Final Integration and Testing
  - Integrate all components into cohesive app experience
  - Perform end-to-end testing of complete user workflows
  - Test widget functionality across all sizes and configurations
  - Validate semester ticket storage and QR code generation
  - Conduct performance testing and memory leak detection
  - _Requirements: All requirements integration testing_