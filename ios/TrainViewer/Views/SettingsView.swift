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
    @State private var testResults: String?
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

                #if DEBUG
                Section(header: Text("Debug & Testing")) {
                    Button("Run LocationService Tests") { runLocationServiceTests() }
                    Button("Run All Tests") { runAllTests() }
                    if let testResults = testResults {
                        Text(testResults)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                #endif

                Section(header: Text("Developer & Support")) {
                    Button("Reload Widgets") { WidgetCenter.shared.reloadAllTimelines() }
                    Button("Clear Offline Cache") { clearCache() }
                    Button("Trigger Background Refresh") { BackgroundRefreshService.shared.schedule() }
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
        // App Store review functionality - would be implemented in production
        print("Open App Store review - not implemented in MVP")
    }

    private func reportIssue() {
        // Email support functionality - would be implemented in production
        print("Report issue via email - not implemented in MVP")
    }
    
    #if DEBUG
    private func runLocationServiceTests() {
        Task {
            let report = TestRunner.runLocationServiceTests()
            await MainActor.run {
                testResults = "LocationService: \(report.passedTests)/\(report.totalTests) passed (\(String(format: "%.1f", report.successRate * 100))%)"
            }
        }
    }
    
    private func runAllTests() {
        Task {
            let summary = TestRunner.runAllTests()
            await MainActor.run {
                testResults = summary
            }
            // Also print detailed results to console
            TestRunner.printDetailedTestResults()
        }
    }
    #endif
}