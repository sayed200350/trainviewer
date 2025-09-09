# API Fetching and Departure Display Logic Documentation

## 🚀 **Architecture Overview**

TrainViewer implements a comprehensive public transport information system with multi-layered architecture for fetching, processing, and displaying next departures.

## 📡 **1. API Fetching Architecture**

### **Transport Service Factory Pattern**

```swift
// TransportAPIFactory.swift - Entry point for API services
final class TransportAPIFactory {
    static let shared = TransportAPIFactory()

    func make() -> TransportAPI {
        let preference = UserSettingsStore.shared.providerPreference
        switch preference {
        case .db:     return DBTransportAPI(provider: .db)
        case .vbb:    return DBTransportAPI(provider: .vbb)
        case .auto:   return AutoTransportAPI(primary: DB, fallback: VBB)
        }
    }
}
```

**Provider Options:**
- **DB (Deutsche Bahn)**: German railway network
- **VBB (Verkehrsverbund Berlin-Brandenburg)**: Berlin regional transport
- **Auto**: Primary DB with VBB fallback

### **DBTransportAPI Implementation**

```swift
final class DBTransportAPI: TransportAPI {
    private let client: APIClient
    private let provider: ProviderPreference

    private var baseURL: URL {
        switch provider {
        case .db: return AppConstants.dbBaseURL
        case .vbb: return AppConstants.vbbBaseURL
        case .auto: return AppConstants.dbBaseURL
        }
    }
}
```

**Base URLs:**
- **DB**: `https://v6.db.transport.rest/`
- **VBB**: `https://v6.vbb.transport.rest/`

## 🛤️ **2. Journey Fetching Logic**

### **Core Journey Fetching Method**

```swift
func nextJourneyOptions(from: Place, to: Place, results: Int = 8) async throws -> [JourneyOption]
```

**API Request Construction:**
```swift
// Build URL with query parameters
var components = URLComponents(url: baseURL.appendingPathComponent("journeys"), resolvingAgainstBaseURL: false)
var items: [URLQueryItem] = [
    URLQueryItem(name: "results", value: String(results)),    // Number of results
    URLQueryItem(name: "stopovers", value: "false"),          // Don't include intermediate stops
    URLQueryItem(name: "remarks", value: "true"),             // Include service remarks
    URLQueryItem(name: "language", value: "en")               // English language
]
```

### **Location Resolution Strategies**

The system uses multiple fallback strategies for location resolution:

```swift
// Strategy 1: Direct ID lookup (preferred)
if let id = from.rawId, !id.isEmpty {
    items.append(URLQueryItem(name: "from", value: encodedId))
}

// Strategy 2: Coordinates with name
else if let lat = from.latitude, let lon = from.longitude {
    items.append(URLQueryItem(name: "from.latitude", value: String(lat)))
    items.append(URLQueryItem(name: "from.longitude", value: String(lon)))
    items.append(URLQueryItem(name: "from.name", value: encodedName))
}

// Strategy 3: Fallback resolution (re-query API)
else {
    let resolvedPlaces = try await resolveLocationSafely(query: from.name, limit: 8)
    // Use first resolved result
}
```

### **Query Enhancement Techniques**

```swift
private func generateQueryVariations(_ query: String) -> [String] {
    // 1. Original query
    // 2. Add "station" suffix if not present
    // 3. Try without special characters
    // 4. Try with common abbreviations
    // 5. Try partial matches
}
```

## 🎯 **3. Journey Selection Logic**

### **Best Option Selection Algorithm**

```swift
private func selectBestJourneyOption(from options: [JourneyOption]) -> JourneyOption? {
    // Filter out invalid options
    let validOptions = options.filter { option in

        // 1. Excessive delays (>30 minutes)
        if let delay = option.delayMinutes, delay > 30 {
            return false
        }

        // 2. Unreasonable journey times (>4 hours)
        if option.totalMinutes > 240 {
            return false
        }

        // 3. Severe warnings/remarks
        if let warnings = option.warnings, !warnings.isEmpty {
            // Analyze remark severity
            return false
        }

        return true
    }

    // Select option with shortest total time
    return validOptions.min(by: { $0.totalMinutes < $1.totalMinutes })
}
```

**Selection Priority:**
1. **Shortest total journey time**
2. **Minimal delays** (< 30 minutes)
3. **Fewest warnings/remarks**
4. **Reasonable journey duration**

## 🏗️ **4. View Model Architecture**

### **RoutesViewModel - Central Data Manager**

```swift
@MainActor
final class RoutesViewModel: ObservableObject {
    @Published private(set) var routes: [Route] = []
    @Published private(set) var statusByRouteId: [UUID: RouteStatus] = [:]
    @Published var isRefreshing: Bool = false
    @Published var isOffline: Bool = false

    private let api: TransportAPI
    private let store: RouteStore
}
```

### **RouteStatus Data Structure**

```swift
struct RouteStatus: Hashable {
    let options: [JourneyOption]      // Available departure options
    let leaveInMinutes: Int?          // Minutes until next departure
    let lastUpdated: Date             // When data was last refreshed
}
```

### **Refresh Logic - Parallel Processing**

```swift
func refreshAll() async {
    await withTaskGroup(of: (UUID, RouteStatus?, Bool).self) { group in
        for route in routes {
            group.addTask { [weak self] in
                do {
                    // Fetch journey options from API
                    let options = try await self.api.nextJourneyOptions(
                        from: route.origin,
                        to: route.destination
                    )

                    // Cache options for offline use
                    self.cache(options: options, for: route)

                    // Compute status (next departure time)
                    let status = self.computeStatus(for: route, options: options)

                    return (route.id, status, false) // success, no cache used

                } catch {
                    // API failed - use cached data
                    let cached = OfflineCache.shared.load(routeId: route.id) ?? []
                    let status = self.computeStatus(for: route, options: cached)

                    return (route.id, status, true) // cache used
                }
            }
        }

        // Collect results from all tasks
        for await (id, status, usedCache) in group {
            if let status = status {
                statusByRouteId[id] = status
            }
        }
    }
}
```

## 🖥️ **5. UI Display Components**

### **MainView - Route List Display**

```swift
struct MainView: View {
    @EnvironmentObject var vm: RoutesViewModel

    var body: some View {
        NavigationView {
            if vm.routes.isEmpty {
                // Empty state
                Text("Add your first route")
            } else {
                List {
                    // Offline indicator
                    if vm.isOffline {
                        Section {
                            HStack {
                                Image(systemName: "wifi.slash")
                                Text("Offline – showing cached data")
                            }
                        }
                    }

                    // Next class reminder (if calendar integration)
                    if let classCard = vm.nextClass {
                        Section(header: Text("Next Class")) {
                            Text("Leave in \(classCard.leaveInMinutes) min • via \(classCard.routeName)")
                        }
                    }

                    // Route list with departure info
                    ForEach(vm.routes) { route in
                        NavigationLink(destination: RouteDetailView(route: route)) {
                            RouteRow(route: route, status: vm.statusByRouteId[route.id])
                        }
                    }
                }
                .refreshable { await vm.refreshAll() }
            }
        }
    }
}
```

### **RouteRow - Individual Route Display**

```swift
struct RouteRow: View {
    let route: Route
    let status: RouteStatus?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(route.name).font(.headline)
                Spacer()

                // Departure urgency indicator
                if let leave = status?.leaveInMinutes {
                    if leave <= 0 {
                        Text("Leave now").foregroundColor(.red)
                    } else {
                        Text("Leave in \(leave) min").foregroundColor(.blue)
                    }
                }
            }

            // Next departure time
            if let first = status?.options.first {
                HStack(spacing: 8) {
                    Text("\(formattedTime(first.departure)) → \(formattedTime(first.arrival))")
                        .foregroundColor(.secondary)

                    // Warning indicator
                    if let warnings = first.warnings, !warnings.isEmpty {
                        Label("\(warnings.count)", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                }
            } else {
                Text("Fetching...").foregroundColor(.secondary)
            }
        }
    }
}
```

### **Status Computation Logic**

```swift
private func computeStatus(for route: Route, options: [JourneyOption]) -> RouteStatus {
    let now = Date()

    // Find next viable departure
    let nextOption = options.first { option in
        let departureTime = option.departure

        // Must depart in the future (within reasonable time)
        let timeUntilDeparture = departureTime.timeIntervalSince(now) / 60
        return timeUntilDeparture >= -5 && timeUntilDeparture <= 120 // -5 to +120 minutes
    }

    let leaveInMinutes = nextOption.map { option in
        let minutes = Int(option.departure.timeIntervalSince(now) / 60)
        return max(0, minutes) // Don't show negative times
    }

    return RouteStatus(
        options: options,
        leaveInMinutes: leaveInMinutes,
        lastUpdated: now
    )
}
```

## 🔄 **6. Background Refresh System**

### **BackgroundRefreshService Architecture**

```swift
final class BackgroundRefreshService: BackgroundRefreshProtocol {
    static let shared = BackgroundRefreshService()

    func register() {
        #if !APP_EXTENSION
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        #endif
    }

    func schedule() {
        #if !APP_EXTENSION
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = calculateNextRefreshTime()

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background refresh: \(error)")
        }
        #endif
    }
}
```

### **Smart Refresh Timing**

```swift
private func calculateNextRefreshTime() -> Date {
    let now = Date()

    // Minimum 5-minute interval between refreshes
    if let lastRefresh = lastRefreshDate,
       now.timeIntervalSince(lastRefresh) < 300 {
        return lastRefresh.addingTimeInterval(300)
    }

    // Check for upcoming departures
    let upcomingDepartures = findUpcomingDepartures()

    if let nextDeparture = upcomingDepartures.first {
        let timeUntilDeparture = nextDeparture.departure.timeIntervalSince(now)

        // Refresh more frequently as departure approaches
        if timeUntilDeparture <= 600 { // 10 minutes
            return now.addingTimeInterval(60)  // Refresh every minute
        } else if timeUntilDeparture <= 3600 { // 1 hour
            return now.addingTimeInterval(300) // Refresh every 5 minutes
        }
    }

    // Default: refresh every 15 minutes
    return now.addingTimeInterval(900)
}
```

### **Background Task Execution**

```swift
internal func handleAppRefresh(task: BGAppRefreshTask) {
    print("🔄 Handling background refresh task")

    // Schedule next refresh immediately
    schedule()

    // Create refresh operation
    let refreshOperation = BackgroundRefreshOperation { [weak self] in
        await self?.triggerManualRefresh()
    }

    // Set completion handler
    refreshOperation.completionBlock = {
        task.setTaskCompleted(success: true)
    }

    // Handle expiration
    task.expirationHandler = {
        refreshOperation.cancel()
        task.setTaskCompleted(success: false)
    }

    // Execute refresh
    let operationQueue = OperationQueue()
    operationQueue.addOperation(refreshOperation)
}
```

## 📦 **7. Offline Caching System**

### **OfflineCache Implementation**

```swift
final class OfflineCache {
    static let shared = OfflineCache()

    func save(options: [JourneyOption], for route: Route) {
        let cacheEntry = CacheEntry(
            routeId: route.id,
            options: options,
            timestamp: Date()
        )

        // Save to UserDefaults/JSON file
        if let encoded = try? JSONEncoder().encode(cacheEntry) {
            UserDefaults.standard.set(encoded, forKey: "route_\(route.id)")
        }
    }

    func load(routeId: UUID) -> [JourneyOption]? {
        guard let data = UserDefaults.standard.data(forKey: "route_\(routeId)") else {
            return nil
        }

        do {
            let entry = try JSONDecoder().decode(CacheEntry.self, from: data)

            // Check if cache is still fresh (< 2 hours old)
            if Date().timeIntervalSince(entry.timestamp) < 7200 {
                return entry.options
            }
        } catch {
            print("Failed to decode cached options: \(error)")
        }

        return nil
    }
}
```

## 🔧 **8. Error Handling & Resilience**

### **API Error Recovery**

```swift
do {
    let options = try await api.nextJourneyOptions(from: origin, to: destination)
    // Success - cache and display
    cache(options: options, for: route)

} catch APIError.networkError {
    // Network issues - use cache if available
    let cached = OfflineCache.shared.load(routeId: route.id)

} catch APIError.invalidResponse {
    // API issues - show error state
    print("API returned invalid response")

} catch {
    // Generic error - fallback to cache
    let cached = OfflineCache.shared.load(routeId: route.id)
}
```

### **Graceful Degradation**

```swift
// 1. Try primary API (DB)
let options = try await dbAPI.nextJourneyOptions(from: origin, to: destination)

// 2. If primary fails, try fallback (VBB)
if options.isEmpty {
    options = try await vbbAPI.nextJourneyOptions(from: origin, to: destination)
}

// 3. If all APIs fail, use cached data
if options.isEmpty {
    options = OfflineCache.shared.load(routeId: route.id) ?? []
}
```

## 📊 **9. Data Flow Summary**

```
User Action → RoutesViewModel.refreshAll()
    ↓
Concurrent Tasks for Each Route
    ↓
API Call: nextJourneyOptions(from: Place, to: Place)
    ↓
Location Resolution (ID/Coordinates/Fallback)
    ↓
HTTP Request to Transport API
    ↓
JSON Response Parsing
    ↓
Journey Filtering & Selection
    ↓
Cache Storage + Status Computation
    ↓
UI Update (RouteRow display)
    ↓
Background Refresh Scheduling
```

## 🎯 **10. Performance Optimizations**

### **Concurrent Processing**
- **Parallel API calls** for multiple routes using `withTaskGroup`
- **Non-blocking UI** with `@MainActor` updates
- **Operation queues** for background processing

### **Smart Caching Strategy**
- **Offline-first** approach with cache validation
- **Time-based expiration** (2-hour cache lifetime)
- **Selective caching** (only successful responses)

### **Memory Management**
- **Weak self references** in async closures
- **Automatic cleanup** of background operations
- **Resource pooling** for API clients

This architecture provides a robust, performant, and user-friendly public transport information system with comprehensive error handling, offline support, and intelligent refresh timing. 🚀
