## Architecture Overview

TrainViewer is a SwiftUI iOS app with a Widget extension. It follows a simple modular directory layout inside `ios/TrainViewer/Sources/`:

- TrainViewer (App target)
  - App.swift: App entry point and lifecycle
  - ContentView.swift: Root UI container
  - Location/
    - LocationManager.swift: CoreLocation wrapper for permissions and updates
  - Model/
    - PersistenceController.swift: Core Data stack configuration
    - RouteEntity.swift: Generated or hand-written Core Data model helpers
    - SharedCache.swift: In-memory cache for shared state
    - TransportModel.xcdatamodeld: Core Data model
   - Networking/
     - TransitAPI.swift: API abstractions and models (incl. TransportMode)
     - LiveTransitAPI.swift: transport.rest v6 integration
       - Resolves nearest numeric station IDs (IBNR/EVA) via `/locations/nearby` or `/stops/nearby`
       - Requests journeys via `/journeys?from=<id>&to=<id>` with `walkingSpeed`, `language`, `pretty=false`
       - Robust ISO8601 parsing (fractional seconds supported)
  - Views/
    - AddRouteView.swift, EditRouteView.swift, RoutesListView.swift, RouteDestination.swift: Feature UIs

- NextDepartureWidget (Widget extension)
  - NextDepartureWidget.swift: Timeline provider and widget UI

### Data Flow
1. UI requests data (e.g., routes and next departures)
2. `TransitAPI` fetches from remote source and maps to models
3. Core Data (`PersistenceController`) persists routes and related info
4. `SharedCache` stores widget payload (route, next departure, walk/buffer mins, transport emoji)
5. `LocationManager` provides optional current location context

### Widget Behavior
- Small: `[emoji] Leave in X min`, `Next: HH:MM`
- Medium: Route name, next window, and large leave-in

### Build Settings and Targets
- App target: `TrainViewer`
- Widget target: `NextDepartureWidget` (or `TrainViewerWidgetExtension` in alternative project)
- iOS Deployment Target: 17.6+ in one project; 18.2 in the alternate project
- Signing: enable Automatic and set your Apple Developer Team


