import SwiftUI

struct MainView: View {
    @EnvironmentObject var vm: RoutesViewModel
    @State private var showingAdd = false
    @State private var editingRoute: Route?

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
                    Button(action: { showingAdd = true }) { Image(systemName: "plus") }
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
                Text("\(formattedTime(first.departure)) → \(formattedTime(first.arrival))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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