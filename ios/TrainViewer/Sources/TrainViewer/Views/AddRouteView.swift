import SwiftUI
import MapKit
import CoreLocation
import CoreData

struct AddRouteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @StateObject private var locationManager = LocationManager()

    @State private var routeName: String = ""
    @State private var originQuery: String = ""
    @State private var destQuery: String = ""
    @State private var walkBuffer: Int = 2

    @State private var originSelection: PlaceResult?
    @State private var destSelection: PlaceResult?

    @State private var originResults: [PlaceResult] = []
    @State private var destResults: [PlaceResult] = []

    var body: some View {
        Form {
            Section("Name") {
                TextField("Morning commute", text: $routeName)
            }
            Section("Origin") {
                TextField("Search origin", text: $originQuery)
                    .onChange(of: originQuery) { _, _ in Task { await searchOrigin() } }
                HStack {
                    Button {
                        if locationManager.authorizationStatus == .notDetermined {
                            locationManager.requestWhenInUseAuthorization()
                        }
                        locationManager.requestLocation()
                        if let loc = locationManager.lastKnownLocation?.coordinate {
                            let pr = PlaceResult(
                                id: UUID(),
                                name: "Current Location",
                                subtitle: "Your position",
                                coordinate: loc,
                                placeId: nil
                            )
                            originSelection = pr
                            originQuery = pr.name
                        }
                    } label: {
                        Label("Use current location", systemImage: "location.fill")
                    }
                    .buttonStyle(.borderless)
                    Spacer()
                }
                if !originResults.isEmpty {
                    ForEach(originResults) { r in
                        Button(action: { originSelection = r; originQuery = r.name }) {
                            VStack(alignment: .leading) {
                                Text(r.name)
                                Text(r.subtitle).font(.footnote).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                if let o = originSelection {
                    Label("Selected: \(o.name)", systemImage: "mappin.and.ellipse")
                }
            }
            Section("Destination") {
                TextField("Search destination", text: $destQuery)
                    .onChange(of: destQuery) { _, _ in Task { await searchDest() } }
                if !destResults.isEmpty {
                    ForEach(destResults) { r in
                        Button(action: { destSelection = r; destQuery = r.name }) {
                            VStack(alignment: .leading) {
                                Text(r.name)
                                Text(r.subtitle).font(.footnote).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                if let d = destSelection {
                    Label("Selected: \(d.name)", systemImage: "mappin")
                }
            }
            Section("Options") {
                Stepper("Prep buffer: \(walkBuffer) min", value: $walkBuffer, in: 0...15)
            }
        }
        .navigationTitle("Add Route")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save).disabled(!canSave)
            }
        }
    }

    private var canSave: Bool {
        !routeName.trimmingCharacters(in: .whitespaces).isEmpty && originSelection != nil && destSelection != nil
    }

    private func save() {
        guard let o = originSelection, let d = destSelection else { return }
        do {
            let user = try? UserRepository().getOrCreateLocalUser()
            try RouteRepository().create(
                name: routeName,
                originName: o.name,
                origin: o.coordinate,
                originPlaceId: o.placeId,
                destName: d.name,
                dest: d.coordinate,
                destPlaceId: d.placeId,
                walkBufferMins: walkBuffer,
                user: user
            )
            // Update shared cache so widget configuration can list routes immediately
            let request = NSFetchRequest<RouteEntity>(entityName: "Route")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \RouteEntity.createdAt, ascending: false)]
            if let list = try? context.fetch(request) {
                SharedCache.saveRoutes(from: list)
            }
            dismiss()
        } catch {
            // For MVP, swallow error; production should surface to user
        }
    }

    private func searchOrigin() async { originResults = await search(query: originQuery) }
    private func searchDest() async { destResults = await search(query: destQuery) }

    private func search(query: String) async -> [PlaceResult] {
        guard query.count > 2 else { return [] }
        return await withCheckedContinuation { cont in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            let search = MKLocalSearch(request: request)
            search.start { response, _ in
                let items = response?.mapItems ?? []
                let results = items.compactMap { item -> PlaceResult? in
                    guard let loc = item.placemark.location?.coordinate else { return nil }
                    return PlaceResult(
                        id: UUID(),
                        name: item.name ?? item.placemark.title ?? "Unknown",
                        subtitle: item.placemark.title ?? "",
                        coordinate: loc,
                        placeId: String(format: "%.6f,%.6f", loc.latitude, loc.longitude) // placeholder
                    )
                }
                cont.resume(returning: results)
            }
        }
    }
}

struct PlaceResult: Identifiable, Hashable {
    let id: UUID
    let name: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let placeId: String?
}

extension PlaceResult {
    static func == (lhs: PlaceResult, rhs: PlaceResult) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


