# TrainViewer iOS App

A SwiftUI iOS app that shows real-time German public transport departures for your saved routes, with widgets, Siri intents, calendar sync, and notifications.

## Requirements
- Xcode 15+
- iOS 15+ deployment target (AppIntents-based widget/Siri require iOS 16+)
- Swift Concurrency enabled (Swift 5.7+)
- Internet connection

## Data Source
Uses public `transport.rest` endpoints:
- Primary: `https://v6.db.transport.rest`
- Fallback: `https://v5.vbb.transport.rest`

## Features
- Save favorite routes (origin → destination)
- Real-time next departure options, platform and delay warnings (remarks)
- "Leave in X min" with walking time + buffer, exam mode adds +5 minutes
- Pull to refresh; offline cache fallback and offline indicator
- Add/edit/delete routes, per-route buffer
- Widgets: static + per-widget route selection via AppIntents (iOS 16+)
- Siri Quick Actions: "Next to campus" and "Next home"
- Settings: ticket type, provider preference (DB/VBB/Auto), energy saving, night walking speed, campus and home places, student verification, analytics opt-in
- Class schedule sync (EventKit): Next Class card and leave-time suggestion
- Background refresh (BGTaskScheduler) to update snapshots for widgets
- Deep links: `trainviewer://route?id=<ROUTE_UUID>` opens route details
- Support: reload widgets, clear cache, background refresh, report issue, privacy/terms, rate app

## Widget Behavior (Small)
- Displays: `[emoji] Leave in X min` and `Next: HH:MM`.
- Calculation: `Leave in = departure − walkingMinutes − bufferMinutes`, floored at 0.
- Time format: 24‑hour if enabled in settings; otherwise uses locale short time.
- Emoji: derived from the transport mode (e.g., 🚌 bus, 🚊 tram, 🚇 subway, 🚆 train).

## Transit API Validation
If you need to verify the API responses for a specific origin/destination:

1) Resolve nearby stops (numeric IDs) for origin/destination:
```bash
curl -sS 'https://v6.db.transport.rest/locations/nearby?latitude=<LAT>&longitude=<LNG>&stops=true&addresses=false&poi=false&results=5&pretty=false&language=en' | jq '.[0] | {id,name}'
```

2) Fetch journeys with the numeric IDs (note: use `from` and `to` parameters):
```bash
curl -sS 'https://v6.db.transport.rest/journeys?from=<NUMERIC_ID>&to=<NUMERIC_ID>&results=1&walkingSpeed=normal&language=en&pretty=false' | jq '.journeys[0].legs[0] | {departure, plannedDeparture, arrival, line: .line.product}'
```

Tips:
- Avoid `curl -i` when piping to `jq` (headers will break JSON parsing).
- Compare `departure` vs `plannedDeparture` with what Google Maps shows (Google may show planned times).

## Setup
1. Create a new Xcode project (SwiftUI App) named TrainViewer, iOS 15+
2. Add the `ios/TrainViewer` folder as groups
3. Capabilities (app target):
   - Background Modes: Background fetch
   - Background Tasks: add identifier `com.yourcompany.trainviewer.refresh`
   - App Groups: e.g. `group.com.yourcompany.trainviewer`
4. Capabilities (widget target): enable the same App Group
5. Info (app):
   - URL Types: scheme `trainviewer`
   - `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription`
   - `NSCalendarsUsageDescription`
6. Update `Shared/Constants.swift`: set `appGroupIdentifier`, privacy/terms URLs, support email
7. Add a Widget Extension if needed and include files under `ios/TrainViewer/Widgets`
8. (Optional) Add watchOS target and include `ios/TrainViewerWatch/*`

## Build & Run
- Build the app scheme; on first launch, grant Location and Calendars permissions
- Add routes; open Settings to set Home/Campus and student options
- Pull to refresh; widgets will auto-refresh when data updates
- Add widgets (static or AppIntents) to Home Screen; for AppIntents, choose a route per widget
- Siri: try "Next to campus" or "Next home" after first run (so last location is saved)

## Background Refresh
- A BGAppRefresh task periodically calls `RoutesViewModel.refreshAll()` and repopulates widget snapshots
- You can manually trigger a schedule in Settings → Developer & Support → Trigger Background Refresh

## Deep Links
- `trainviewer://route?id=<ROUTE_UUID>` opens route details; widgets include deep links

## Privacy & Analytics
- Anonymous analytics is off by default; enable in Settings → Modes & Privacy
- Links to Privacy Policy and Terms are available in Settings

## Troubleshooting
- If widgets/Siri don’t show live data, open the app and pull-to-refresh to populate the App Group store, then tap Reload Widgets
- If calendar sync doesn’t show the Next Class card, ensure permission is granted and your events are within 12 hours
- If deep links don’t open, check the app’s URL Types and the scheme spelling

## Extending
- Semester ticket validation flow and savings tracker
- Apple Watch complication for leave time
- Geofencing campus/home to suggest routes automatically
- Server-side push for strike alerts