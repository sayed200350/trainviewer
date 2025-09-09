# German Public Transport Departure App - MVP Specification

## Problem Statement
Students in Germany frequently use public transport and need to quickly check when to leave home to catch their next connection. Currently, this requires opening Google Maps, entering destinations, and navigating through multiple screens.

## Solution Overview
An iOS app with widgets that provides instant departure times for saved routes, eliminating the need to repeatedly enter the same journey details.

## Core Features (MVP)

### 1. Route Management
- **Add Favorite Routes**: Save frequently used routes (home → university, home → work, etc.)
- **Route Details**: Store start location, destination, and optional route name
- **Quick Edit**: Modify saved routes easily
- **Delete Routes**: Remove unused routes

### 2. Real-time Departure Information
- **Next Departures**: Show 2-3 next departure options for each saved route
- **Journey Time**: Display total travel time including connections
- **Departure Countdown**: Show "Leave in X minutes" instead of just departure times
- **Platform Information**: Include platform/track numbers when available
- **Delay Information**: Show real-time delays and disruptions

### 3. iOS Widgets
- **Small Widget**: Show next departure for one favorite route
- **Medium Widget**: Show next 2-3 departures for one route
- **Large Widget**: Show next departure for multiple favorite routes
- **Widget Configuration**: Let users choose which route to display in each widget

### 4. Smart Features
- **Location Detection**: Auto-detect when user is at home/saved locations
- **Walking Time Calculation**: Factor in walking time to the station
- **Preparation Buffer**: Add configurable buffer time (e.g., 2-5 minutes)
- **Smart Notifications**: Optional notifications for "time to leave" alerts

### 5. Semester Ticket Management
- **Digital Ticket Storage**: Store and display valid semester tickets
- **QR Code Generation**: Generate scannable codes for ticket validation
- **Multi-University Support**: Handle different university ticket formats
- **Validity Tracking**: Alert users before ticket expiration
- **Zone Integration**: Show transport zones covered by student ticket
- **Renewal Reminders**: Notifications for upcoming semester ticket renewal

## Technical Requirements

### Data Source
- **Primary**: Deutsche Bahn (DB) API or HAFAS API for German public transport
- **Fallback**: VBB (Berlin-Brandenburg) or MVV (Munich) regional APIs
- **Real-time Updates**: Ensure departure times are current and include delays

### iOS Integration
- **Widgets**: iOS 14+ WidgetKit support
- **Shortcuts**: Siri Shortcuts integration for voice queries
- **Background Refresh**: Keep widget data current
- **Location Services**: GPS for automatic location detection

### Core Technologies
- **Platform**: iOS 15+ (Swift/SwiftUI)
- **Data**: REST API integration with JSON parsing
- **Storage**: Core Data for route persistence
- **Networking**: URLSession with proper error handling

## User Interface (MVP)

### Home Screen (Map-Based)
- **Full-Screen Map**: Dark mode map showing user's current location
- **Nearby Stations**: Transit stops/stations displayed as pins with real-time info
- **Route Overlay**: Saved routes shown as colored lines on map
- **Quick Departure Card**: Sliding bottom panel showing next departures for saved routes
- **Location Button**: Center map on user's current position
- **Semester Ticket Button**: Floating action button to view ticket details

### Dark Mode Design Principles
- **Background**: Dark gray (#1C1C1E) with pure black (#000000) for OLED efficiency
- **Map Style**: Dark map theme with high contrast transit lines
- **Accent Colors**: 
  - Primary: Electric blue (#007AFF) for buttons and active states
  - Success: Green (#34C759) for "on time" status
  - Warning: Orange (#FF9500) for delays
  - Error: Red (#FF3B30) for disruptions
- **Typography**: SF Pro with high contrast white text on dark backgrounds
- **Cards**: Semi-transparent dark cards with subtle borders

### Add Route Screen
- Location picker with search functionality
- Recent locations and favorites
- Route naming option
- Save and test functionality

### Semester Ticket Integration
- **Digital Ticket Display**: Full-screen semester ticket with QR code
- **Validity Checker**: Show remaining days/months on current ticket
- **Zone Coverage**: Visual map showing covered transport zones
- **University Integration**: Connect with student portal for automatic renewal
- **Backup Storage**: Offline access when network is unavailable
- **Quick Access**: Swipe down from ticket button for instant display

### Bottom Sheet UI Components
- **Next Departures Panel**: Expandable sheet showing departure times
- **Route Quick Actions**: Add route, edit favorites, view full journey
- **Ticket Quick View**: Mini ticket card showing validity status
- **Settings Access**: Dark mode toggle, notifications, account settings

## Widget Specifications

### Small Widget (2x2)
```
[Route Name]
🚇 Leave in 8 min
Next: 12:45 → 13:22
[Last updated time]
```

### Medium Widget (4x2)
```
[Route Name]
🚇 Leave in 8 min  |  Next: Leave in 23 min
12:45 → 13:22     |  13:00 → 13:37
Platform 3        |  Platform 3
```

### Large Widget (4x4)
```
Home → University
🚇 Leave in 8 min
12:45 → 13:22, Platform 3

Home → Work
🚊 Leave in 15 min  
13:30 → 14:05, Platform 1

Dorm → City Center
🚌 Leave now
12:38 → 12:52
```

## MVP User Flow

1. **First Launch**: Welcome screen explaining the app's purpose
2. **Add First Route**: Simple onboarding to add home → university route
3. **Permission Requests**: Location access for auto-detection
4. **Widget Setup**: Guide user to add widget to home screen
5. **Daily Usage**: Quick glance at widget, tap for details if needed

## Success Metrics

### Primary KPIs
- **Widget Usage**: % of users who add and regularly use widgets
- **Route Saves**: Average number of routes saved per active user
- **Session Length**: Shorter sessions indicate successful quick access
- **Return Usage**: Daily/weekly active users

### Secondary Metrics
- App Store rating and reviews
- Feature usage (notifications, route sharing)
- Performance metrics (API response time, app launch time)

## Development Phases

### Phase 1 (Week 1-2): Core Functionality
- Basic route management (add, edit, delete)
- API integration for departure times
- Simple list view with real-time data

### Phase 2 (Week 3-4): Widget Implementation
- Small and medium widgets
- Widget configuration
- Background refresh setup

### Phase 3 (Week 5-6): Polish & Smart Features
- Large widget
- Walking time calculation
- Smart notifications
- Error handling and offline states

## Future Enhancements (Post-MVP)

### Advanced Features
- **Multi-city Support**: Support for all German cities
- **Bike Integration**: Include bike-sharing options in routes
- **Group Features**: Share routes with friends/classmates
- **Calendar Integration**: Smart departure times based on calendar events
- **Apple Watch**: Glanceable departure times on wrist
- **Accessibility**: VoiceOver support for visually impaired users

### Premium Features
- **Unlimited Routes**: Free version limited to 3-5 routes
- **Advanced Notifications**: Multiple notification types and timing
- **Route Optimization**: Suggest faster alternatives
- **Historical Data**: Track punctuality and suggest reliable departure times

## Technical Considerations

### API Rate Limits
- Implement proper caching to minimize API calls
- Use background refresh efficiently
- Handle API failures gracefully

### Battery Optimization
- Limit background location tracking
- Efficient widget refresh scheduling
- Minimize network requests

### Privacy
- Location data stored locally only
- Clear privacy policy
- Optional location sharing

## Success Definition

The MVP is successful if:
- Users add at least 2 favorite routes within first week
- 60%+ of users enable at least one widget
- Average session time under 30 seconds (indicating quick access success)
- 4+ star App Store rating
- 70%+ weekly retention after first month

This MVP focuses on solving the core problem simply and effectively, with clear paths for future enhancement based on user feedback and usage patterns.