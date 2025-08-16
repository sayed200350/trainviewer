# Requirements Document

## Introduction

This document outlines the requirements for completing the German Public Transport Departure App MVP. The app aims to provide students in Germany with instant access to departure times for their frequently used routes through an iOS app with widgets, eliminating the need to repeatedly enter journey details in other apps like Google Maps.

The app should integrate seamlessly with existing German public transport APIs, provide real-time departure information, and offer convenient iOS widgets for quick access. Additionally, it should include semester ticket management functionality for German students.

## Requirements

### Requirement 1: Route Management System

**User Story:** As a student, I want to save my frequently used routes (home → university, dorm → work), so that I can quickly access departure times without re-entering destinations.

#### Acceptance Criteria

1. WHEN a user opens the app THEN the system SHALL display a map-based interface with options to add routes
2. WHEN a user selects "Add Route" THEN the system SHALL provide location picker with search functionality
3. WHEN a user enters start and destination locations THEN the system SHALL validate the locations using transport API
4. WHEN a user saves a route THEN the system SHALL store it locally using Core Data with optional custom name
5. WHEN a user views saved routes THEN the system SHALL display all routes with edit and delete options
6. IF a user has no saved routes THEN the system SHALL show onboarding to add their first route

### Requirement 2: Real-time Departure Information

**User Story:** As a commuter, I want to see real-time departure information including delays and platform details, so that I can make informed decisions about when to leave.

#### Acceptance Criteria

1. WHEN a user views a saved route THEN the system SHALL display next 2-3 departure options with real-time data
2. WHEN departure data is available THEN the system SHALL show total journey time including connections
3. WHEN displaying departures THEN the system SHALL show "Leave in X minutes" countdown instead of just departure times
4. WHEN platform information is available THEN the system SHALL include platform/track numbers
5. WHEN delays occur THEN the system SHALL display real-time delay information and disruptions
6. WHEN walking time is configured THEN the system SHALL factor walking time to station in departure calculations
7. IF API is unavailable THEN the system SHALL display cached data with appropriate offline indicator

### Requirement 3: iOS Widget Integration

**User Story:** As a busy student, I want to see departure times directly on my home screen through widgets, so that I can check times without opening the app.

#### Acceptance Criteria

1. WHEN a user adds a small widget THEN the system SHALL display next departure for one selected route
2. WHEN a user adds a medium widget THEN the system SHALL show next 2-3 departures for one route
3. WHEN a user adds a large widget THEN the system SHALL display next departure for multiple favorite routes
4. WHEN configuring widgets THEN the system SHALL allow users to choose which route to display
5. WHEN widget data becomes stale THEN the system SHALL refresh using background app refresh
6. WHEN tapped THEN widgets SHALL deep-link to relevant route details in the app
7. IF no internet connection THEN widgets SHALL display last known data with timestamp

### Requirement 4: Smart Location and Timing Features

**User Story:** As a user, I want the app to automatically detect my location and calculate optimal departure times, so that I don't miss my connections.

#### Acceptance Criteria

1. WHEN location permission is granted THEN the system SHALL auto-detect when user is at saved locations
2. WHEN calculating departure times THEN the system SHALL include walking time to the station
3. WHEN user configures buffer time THEN the system SHALL add configurable preparation time (2-5 minutes)
4. WHEN smart notifications are enabled THEN the system SHALL send "time to leave" alerts
5. WHEN user is near a station THEN the system SHALL show nearby stations on map with real-time info
6. IF location services are disabled THEN the system SHALL gracefully degrade to manual location selection

### Requirement 5: Semester Ticket Management

**User Story:** As a German student, I want to store and display my semester ticket digitally, so that I can easily show it during ticket inspections and track its validity.

#### Acceptance Criteria

1. WHEN a user adds a semester ticket THEN the system SHALL store ticket details securely locally
2. WHEN displaying the ticket THEN the system SHALL show a full-screen view with QR code
3. WHEN ticket is displayed THEN the system SHALL generate scannable codes for validation
4. WHEN multiple universities are supported THEN the system SHALL handle different ticket formats
5. WHEN ticket validity is checked THEN the system SHALL show remaining days/months
6. WHEN ticket is near expiration THEN the system SHALL send renewal reminder notifications
7. WHEN viewing zones THEN the system SHALL display transport zones covered by student ticket
8. IF network is unavailable THEN the system SHALL provide offline access to stored tickets

### Requirement 6: Dark Mode Map Interface

**User Story:** As a user, I want a dark mode map-based interface that's easy on the eyes and shows transit information clearly, so that I can use the app comfortably in various lighting conditions.

#### Acceptance Criteria

1. WHEN the app launches THEN the system SHALL display a full-screen dark mode map
2. WHEN showing user location THEN the system SHALL center map on current position with location button
3. WHEN displaying transit stops THEN the system SHALL show stations as pins with real-time info
4. WHEN showing saved routes THEN the system SHALL display routes as colored lines on map
5. WHEN using bottom sheet THEN the system SHALL show sliding panel with departure information
6. WHEN in dark mode THEN the system SHALL use specified color scheme (dark gray #1C1C1E background, electric blue #007AFF accents)
7. WHEN showing status information THEN the system SHALL use color coding (green for on-time, orange for delays, red for disruptions)

### Requirement 7: API Integration and Performance

**User Story:** As a user, I want fast and reliable departure information from German public transport systems, so that I can trust the app for my daily commute.

#### Acceptance Criteria

1. WHEN fetching departure data THEN the system SHALL use Deutsche Bahn (DB) API or HAFAS API as primary source
2. WHEN primary API fails THEN the system SHALL fallback to regional APIs (VBB, MVV)
3. WHEN making API calls THEN the system SHALL implement proper caching to minimize requests
4. WHEN API rate limits are reached THEN the system SHALL handle gracefully with cached data
5. WHEN network errors occur THEN the system SHALL display appropriate error messages
6. WHEN background refresh occurs THEN the system SHALL update widget data efficiently
7. IF API response time exceeds 5 seconds THEN the system SHALL show loading indicator and timeout handling

### Requirement 8: User Onboarding and Experience

**User Story:** As a new user, I want clear guidance on how to set up and use the app effectively, so that I can quickly start benefiting from its features.

#### Acceptance Criteria

1. WHEN launching for the first time THEN the system SHALL show welcome screen explaining app purpose
2. WHEN onboarding starts THEN the system SHALL guide user to add their first route (home → university)
3. WHEN permissions are needed THEN the system SHALL request location access with clear explanation
4. WHEN onboarding continues THEN the system SHALL guide user to add widget to home screen
5. WHEN user completes setup THEN the system SHALL show confirmation and usage tips
6. WHEN user needs help THEN the system SHALL provide contextual help and tooltips
7. IF user skips onboarding THEN the system SHALL allow access to main features with optional tutorial later