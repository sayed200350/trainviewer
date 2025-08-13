# TrainViewer iOS App

A SwiftUI iOS app that shows real-time German public transport departures for your saved routes, with optional widgets, Siri, and notifications.

## Requirements
- Xcode 15+
- iOS 15+ deployment target (AppIntents-based widget/Siri require iOS 16+)
- Swift Concurrency enabled (Swift 5.7+)
- Internet connection

## Data Source
Uses public `transport.rest` endpoints:
- Primary: `https://v6.db.transport.rest`
- Fallback: `https://v5.vbb.transport.rest`

No API key required. See `Shared/Constants.swift` to change providers.

## Features
- Save favorite routes (origin → destination)
- Real-time next departure options
- "Leave in X min" with walking time + buffer
- Pull to refresh
- Add/edit/delete routes
- Optional local notifications
- Widgets: static + per-widget route selection via AppIntents (iOS 16+)
- Siri Quick Actions: "Next to campus" and "Next home" intents
- Settings: ticket type, provider preference, exam/energy/night modes, campus and home places, student verification
- Class schedule sync: imports calendar events; shows Next Class card and computes leave time to campus
- Offline cache for departures; used when network fails

## Setup Steps (Xcode)
1. Create a new Xcode project:
   - iOS App → SwiftUI → Product Name: TrainViewer
   - Team: your Apple Developer team
   - Organization Identifier: e.g. `com.yourcompany`
   - Language: Swift, Interface: SwiftUI, Lifecycle: SwiftUI App
   - iOS 15 deployment target
2. In the Project Navigator, add the `ios/TrainViewer` folder (Create groups).
3. Capabilities (Targets → TrainViewer → Signing & Capabilities):
   - Background Modes: Background fetch
   - Location Updates (optional if you want significant-change updates)
   - Push Notifications: not required (we use local notifications)
   - App Groups: add one, e.g. `group.com.yourcompany.trainviewer`
4. Capabilities (Targets → TrainViewerWidget → Signing & Capabilities):
   - App Groups: enable the same group `group.com.yourcompany.trainviewer`
   - Widgets don’t need Location or Notifications
5. Update `Shared/Constants.swift` with your App Group identifier.
6. Info.plist keys (Targets → TrainViewer → Info):
   - `NSLocationWhenInUseUsageDescription` → "Used to estimate walking time to your station"
   - `NSLocationAlwaysAndWhenInUseUsageDescription` → "Used to estimate walking time to your station"
   - `NSCalendarsUsageDescription` → "Used to detect upcoming classes on your calendar"
7. Add a Widget Extension target (File → New → Target → Widget Extension) if not already added and include files from `ios/TrainViewer/Widgets`.
8. Build & Run on a device or simulator with network access.

## Siri Quick Actions (iOS 16+)
- Intents: `NextToCampusIntent`, `NextHomeIntent` in `AppIntents/QuickActionsIntents.swift`
- After first run, set Campus and Home in Settings and grant location permission
- Invoke via Siri: "Next to campus" or "Next home"

## Widgets
- Static widget: `TrainViewerWidget` shows snapshot from the first route
- AppIntents widget: `TrainViewerRouteWidget` lets you choose a specific route per widget instance

## Apple Watch (Optional)
1. Add a watchOS App target (File → New → Target → Watch App for iOS App)
2. Enable the same App Group in the WatchKit Extension
3. Add files from `ios/TrainViewerWatch` to the WatchKit Extension target
4. Build & run on a Watch simulator

## Build
- Select the TrainViewer app scheme → Run
- For widgets, run widget schemes to preview; ensure the app has been opened at least once to populate App Group data.

## Troubleshooting
- If you see decoding errors, check network logs in `Services/APIClient.swift` and inspect the JSON.
- If widgets or Siri don’t have data, open the app once and pull-to-refresh to populate App Group storage.
- Location permission can be denied; walking time will default to 0.
- Calendar permission can be denied; Next Class card will not appear.