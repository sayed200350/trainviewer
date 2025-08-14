import SwiftUI
import CoreData
import WidgetKit
import CoreLocation

struct RoutesListView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \RouteEntity.createdAt, ascending: false)],
        animation: .default
    ) private var routes: FetchedResults<RouteEntity>

    @State private var showingAdd = false
    @State private var editingRoute: RouteEntity?

    var body: some View {
        List {
            if routes.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No routes yet")
                            .font(.headline)
                        Text("Tap + to add your first route")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 24)
                }
            }
            ForEach(routes) { route in
                NavigationLink(destination: RouteDetailView(route: route)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(route.name)
                            .font(.headline)
                        Text("\(route.originName) → \(route.destName)")
                            .foregroundColor(.secondary)
                    }
                }
                .contextMenu {
                    Button {
                        editingRoute = route
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        editingRoute = route
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                .onAppear {
                    // ensure routes list saved for intent suggestions
                    SharedCache.saveRoutes(from: Array(routes))
                }
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("Routes")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAdd = true }) { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) {
            NavigationStack { AddRouteView() }
        }
        .sheet(item: $editingRoute) { r in
            NavigationStack { EditRouteView(route: r) }
        }
    }

    private func delete(offsets: IndexSet) {
        let repo = RouteRepository()
        for index in offsets {
            do { try repo.delete(routes[index]) } catch {}
        }
        SharedCache.saveRoutes(from: Array(routes))
    }
}

struct RouteDetailView: View {
    let route: RouteEntity
    @State private var departures: [Departure] = []
    private let api: TransitAPI = TransitAPIProvider.shared.api

    var body: some View {
        List {
            Section("Route") {
                Text(route.name).font(.headline)
                Text("\(route.originName) → \(route.destName)")
            }
            Section("Next Departures") {
                if departures.isEmpty {
                    ProgressView()
                } else {
                    ForEach(departures) { d in
                        VStack(alignment: .leading) {
                            Text("Leave in \(leaveInMinutes(for: d)) min")
                                .font(.headline)
                            Text("\(format(d.departureTime)) → \(format(d.arrivalTime))")
                                .foregroundColor(.secondary)
                            if let p = d.platform { Text("Platform \(p)") }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Details")
        .task { await load() }
        .onAppear {
            SharedCache.setLastUsedRouteId(route.id)
        }
    }

    private func load() async {
        do {
            departures = try await api.fetchNextDepartures(
                origin: route.originCoordinate,
                destination: route.destCoordinate,
                limit: 3
            )
            SharedCache.updateDepartures(for: route, departures: departures)
        } catch {
            departures = []
        }
    }

    private func leaveInMinutes(for d: Departure) -> Int {
        // Include walking/prep buffer
        let buffer = Int(route.walkBufferMins)
        let minutes = Int(d.departureTime.timeIntervalSinceNow / 60) - buffer
        return max(0, minutes)
    }

    private func format(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}


