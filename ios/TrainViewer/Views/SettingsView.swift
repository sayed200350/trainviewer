import SwiftUI
import WidgetKit
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = UserSettingsStore.shared
    @State private var campusQuery: String = ""
    @State private var campusResults: [Place] = []
    @State private var homeQuery: String = ""
    @State private var homeResults: [Place] = []
    private let api = TransportAPIFactory.shared.make()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ticket"), footer: Text("Deutschlandticket (Student) is €29.40/month.")) {
                    Picker("Type", selection: $settings.ticketType) {
                        ForEach(TicketType.allCases) { t in
                            Text(String(describing: t.rawValue)).tag(t)
                        }
                    }
                    Toggle("I am a verified student", isOn: $settings.studentVerified)
                    NavigationLink(destination: TicketView()) { Label("Show Ticket", systemImage: "qrcode.viewfinder") }
                    Button("Add to Apple Wallet (URL)") { presentWalletAdd() }
                }

                Section(header: Text("Transport Provider")) {
                    Picker("Preference", selection: $settings.providerPreference) {
                        ForEach(ProviderPreference.allCases) { p in
                            Text(p.rawValue.uppercased()).tag(p)
                        }
                    }
                }

                Section(header: Text("Modes & Privacy")) {
                    Toggle("Exam Period Mode (+5 min buffer)", isOn: $settings.examModeEnabled)
                    Toggle("Energy Saving Mode", isOn: $settings.energySavingMode)
                    Toggle("Night Preference (slower walking)", isOn: $settings.nightModePreference)
                    Toggle("Allow anonymous analytics", isOn: $settings.analyticsEnabled)
                }

                Section(header: Text("Home")) {
                    if let home = settings.homePlace {
                        VStack(alignment: .leading) {
                            Text(home.name).font(.subheadline)
                            Button("Clear Home") { settings.homePlace = nil }
                        }
                    }
                    TextField("Search home address", text: $homeQuery)
                        .onChange(of: homeQuery) { _ in Task { await searchHome() } }
                    if !homeResults.isEmpty {
                        ForEach(homeResults, id: \.self) { place in
                            Button(place.name) { settings.homePlace = place; homeQuery = place.name; homeResults = [] }
                        }
                    }
                }

                Section(header: Text("Campus"), footer: Text("Set your main campus to enable smart suggestions and geofencing.")) {
                    if let campus = settings.campusPlace {
                        VStack(alignment: .leading) {
                            Text(campus.name).font(.subheadline)
                            Button("Clear Campus") { settings.campusPlace = nil }
                        }
                    }
                    TextField("Search campus", text: $campusQuery)
                        .onChange(of: campusQuery) { _ in Task { await searchCampus() } }
                    if !campusResults.isEmpty {
                        ForEach(campusResults, id: \.self) { place in
                            Button(place.name) { settings.campusPlace = place; campusQuery = place.name; campusResults = [] }
                        }
                    }
                }

                Section(header: Text("Developer & Support")) {
                    Button("Reload Widgets") { WidgetCenter.shared.reloadAllTimelines() }
                    Button("Clear Offline Cache") { clearCache() }
                    Button("Trigger Background Refresh") { BackgroundRefreshService.shared.schedule() }
                    Button("Seed Sample Ticket") { seedSampleTicket() }
                    Link("Privacy Policy", destination: AppConstants.privacyPolicyURL)
                    Link("Terms of Service", destination: AppConstants.termsOfServiceURL)
                    Button("Rate App") { openReview() }
                    Button("Report Issue") { reportIssue() }
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Done", action: { dismiss() }) } }
        }
    }

    private func presentWalletAdd() {
        guard let url = URL(string: "https://example.com/path/to/student.pkpass"), let root = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).flatMap({ $0.windows }).first(where: { $0.isKeyWindow })?.rootViewController else { return }
        Task { try? await PassKitService.shared.addPass(from: url, presenting: root) }
    }

    private func searchCampus() async {
        guard !campusQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { campusResults = []; return }
        campusResults = (try? await api.searchLocations(query: campusQuery, limit: 6)) ?? []
    }

    private func searchHome() async {
        guard !homeQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { homeResults = []; return }
        homeResults = (try? await api.searchLocations(query: homeQuery, limit: 6)) ?? []
    }

    private func clearCache() {
        let summaries = SharedStore.shared.loadRouteSummaries()
        OfflineCache.shared.clearAll(routeIds: summaries.map { $0.id })
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func openReview() {
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/idXXXXXXXX?action=write-review") else { return }
        UIApplication.shared.open(url)
    }

    private func reportIssue() {
        let subject = "TrainViewer Support"
        let body = "Please describe your issue here..."
        let to = AppConstants.supportEmail
        let encoded = "mailto:\(to)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject)&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? body)"
        if let url = URL(string: encoded) { UIApplication.shared.open(url) }
    }

    private func seedSampleTicket() {
        // Sample 5-minute valid QR ticket for demo
        let t = Ticket(status: .active,
                       validFrom: Date().addingTimeInterval(-60),
                       expiresAt: Date().addingTimeInterval(300),
                       qrPayload: "DEMO-STUDENT-TICKET-\(UUID().uuidString.prefix(8))",
                       format: .qr)
        TicketService.shared.save(ticket: t)
    }
}