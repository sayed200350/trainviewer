# TrainViewer iOS App

A SwiftUI iOS app that shows real-time German public transport departures for your saved routes, with optional widgets and notifications.

## Requirements
- Xcode 15+
- iOS 15+ deployment target
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
- WidgetKit extension skeleton for small/medium widgets

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
7. Add a Widget Extension target (File → New → Target → Widget Extension) if not already added and include files from `ios/TrainViewer/Widgets`.
8. Build & Run on a device or simulator with network access.

## Build
- Select the TrainViewer app scheme → Run
- For the widget, run the TrainViewerWidget scheme to preview widgets; the widget reads from App Group store populated after the app performs a refresh.

## Notes
- Core Data model is created programmatically; no `.xcdatamodeld` file required.
- For per-widget route selection, add an Intent Definition file or AppIntents (iOS 16+).
- If DB provider throttles, fallback provider can be used by switching `TransportProvider` to `.vbb` in `DBTransportAPI`.

## Troubleshooting
- If you see decoding errors, check network logs in `Services/APIClient.swift` and inspect the JSON.
- If widgets don’t refresh, open the app once and pull-to-refresh; the widget timeline updates every ~10 minutes by default.
- Location permission can be denied; walking time will default to 0.