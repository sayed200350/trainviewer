import SwiftUI

struct MainView: View {
    @EnvironmentObject var vm: RoutesViewModel
    @State private var showingAdd = false
    @State private var editingRoute: Route?
    @State private var showingSettings = false
    @State private var toast: Toast?

    var body: some View {
        NavigationView {
            Group {
                if vm.routes.isEmpty {
                    VStack(spacing: 12) {
                        Text("Add your first route")
                            .font(.headline)
                        Button(action: { showingAdd = true }) {
                            Label("Add Route", systemImage: "plus")
                        }
                    }
                } else {
                    List {
                        if vm.isOffline {
                            Section {
                                HStack(spacing: 8) {
                                    Image(systemName: "wifi.slash").foregroundColor(.orange)
                                    Text("Offline – showing last saved data").foregroundColor(.orange)
                                }
                            }
                        }
                        if let classCard = vm.nextClass {
                            Section(header: Text("Next Class")) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(classCard.eventTitle).font(.headline)
                                        Text("Leave in \(classCard.leaveInMinutes) min • via \(classCard.routeName)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        ForEach(vm.routes) { route in
                            NavigationLink(destination: RouteDetailView(route: route)) {
                                RouteRow(route: route, status: vm.statusByRouteId[route.id])
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Edit") { editingRoute = route }
                                    .tint(.blue)
                            }
                        }
                        .onDelete(perform: vm.deleteRoute)
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await vm.refreshAll() }
                }
            }
            .navigationTitle("TrainViewer")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { WidgetCenter.shared.reloadAllTimelines() }) { Image(systemName: "arrow.clockwise.circle") }
                        Button(action: { showingSettings = true }) { Image(systemName: "gearshape") }
                        Button(action: { showingAdd = true }) { Image(systemName: "plus") }
                    }
                }
            }
            .sheet(isPresented: $showingAdd, onDismiss: {
                vm.loadRoutes()
                Task { await vm.refreshAll() }
            }) {
                AddRouteView()
            }
            .sheet(item: $editingRoute, onDismiss: {
                vm.loadRoutes()
                Task { await vm.refreshAll() }
            }) { route in
                EditRouteView(route: route)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .toast($toast)
        .onChange(of: vm.isOffline) { isOffline in
            if isOffline { toast = Toast(message: "Offline – showing cached data") }
        }
    }
}

struct RouteRow: View {
    let route: Route
    let status: RouteStatus?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(route.name)
                    .font(.headline)
                Spacer()
                if let leave = status?.leaveInMinutes {
                    if leave <= 0 {
                        Text("Leave now")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    } else {
                        Text("Leave in \(leave) min")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            if let first = status?.options.first {
                HStack(spacing: 8) {
                    Text("\(formattedTime(first.departure)) → \(formattedTime(first.arrival))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let warnings = first.warnings, !warnings.isEmpty {
                        Label("\(warnings.count)", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            } else {
                Text("Fetching...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}