import SwiftUI
import MapKit
import CoreLocation

struct RoutePreviewPoint: Hashable {
    let name: String
    let coordinate: CLLocationCoordinate2D
}

struct RoutePreviewView: View {
    let origin: RoutePreviewPoint
    let onConfirm: (_ chosenIndex: Int?) -> Void

    @Environment(\.dismiss) private var dismiss
    private let api: TransitAPI = TransitAPIProvider.shared.api
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var departures: [Departure] = []
    @State private var isLoading = true
    @State private var selectedIndex: Int? = 0
    @State private var destinationPoint: RoutePreviewPoint
    @State private var showDestinationSearch = false

    init(origin: RoutePreviewPoint, destination: RoutePreviewPoint, onConfirm: @escaping (_ chosenIndex: Int?) -> Void) {
        self.origin = origin
        self.onConfirm = onConfirm
        _destinationPoint = State(initialValue: destination)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            map
                .frame(height: 220)
            list
            confirmBar
        }
        .task { await load() }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $showDestinationSearch) {
            DestinationSearchSheet { item in
                if let c = item.placemark.location?.coordinate {
                    destinationPoint = RoutePreviewPoint(name: item.name ?? "Destination",
                                                         coordinate: c)
                    Task { await load() }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Route Preview").font(.headline)
                Text("\(origin.name) → \(destinationPoint.name)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button("Change destination") { showDestinationSearch = true }
            Button(action: { dismiss() }) { Image(systemName: "xmark") }
        }
        .padding()
    }

    @ViewBuilder
    private var map: some View {
        if #available(iOS 17.0, *) {
            Map(position: $mapPosition) {
                Annotation(origin.name, coordinate: origin.coordinate) {
                    Circle().fill(.blue).frame(width: 12, height: 12).overlay(Circle().stroke(.white, lineWidth: 2))
                }
                Annotation(destinationPoint.name, coordinate: destinationPoint.coordinate) {
                    Circle().fill(.green).frame(width: 12, height: 12).overlay(Circle().stroke(.white, lineWidth: 2))
                }
                MapPolyline(coordinates: [origin.coordinate, destinationPoint.coordinate])
                    .stroke(.blue.opacity(0.6), lineWidth: 3)
            }
            .onAppear {
                mapPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: (origin.coordinate.latitude + destinationPoint.coordinate.latitude) / 2,
                        longitude: (origin.coordinate.longitude + destinationPoint.coordinate.longitude) / 2
                    ),
                    span: MKCoordinateSpan(latitudeDelta: abs(origin.coordinate.latitude - destinationPoint.coordinate.latitude) * 2 + 0.02,
                                           longitudeDelta: abs(origin.coordinate.longitude - destinationPoint.coordinate.longitude) * 2 + 0.02)
                ))
            }
        } else {
            Map(coordinateRegion: .constant(MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: (origin.coordinate.latitude + destinationPoint.coordinate.latitude) / 2,
                    longitude: (origin.coordinate.longitude + destinationPoint.coordinate.longitude) / 2
                ),
                span: MKCoordinateSpan(latitudeDelta: abs(origin.coordinate.latitude - destinationPoint.coordinate.latitude) * 2 + 0.02,
                                       longitudeDelta: abs(origin.coordinate.longitude - destinationPoint.coordinate.longitude) * 2 + 0.02)
            )))
        }
    }

    private var list: some View {
        Group {
            if isLoading {
                HStack { ProgressView(); Text("Loading options...").foregroundStyle(.secondary) }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if departures.isEmpty {
                Text("No realtime options found. You can still save the route.")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                List(Array(departures.enumerated()), id: \.offset) { idx, d in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Image(systemName: "tram.fill").foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            let leaveIn = max(0, Int(d.departureTime.timeIntervalSinceNow / 60))
                            let duration = max(0, Int(d.arrivalTime.timeIntervalSince(d.departureTime) / 60))
                            Text("Leave in \(leaveIn) min")
                                .font(.headline)
                            Text("Duration \(duration) min • \(formatted(d.departureTime)) → \(formatted(d.arrivalTime))")
                                .foregroundStyle(.secondary)
                            if let p = d.platform { Text("Platform \(p)").font(.footnote).foregroundStyle(.secondary) }
                        }
                        Spacer()
                        if selectedIndex == idx { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedIndex = idx }
                }
                .listStyle(.inset)
            }
        }
    }

    private var confirmBar: some View {
        HStack {
            Button("Back") { dismiss() }
            Spacer()
            Button("Use This Route") {
                onConfirm(selectedIndex)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }

    private func load() async {
        isLoading = true
        let list = (try? await api.fetchNextDepartures(origin: origin.coordinate, destination: destinationPoint.coordinate, limit: 3)) ?? []
        await MainActor.run {
            self.departures = list
            self.isLoading = false
        }
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: date)
    }
}


