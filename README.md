# TrainViewer

An iOS app built with SwiftUI that shows upcoming train departures for saved routes and nearby stations. Includes a widget extension for quick glanceable departures.

## Highlights
- SwiftUI app target and a Widget extension
- Core Data for persistence (`TransportModel.xcdatamodeld` with `RouteEntity`)
- Location + smart features:
  - Auto-detect user location for walking-time estimate
  - Preparation buffer before departure (configurable)
  - Disruption detection + optional notifications
- Widget (small/medium):
  - Small: `[emoji] Leave in X min` and `Next: HH:MM`
  - Medium: route name, next window, and larger leave-in display
- Transit API integration using transport.rest v6 (journeys), with robust time parsing

## Requirements
- Xcode 15.4 or newer (Xcode 16 recommended)
- iOS 17+ (project settings include iOS 17.6 and newer)
- An Apple Developer Team set in Signing settings

## Open and Run
1. Clone the repo.
2. Recommended: open the project at `TrainViewer/TrainViewer.xcodeproj`.
   - There is also a project under `ios/TrainViewer/TrainViewer.xcodeproj` used for the app + widget setup. If one project fails to open, try the other.
3. In Xcode, select the `TrainViewer` scheme and a simulator or device.
4. Update Signing:
   - Set your Team in Signing & Capabilities for all targets.
   - Adjust bundle identifiers as needed (e.g., `com.trainviewer.app`).
5. Build and run.

## Targets & Schemes
- TrainViewer (iOS app)
- Widget Extension (Next Departure / TrainViewerWidgetExtension)

## Folder Structure
```
ios/TrainViewer/
  Sources/
    NextDepartureWidget/
      NextDepartureWidget.swift
    TrainViewer/
      App.swift
      ContentView.swift
      Location/
        LocationManager.swift
      Model/
        PersistenceController.swift
        RouteEntity.swift
        SharedCache.swift
        TransportModel.xcdatamodeld/
      Networking/
        TransitAPI.swift
      Views/
        AddRouteView.swift
        EditRouteView.swift
        RouteDestination.swift
        RoutesListView.swift
```

## Configuration
- Networking:
  - See `Sources/TrainViewer/Networking/TransitAPI.swift` and `LiveTransitAPI.swift`.
  - Journeys are requested with numeric station IDs (IBNR/EVA). We resolve them via `/locations/nearby`/`/stops/nearby` first, then call `/journeys?from=<id>&to=<id>`.
  - Query parameters include `walkingSpeed`, `language`, and `pretty=false` for consistent JSON.
- Persistence: Core Data stack in `Model/PersistenceController.swift`, entities in `TransportModel.xcdatamodeld`.
- Location: `Location/LocationManager.swift` handles permissions and updates.
- Widget: `Sources/NextDepartureWidget/NextDepartureWidget.swift`; Info Plist in `ios/TrainViewer/Support/NextDepartureWidget-Info.plist`.

## Troubleshooting
- Xcode project issues: see `docs/TROUBLESHOOTING.md` (DerivedData cleanup, developer tools selection, project files).
- Widget shows unexpected times:
  - Small widget shows only departure time; leave-in is computed as `departure − walkingMinutes − buffer`.
  - Ensure the app has recent location and at least one saved route; then open the app to refresh the widget cache.
- API validation:
  - Copy the debug URLs from the console (nearest locations/stops and journeys).
  - Use `curl -sS '<url>' | jq .` (avoid `-i`) to verify JSON.

## License
Proprietary – internal development use.


