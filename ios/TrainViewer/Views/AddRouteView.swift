import SwiftUI

struct AddRouteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = AddRouteViewModel()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Route Name (optional)")) {
                    TextField("e.g. Home → Uni", text: $vm.routeName)
                        .textInputAutocapitalization(.words)
                }

                Section(header: Text("From")) {
                    TextField("Search origin", text: $vm.fromQuery)
                        .onChange(of: vm.fromQuery) { _ in Task { await vm.searchFrom() } }
                    if !vm.fromResults.isEmpty {
                        ForEach(vm.fromResults, id: \.self) { place in
                            Button(action: { vm.selectedFrom = place; vm.fromQuery = place.name }) {
                                HStack {
                                    Text(place.name)
                                    Spacer()
                                    if vm.selectedFrom == place { Image(systemName: "checkmark") }
                                }
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
                                HStack {
                                    Text(place.name)
                                    Spacer()
                                    if vm.selectedTo == place { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    }
                }

                Section {
                    Button(action: { vm.saveRoute(); dismiss() }) {
                        Text("Save Route")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(vm.selectedFrom == nil || vm.selectedTo == nil)
                }
            }
            .navigationTitle("Add Route")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel", action: { dismiss() }) }
            }
        }
    }
}