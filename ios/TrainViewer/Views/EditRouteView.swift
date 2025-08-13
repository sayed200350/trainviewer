import SwiftUI

struct EditRouteView: View {
    let route: Route
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: EditRouteViewModel

    init(route: Route) {
        self.route = route
        _vm = StateObject(wrappedValue: EditRouteViewModel(route: route))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Route Name")) {
                    TextField("Name", text: $vm.routeName)
                }

                Section(header: Text("From")) {
                    TextField("Search origin", text: $vm.fromQuery)
                        .onChange(of: vm.fromQuery) { _ in Task { await vm.searchFrom() } }
                    if !vm.fromResults.isEmpty {
                        ForEach(vm.fromResults, id: \.self) { place in
                            Button(action: { vm.selectedFrom = place; vm.fromQuery = place.name }) {
                                HStack { Text(place.name); Spacer(); if vm.selectedFrom == place { Image(systemName: "checkmark") } }
                            }
                        }
                    }
                }

                Section(header: Text("To")) {
                    TextField("Search destination", text: $vm.toQuery)
                        .onChange(of: vm.toQuery) { _ in Task { await vm.searchTo() } }
                    if !vm.toResults.isEmpty {
                        ForEach(vm.toResults, id: \.self) { place in
                            Button(action: { vm.selectedTo = place; vm.toQuery = place.name }) {
                                HStack { Text(place.name); Spacer(); if vm.selectedTo == place { Image(systemName: "checkmark") } }
                            }
                        }
                    }
                }

                Section(header: Text("Buffer"), footer: Text("Extra minutes to prepare before leaving")) {
                    Stepper(value: $vm.bufferMinutes, in: 0...10) {
                        Text("Buffer: \(vm.bufferMinutes) min")
                    }
                }

                Section {
                    Button("Save Changes") { vm.saveChanges(); dismiss() }
                }
            }
            .navigationTitle("Edit Route")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel", action: { dismiss() }) } }
        }
    }
}