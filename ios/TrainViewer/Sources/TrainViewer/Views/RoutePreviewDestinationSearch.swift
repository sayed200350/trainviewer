import SwiftUI
import MapKit

struct DestinationSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    @State private var results: [MKMapItem] = []
    let onSelect: (MKMapItem) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                HStack {
                    TextField("Search destination", text: $query)
                        .textFieldStyle(.roundedBorder)
                    Button("Search") { Task { await search() } }
                }
                List(results, id: \.self) { item in
                    Button(action: { onSelect(item); dismiss() }) {
                        VStack(alignment: .leading) {
                            Text(item.name ?? "Destination")
                            Text(item.placemark.title ?? "").font(.footnote).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Choose Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }

    private func search() async {
        guard query.count > 2 else { results = []; return }
        let req = MKLocalSearch.Request(); req.naturalLanguageQuery = query
        let res = try? await MKLocalSearch(request: req).start()
        await MainActor.run { results = res?.mapItems ?? [] }
    }
}


