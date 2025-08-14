import SwiftUI
import MapKit
import UserNotifications

struct OnboardingFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page: Int = 0

    var body: some View {
        TabView(selection: $page) {
            WelcomeSlide().tag(0)
            PermissionsSlide().tag(1)
            UniversitySlide().tag(2)
            WidgetSlide(onDone: finish).tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .background(Color(UIColor.systemBackground))
    }

    private func finish() {
        OnboardingManager.shared.markCompleted()
        dismiss()
    }
}

private struct WelcomeSlide: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tram.fill").font(.system(size: 56)).foregroundStyle(.blue)
            Text("Turn rejection into resilience")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("Never miss your train again. Real-time departures, disruption alerts, and beautiful widgets.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Spacer()
            Text("Swipe to continue →").foregroundStyle(.secondary)
            Spacer(minLength: 20)
        }
        .padding()
    }
}

private struct PermissionsSlide: View {
    @StateObject private var loc = LocationManager()
    @State private var notifGranted: Bool = false
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Permissions").font(.title.bold())
            Text("We use your location to show nearby stations and send timely reminders.")
                .foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Enable Location") {
                if loc.authorizationStatus == .notDetermined { loc.requestWhenInUseAuthorization() }
            }
            .buttonStyle(.borderedProminent)
            Button(notifGranted ? "Notifications Enabled" : "Enable Notifications") {
                Task {
                    let ok = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                    await MainActor.run { notifGranted = (ok ?? false) }
                }
            }
            .buttonStyle(.bordered)
            .disabled(notifGranted)
            Spacer()
        }
        .padding()
    }
}

private struct UniversitySlide: View {
    @State private var query = ""
    @State private var results: [MKMapItem] = []
    @State private var selected: MKMapItem?
    let popular = ["TU Munich", "Humboldt Berlin", "Uni Frankfurt", "RWTH Aachen"]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your University").font(.title.bold())
            HStack {
                TextField("Search universities", text: $query)
                    .textFieldStyle(.roundedBorder)
                Button("Search") { Task { await search() } }
            }
            if !results.isEmpty {
                List(results, id: \.self, selection: .constant(nil)) {
                    item in
                    Button(action: { select(item) }) {
                        VStack(alignment: .leading) {
                            Text(item.name ?? "University")
                            Text(item.placemark.title ?? "").font(.footnote).foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 200)
            }
            Text("Popular").font(.headline)
            ForEach(popular, id: \.self) { u in
                Button(u) { selectName(u) }
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let chosen = selected {
                Text("Selected: \(chosen.name ?? "")").foregroundStyle(.secondary)
            } else if let name = AppPreferences.shared.universityName {
                Text("Selected: \(name)").foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
    }

    private func search() async {
        guard query.count > 2 else { results = []; return }
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = query
        let res = try? await MKLocalSearch(request: req).start()
        await MainActor.run { results = res?.mapItems ?? [] }
    }

    private func select(_ item: MKMapItem) {
        selected = item
        AppPreferences.shared.universityName = item.name
        if let c = item.placemark.location?.coordinate {
            AppPreferences.shared.universityLocation = (c.latitude, c.longitude)
        }
    }

    private func selectName(_ name: String) {
        AppPreferences.shared.universityName = name
        selected = nil
    }
}

private struct WidgetSlide: View {
    let onDone: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Widgets").font(.title.bold())
            Text("Add widgets to your home screen for instant departure times.")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Done", action: onDone)
                .buttonStyle(.borderedProminent)
            Spacer(minLength: 20)
        }
        .padding()
    }
}


