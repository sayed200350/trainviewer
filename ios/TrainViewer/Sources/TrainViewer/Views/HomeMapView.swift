import SwiftUI
import MapKit
import CoreLocation
import CoreData

enum StationType: String, CaseIterable { case sBahn, uBahn, bus, tram, regional }
enum ServiceStatus: String, CaseIterable { case onTime, delayed, disrupted, noService }

struct NearbyStation: Identifiable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    let distanceMeters: CLLocationDistance
    let type: StationType
    let status: ServiceStatus
}

struct HomeMapView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \RouteEntity.createdAt, ascending: false)],
        animation: .default
    ) private var routes: FetchedResults<RouteEntity>

    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var stations: [NearbyStation] = []
    @State private var isShowingTicket = false
    @State private var isShowingAddRoute = false
    @State private var panelExpanded = false
    @State private var disruptionBanner: String?
    @State private var previewRoute: (RoutePreviewPoint, RoutePreviewPoint)?
    @GestureState private var dragOffset: CGFloat = 0
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @State private var selectedRouteId: String?

    // Quick departures cache (by route id)
    @State private var departuresByRoute: [String: [Departure]] = [:]
    private let api: TransitAPI = TransitAPIProvider.shared.api

    var body: some View {
        ZStack(alignment: .top) {
            mapLayer
                .ignoresSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            // Google Maps-style search pill at the very top
            SearchPill()
                .onTapGesture {
                    // Present route preview with current location and last route's destination if available
                    if let latest = routes.first {
                        let originPoint: RoutePreviewPoint
                        if let loc = locationManager.lastKnownLocation?.coordinate {
                            originPoint = RoutePreviewPoint(name: "Current Location", coordinate: loc)
                        } else {
                            originPoint = RoutePreviewPoint(name: latest.originName, coordinate: latest.originCoordinate)
                        }
                        let destPoint = RoutePreviewPoint(name: latest.destName, coordinate: latest.destCoordinate)
                        presentPreview(origin: originPoint, destination: destPoint)
                    } else {
                        isShowingAddRoute = true
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .top)

            // Floating controls bottom-right
            VStack(spacing: 16) {
                ControlButton(systemName: "location.fill", action: centerOnUser)
                ControlButton(systemName: "ticket.fill") { isShowingTicket = true }
                ControlButton(systemName: "plus") { isShowingAddRoute = true }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, 16)
            .padding(.bottom, 24)

            // Saved routes button (top-right)
            NavigationLink(destination: RoutesListView()) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(.regularMaterial, in: Circle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 8)
            .padding(.trailing, 12)

            // Disruption banner (top-center)
            if let banner = disruptionBanner {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
                    Text(banner).font(.subheadline)
                    Spacer(minLength: 8)
                    if let latest = routes.first {
                        Button("See alternatives") {
                            let o = RoutePreviewPoint(name: latest.originName, coordinate: latest.originCoordinate)
                            let d = RoutePreviewPoint(name: latest.destName, coordinate: latest.destCoordinate)
                            presentPreview(origin: o, destination: d)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .font(.caption)
                    }
                    Button(action: { withAnimation { disruptionBanner = nil } }) {
                        Image(systemName: "xmark").font(.caption)
                    }
                }
                .padding(10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.top, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .safeAreaInset(edge: .bottom) {
            DeparturesBottomSheet(
                routes: Array(routes),
                departuresByRoute: $departuresByRoute,
                selectedRouteId: $selectedRouteId,
                isExpanded: $panelExpanded
            )
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .padding(.horizontal)
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isShowingTicket) {
            NavigationStack { TicketDetailsView() }
        }
        .sheet(isPresented: $isShowingAddRoute) {
            NavigationStack { AddRouteView() }
        }
        .sheet(item: Binding(
            get: { previewRoute.map { IdentifiedPreview(id: UUID(), origin: $0.0, destination: $0.1) } },
            set: { newValue in previewRoute = newValue.map { ($0.origin, $0.destination) } }
        )) { item in
            RoutePreviewView(origin: item.origin, destination: item.destination) { _ in
                handlePreviewConfirm(origin: item.origin, destination: item.destination)
            }
        }
        .task { await initializeAndLoad() }
        .onChange(of: locationManager.lastKnownLocation) { _, _ in Task { await searchStationsIfNeeded() } }
        .onChange(of: routes.count) { _, _ in Task { await refreshDepartures() } }
    }

    @ViewBuilder
    private var mapLayer: some View {
        if #available(iOS 17.0, *) {
            Map(position: $mapPosition) {
                if let loc = locationManager.lastKnownLocation {
                    let center = loc.coordinate
                    let accuracy = max(loc.horizontalAccuracy, 30)
                    MapCircle(center: center, radius: accuracy)
                        .foregroundStyle(Color.blue.opacity(0.15))
                    Annotation("user", coordinate: center) {
                        UserPuck(isStale: Date().timeIntervalSince(loc.timestamp) > 300)
                    }
                }

                // Nearby station pins
                ForEach(stations) { station in
                    Annotation(station.name, coordinate: station.coordinate) {
                        Circle()
                            .fill(station.status == .disrupted ? .gray : color(for: station.type))
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(color: .black.opacity(0.2), radius: 2)
                            .accessibilityLabel(station.name)
                    }
                }

                // Route overlay only for selected route
                if let rid = selectedRouteId, let route = routes.first(where: { $0.id == rid }) {
                    let coords = [route.originCoordinate, route.destCoordinate]
                    MapPolyline(coordinates: coords)
                        .stroke(Color.green.opacity(0.8), lineWidth: 3)
                }
            }
            .mapStyle(.standard(elevation: .realistic, emphasis: .muted))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        } else {
            Map(
                coordinateRegion: $region,
                interactionModes: [.all],
                showsUserLocation: true,
                userTrackingMode: .none,
                annotationItems: stations
            ) { station in
                MapMarker(coordinate: station.coordinate, tint: .orange)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
    }

    private func initializeAndLoad() async {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.requestLocation()
        if let loc = locationManager.lastKnownLocation?.coordinate {
            region.center = loc
        }
        await searchStationsIfNeeded()
        await refreshDepartures()
        await DisruptionMonitor.shared.requestNotificationAuth()
    }

    private func centerOnUser() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.requestLocation()
        if let loc = locationManager.lastKnownLocation?.coordinate {
            if #available(iOS 17.0, *) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    mapPosition = .region(MKCoordinateRegion(center: loc, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)))
                }
            } else {
                withAnimation { region.center = loc }
            }
        }
    }

    private func searchStationsIfNeeded() async {
        guard let userCoordinate = locationManager.lastKnownLocation?.coordinate else { return }
        let currentCenter = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        let userLocation = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        if currentCenter.distance(from: userLocation) > 1000 {
            region.center = userCoordinate
        }

        let req = MKLocalSearch.Request()
        if #available(iOS 15.0, *) {
            req.pointOfInterestFilter = MKPointOfInterestFilter(including: [.publicTransport])
        }
        req.naturalLanguageQuery = "station"
        req.region = region
        let search = MKLocalSearch(request: req)
        let response = try? await search.start()
        let items = response?.mapItems ?? []
        let base = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        let mapped: [NearbyStation] = items.compactMap { item in
            guard let coord = item.placemark.location?.coordinate else { return nil }
            let dist = item.placemark.location.map { $0.distance(from: base) } ?? 0
            let type = StationType.allCases.randomElement() ?? .uBahn
            let status = ServiceStatus.allCases.randomElement() ?? .onTime
            return NearbyStation(id: UUID(), name: item.name ?? "Station", coordinate: coord, distanceMeters: dist, type: type, status: status)
        }
        let top = mapped.sorted { $0.distanceMeters < $1.distanceMeters }.prefix(50)
        await MainActor.run { stations = Array(top) }
    }

    private func refreshDepartures() async {
        let safeRoutes: [RouteInfo] = routes.map { r in
            RouteInfo(
                id: r.id,
                name: r.name,
                origin: r.originCoordinate,
                dest: r.destCoordinate,
                walkBufferMins: Int(r.walkBufferMins)
            )
        }
        await withTaskGroup(of: (String, [Departure]).self) { group in
            for info in safeRoutes {
                group.addTask {
                    let list: [Departure]
                    do {
                        list = try await api.fetchNextDepartures(origin: info.origin, destination: info.dest, limit: 3)
                    } catch {
                        list = []
                    }
                    return (info.id, list)
                }
            }
            var updated: [String: [Departure]] = [:]
            for await (id, list) in group { updated[id] = list }
            await MainActor.run { departuresByRoute = updated }
        }

        // Update widget cache for the most recent route if available
        if let latest = routes.first, let list = departuresByRoute[latest.id], !list.isEmpty {
            SharedCache.updateDepartures(for: latest, departures: list)
            SharedCache.setLastUsedRouteId(latest.id)
            // Simple disruption check with in-app banner trigger
            let planned = Date().addingTimeInterval(TimeInterval(Int(latest.walkBufferMins) * 60))
            if let delay = await DisruptionMonitor.shared.detectDelay(
                origin: latest.originCoordinate,
                destination: latest.destCoordinate,
                plannedDeparture: planned,
                thresholdMinutes: 5
            ) {
                await MainActor.run {
                    disruptionBanner = "Delay detected: +\(delay) min"
                }
            }
        }
    }
}

private struct RouteInfo: Identifiable {
    let id: String
    let name: String
    let origin: CLLocationCoordinate2D
    let dest: CLLocationCoordinate2D
    let walkBufferMins: Int
}

// Minimal bottom sheet used with safeAreaInset
private struct DeparturesBottomSheet: View {
    let routes: [RouteEntity]
    @Binding var departuresByRoute: [String: [Departure]]
    @Binding var selectedRouteId: String?
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 14) {
            Capsule().fill(Color.secondary.opacity(0.35)).frame(width: 40, height: 5)
                .padding(.top, 8)
            header
            content
            actions
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "tram.fill").foregroundStyle(.secondary)
            Text("Next Departures").font(.system(size: 18, weight: .semibold))
            Spacer()
            NavigationLink(destination: RoutesListView()) {
                Label("Routes", systemImage: "list.bullet").labelStyle(.iconOnly).foregroundStyle(.secondary)
            }
            .accessibilityLabel("Saved Routes")
        }
    }

    @ViewBuilder
    private var content: some View {
        if routes.isEmpty {
            HStack {
                Image(systemName: "info.circle")
                Text("Add a route to see quick departures").foregroundColor(.secondary)
                Spacer()
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(routes) { route in
                        Button { selectedRouteId = route.id } label: { card(for: route) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 18) {
            NavigationLink(destination: AddRouteView()) { label(icon: "plus", title: "Add Route") }
            Button(action: { withAnimation(.spring()) { selectedRouteId = nil } }) { label(icon: "slash.circle", title: "Clear Path") }
            NavigationLink(destination: WidgetConfigView()) { label(icon: "gearshape", title: "Settings") }
            Button(action: { /* share */ }) { label(icon: "square.and.arrow.up", title: "Share") }
            Spacer()
        }
    }

    @ViewBuilder
    private func card(for route: RouteEntity) -> some View {
        let list = departuresByRoute[route.id] ?? []
        VStack(alignment: .leading, spacing: 8) {
            Text(route.name).font(.system(size: 15, weight: .semibold)).lineLimit(1)
            Text("\(route.originName) → \(route.destName)").font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
            if let first = list.first {
                let minutes = max(0, Int(first.departureTime.timeIntervalSinceNow / 60) - Int(route.walkBufferMins))
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "tram.fill").foregroundStyle(.blue)
                    Text("\(minutes)").font(.system(size: 28, weight: .bold, design: .rounded)).monospacedDigit()
                    Text("min").font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Text("\(format(first.departureTime)) → \(format(first.arrivalTime))").font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
                if let p = first.platform { Text("Platform \(p)").font(.system(size: 11)).foregroundStyle(.secondary) }
            } else {
                HStack(spacing: 8) { ProgressView().scaleEffect(0.8); Text("No realtime data").font(.system(size: 12)).foregroundStyle(.secondary) }
            }
        }
        .padding(14)
        .frame(width: 260, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func format(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    @ViewBuilder
    private func label(icon: String, title: String) -> some View {
        HStack(spacing: 6) { Image(systemName: icon); Text(title) }
            .font(.footnote)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(Capsule())
    }
}

private struct QuickDeparturesPanel: View {
    let routes: [RouteEntity]
    @Binding var departuresByRoute: [String: [Departure]]
    let collapsedHeight: CGFloat
    let expandedHeight: CGFloat
    @Binding var panelExpanded: Bool
    @Binding var selectedRouteId: String?

    var body: some View {
        VStack(spacing: 12) {
            Capsule().fill(Color.secondary.opacity(0.4)).frame(width: 40, height: 5)
                .padding(.top, 10)
            HStack(spacing: 12) {
                Image(systemName: "tram.fill").foregroundStyle(.secondary)
                Text("Next Departures").font(.system(size: 18, weight: .semibold))
                Spacer()
                NavigationLink(destination: RoutesListView()) {
                    Label("Routes", systemImage: "list.bullet")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Saved Routes")
            }
            .padding(.horizontal)

            if routes.isEmpty {
                HStack {
                    Image(systemName: "info.circle")
                    Text("Add a route to see quick departures")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(routes) { route in
                            Button {
                                selectedRouteId = route.id
                            } label: {
                                departureCard(for: route)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            HStack(spacing: 18) {
                NavigationLink(destination: AddRouteView()) {
                    label(icon: "plus", title: "Add Route")
                }
                Button(action: { withAnimation(.spring()) { selectedRouteId = nil } }) { label(icon: "slash.circle", title: "Clear Path") }
                NavigationLink(destination: WidgetConfigView()) {
                    label(icon: "gearshape", title: "Settings")
                }
                Button(action: { /* share */ }) { label(icon: "square.and.arrow.up", title: "Share") }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
    }

    @ViewBuilder
    private func departureCard(for route: RouteEntity) -> some View {
        let list = departuresByRoute[route.id] ?? []
        VStack(alignment: .leading, spacing: 8) {
            Text(route.name)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
            Text("\(route.originName) → \(route.destName)")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if let first = list.first {
                let minutes = max(0, Int(first.departureTime.timeIntervalSinceNow / 60) - Int(route.walkBufferMins))
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "tram.fill")
                        .foregroundStyle(.blue)
                    Text("\(minutes)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("min")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Text("\(format(first.departureTime)) → \(format(first.arrivalTime))")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let p = first.platform {
                    Text("Platform \(p)").font(.system(size: 11)).foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.8)
                    Text("No realtime data").font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .frame(width: 260, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func format(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    @ViewBuilder
    private func label(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.footnote)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(Capsule())
    }
}

// MARK: - Helpers
private func color(for type: StationType) -> Color {
    switch type {
    case .sBahn: return Color(red: 0.203, green: 0.78, blue: 0.349)
    case .uBahn: return Color(red: 0.0, green: 0.48, blue: 1.0)
    case .bus: return Color(red: 1.0, green: 0.58, blue: 0.0)
    case .tram: return Color(red: 0.686, green: 0.322, blue: 0.871)
    case .regional: return Color(red: 1.0, green: 0.231, blue: 0.188)
    }
}

private struct UserPuck: View {
    let isStale: Bool
    @State private var animate = false
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.blue.opacity(isStale ? 0.15 : 0.25), lineWidth: 6)
                .frame(width: 28, height: 28)
                .scaleEffect(animate ? 1.2 : 1.0)
                .opacity(animate ? 0.2 : 0.35)
            Circle()
                .fill(isStale ? Color.blue.opacity(0.4) : Color.blue)
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                .frame(width: 20, height: 20)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

private struct IdentifiedPreview: Identifiable {
    let id: UUID
    let origin: RoutePreviewPoint
    let destination: RoutePreviewPoint
}

extension HomeMapView {
    private func presentPreview(origin: RoutePreviewPoint, destination: RoutePreviewPoint) {
        previewRoute = (origin, destination)
    }

    private func handlePreviewConfirm(origin: RoutePreviewPoint, destination: RoutePreviewPoint) {
        do {
            try RouteRepository().create(
                name: "\(origin.name) → \(destination.name)",
                originName: origin.name,
                origin: origin.coordinate,
                originPlaceId: nil,
                destName: destination.name,
                dest: destination.coordinate,
                destPlaceId: nil,
                walkBufferMins: AppPreferences.shared.preferredDepartureBufferMins,
                user: try? UserRepository().getOrCreateLocalUser()
            )
            Task { await refreshDepartures() }
        } catch {
            // Silently ignore for MVP
        }
    }
}

// MARK: - Google Maps-like UI pieces

private struct SearchPill: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            Text("Search stations, addresses…")
                .foregroundStyle(.secondary)
            Spacer()
            Image(systemName: "mic.fill")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }
}

private struct ControlButton: View {
    let systemName: String
    let action: () -> Void
    init(systemName: String, action: @escaping () -> Void) {
        self.systemName = systemName
        self.action = action
    }
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
        }
    }
}
