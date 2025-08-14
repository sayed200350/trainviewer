import SwiftUI
import CoreData
import MapKit
import CoreLocation

struct EditRouteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context

    @ObservedObject var route: RouteEntity

    @State private var name: String = ""
    @State private var walkBuffer: Int = 2

	@StateObject private var locationManager = LocationManager()
	@State private var originQuery: String = ""
	@State private var destQuery: String = ""
	@State private var originSelection: PlaceResult?
	@State private var destSelection: PlaceResult?
	@State private var originResults: [PlaceResult] = []
	@State private var destResults: [PlaceResult] = []

    var body: some View {
		Form {
            Section("Name") {
                TextField("Route name", text: $name)
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
        .navigationTitle("Edit Route")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Save", action: save) }
        }
        .onAppear {
            name = route.name
            walkBuffer = Int(route.walkBufferMins)
			originQuery = route.originName
			destQuery = route.destName
        }
    }

    private func save() {
        route.name = name.trimmingCharacters(in: .whitespaces)
        route.walkBufferMins = Int16(walkBuffer)

        if let o = originSelection {
            route.originName = o.name
            route.originLatitude = o.coordinate.latitude
            route.originLongitude = o.coordinate.longitude
            route.originPlaceId = o.placeId
        }
        if let d = destSelection {
            route.destName = d.name
            route.destLatitude = d.coordinate.latitude
            route.destLongitude = d.coordinate.longitude
            route.destPlaceId = d.placeId
        }

        do { try RouteRepository().saveChanges() } catch {}
        // Update shared cache so widget configuration can list updated routes immediately
        let request = NSFetchRequest<RouteEntity>(entityName: "Route")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RouteEntity.createdAt, ascending: false)]
        if let list = try? context.fetch(request) {
            SharedCache.saveRoutes(from: list)
        }
        dismiss()
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


