import SwiftUI
import MapKit

struct AddRouteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = AddRouteViewModel()
    @FocusState private var focusedField: Field?

    enum Field {
        case routeName, from, to
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Route Name Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Route Name")
                                .font(.headline)
                                .foregroundColor(.primary)

                            HStack {
                                Image(systemName: "signpost.right")
                                    .foregroundColor(.blue)
                                    .frame(width: 20)

                                TextField("e.g. Home → University", text: $vm.routeName)
                                    .focused($focusedField, equals: .routeName)
                                    .textInputAutocapitalization(.words)
                                    .submitLabel(.next)

                                if !vm.routeName.isEmpty {
                                    Button(action: { vm.routeName = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(vm.routeName.isEmpty ? Color.gray.opacity(0.2) : Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)

                        // From Location Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "mappin.circle")
                                    .foregroundColor(.green)
                                Text("From")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Spacer()

                                if vm.isSearchingFrom {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }

                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)

                                TextField("Search departure location", text: $vm.fromQuery)
                                    .focused($focusedField, equals: .from)
                                    .textInputAutocapitalization(.words)
                                    .submitLabel(.search)
                                    .onChange(of: vm.fromQuery) { _ in
                                        Task { await vm.searchFrom() }
                                    }

                                if !vm.fromQuery.isEmpty {
                                    Button(action: { vm.fromQuery = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(vm.selectedFrom != nil ? Color.green.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1)
                            )

                            // Quick Actions
                            HStack(spacing: 12) {
                                Button(action: { vm.useCurrentLocationForFrom() }) {
                                    HStack {
                                        Image(systemName: "location.fill")
                                        Text("Current Location")
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }

                                Button(action: { vm.showRecentFrom.toggle() }) {
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                        Text("Recent")
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }

                            // Search Results
                            if !vm.fromResults.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(vm.fromResults, id: \.self) { place in
                                        Button(action: {
                                            vm.selectedFrom = place
                                            vm.fromQuery = place.name
                                            focusedField = .to // Move to next field
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(place.name)
                                                        .font(.body)
                                                        .foregroundColor(.primary)
                                                    if let coordinate = place.coordinate {
                                                        Text(String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude))
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                            .lineLimit(1)
                                                    }
                                                }
                                                Spacer()
                                                if vm.selectedFrom == place {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.green)
                                                        .font(.title3)
                                                } else {
                                                    Image(systemName: "chevron.right")
                                                        .foregroundColor(.gray)
                                                        .font(.caption)
                                                }
                                            }
                                            .padding()
                                            .background(vm.selectedFrom == place ? Color.green.opacity(0.1) : Color.clear)
                                        }
                                        .buttonStyle(.plain)

                                        if place != vm.fromResults.last {
                                            Divider()
                                                .padding(.leading)
                                        }
                                    }
                                }
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            }

                            // Recent Locations
                            if vm.showRecentFrom && !vm.recentFromLocations.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Recent Locations")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    ForEach(vm.recentFromLocations, id: \.self) { place in
                                        Button(action: {
                                            vm.selectedFrom = place
                                            vm.fromQuery = place.name
                                            vm.showRecentFrom = false
                                        }) {
                                            HStack {
                                                Image(systemName: "clock")
                                                    .foregroundColor(.gray)
                                                Text(place.name)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)

                        // To Location Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "mappin.circle")
                                    .foregroundColor(.red)
                                Text("To")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Spacer()

                                if vm.isSearchingTo {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }

                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)

                                TextField("Search destination", text: $vm.toQuery)
                                    .focused($focusedField, equals: .to)
                                    .textInputAutocapitalization(.words)
                                    .submitLabel(.done)
                                    .onChange(of: vm.toQuery) { _ in
                                        Task { await vm.searchTo() }
                                    }

                                if !vm.toQuery.isEmpty {
                                    Button(action: { vm.toQuery = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(vm.selectedTo != nil ? Color.red.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1)
                            )

                            // Quick Actions
                            HStack(spacing: 12) {
                                Button(action: { vm.useCurrentLocationForTo() }) {
                                    HStack {
                                        Image(systemName: "location.fill")
                                        Text("Current Location")
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }

                                Button(action: { vm.showRecentTo.toggle() }) {
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                        Text("Recent")
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }

                            // Search Results
                            if !vm.toResults.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(vm.toResults, id: \.self) { place in
                                        Button(action: {
                                            vm.selectedTo = place
                                            vm.toQuery = place.name
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(place.name)
                                                        .font(.body)
                                                        .foregroundColor(.primary)
                                                    if let coordinate = place.coordinate {
                                                        Text(String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude))
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                            .lineLimit(1)
                                                    }
                                                }
                                                Spacer()
                                                if vm.selectedTo == place {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.red)
                                                        .font(.title3)
                                                } else {
                                                    Image(systemName: "chevron.right")
                                                        .foregroundColor(.gray)
                                                        .font(.caption)
                                                }
                                            }
                                            .padding()
                                            .background(vm.selectedTo == place ? Color.red.opacity(0.1) : Color.clear)
                                        }
                                        .buttonStyle(.plain)

                                        if place != vm.toResults.last {
                                            Divider()
                                                .padding(.leading)
                                        }
                                    }
                                }
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            }

                            // Recent Locations
                            if vm.showRecentTo && !vm.recentToLocations.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Recent Locations")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    ForEach(vm.recentToLocations, id: \.self) { place in
                                        Button(action: {
                                            vm.selectedTo = place
                                            vm.toQuery = place.name
                                            vm.showRecentTo = false
                                        }) {
                                            HStack {
                                                Image(systemName: "clock")
                                                    .foregroundColor(.gray)
                                                Text(place.name)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)

                        // Route Preview
                        if let from = vm.selectedFrom, let to = vm.selectedTo {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Route Preview")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(from.name)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("→")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(to.name)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }

                        // Save Button
                        VStack {
                            Button(action: {
                                vm.saveRoute()
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text(vm.selectedFrom != nil && vm.selectedTo != nil ? "Save Route" : "Select locations to continue")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(vm.selectedFrom != nil && vm.selectedTo != nil ? Color.blue : Color.gray.opacity(0.3))
                                .foregroundColor(vm.selectedFrom != nil && vm.selectedTo != nil ? .white : .gray)
                                .cornerRadius(12)
                            }
                            .disabled(vm.selectedFrom == nil || vm.selectedTo == nil)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Add Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Cancel")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .onSubmit {
                switch focusedField {
                case .routeName:
                    focusedField = .from
                case .from:
                    focusedField = .to
                case .to:
                    focusedField = nil
                case .none:
                    break
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}