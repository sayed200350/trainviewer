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

    // Search state management
    @State private var isSearchingHome = false
    @State private var isSearchingCampus = false
    @State private var homeSearchError: String?
    @State private var campusSearchError: String?
    @State private var homeSearchTask: Task<Void, Never>?
    @State private var campusSearchTask: Task<Void, Never>?

    // Semester ticket state
    @State private var showSemesterTicketSetup = false

    private let api = TransportAPIFactory.shared.make()
    private let searchDebounceSeconds = 0.5
    private let minimumSearchCharacters = 2

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Semesterticket")) {
                    NavigationLink(destination: SemesterTicketListView()) {
                        HStack {
                            Text("Meine Semestertickets")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    NavigationLink(destination: SemesterTicketNotificationSettingsView()) {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(.brandBlue)
                            Text("Erinnerungen für Verlängerung")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: {
                        // Navigate to setup view
                        showSemesterTicketSetup = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.brandBlue)
                            Text("Semesterticket hinzufügen")
                                .foregroundColor(.brandBlue)
                            Spacer()
                        }
                    }
                }

                Section(header: Text("Timing Preferences")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preparation Buffer")
                            .font(.headline)
                        Text("Extra time added to walking calculations (minutes)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Stepper(value: $settings.preparationBufferMinutes, in: 0...30, step: 1) {
                        HStack {
                            Text("\(settings.preparationBufferMinutes) minutes")
                            Spacer()
                            if settings.preparationBufferMinutes == 0 {
                                Text("No buffer")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section(header: Text("Transport Provider")) {
                    Picker("Preference", selection: $settings.providerPreference) {
                        ForEach(ProviderPreference.allCases) { p in
                            Text(p.rawValue.uppercased()).tag(p)
                        }
                    }
                }


                Section(header: Text("Home")) {
                    if let home = settings.homePlace {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(home.name)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Button("Clear Home") {
                                settings.homePlace = nil
                                homeQuery = ""
                                homeResults = []
                                homeSearchError = nil
                            }
                            .foregroundColor(.red)
                            .font(.caption)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("Search home address (street, city, etc.)", text: $homeQuery)
                                .onChange(of: homeQuery) { oldValue, newValue in
                                    handleHomeQueryChange(from: oldValue, to: newValue)
                                }

                            if isSearchingHome {
                                ProgressView()
                                    .frame(width: 20, height: 20)
                            }
                        }

                        if let error = homeSearchError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        if homeQuery.count < minimumSearchCharacters && !homeQuery.isEmpty {
                            Text("Type at least \(minimumSearchCharacters) characters to search")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if !homeResults.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(homeResults, id: \.self) { place in
                                    Button(action: {
                                        selectHomePlace(place)
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(place.name)
                                                    .foregroundColor(.primary)
                                                    .font(.subheadline)
                                                if let coordinates = place.coordinatesString {
                                                    Text(coordinates)
                                                        .foregroundColor(.secondary)
                                                        .font(.caption2)
                                                }
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                        }
                                        .padding(.vertical, 8)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                            .padding(.top, 4)
                        }
                    }
                }

                Section(header: Text("Campus"), footer: Text("Set your main campus to enable smart suggestions and geofencing.")) {
                    if let campus = settings.campusPlace {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(campus.name)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Button("Clear Campus") {
                                settings.campusPlace = nil
                                campusQuery = ""
                                campusResults = []
                                campusSearchError = nil
                            }
                            .foregroundColor(.red)
                            .font(.caption)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("Search campus (university, school, etc.)", text: $campusQuery)
                                .onChange(of: campusQuery) { oldValue, newValue in
                                    handleCampusQueryChange(from: oldValue, to: newValue)
                                }

                            if isSearchingCampus {
                                ProgressView()
                                    .frame(width: 20, height: 20)
                            }
                        }

                        if let error = campusSearchError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        if campusQuery.count < minimumSearchCharacters && !campusQuery.isEmpty {
                            Text("Type at least \(minimumSearchCharacters) characters to search")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if !campusResults.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(campusResults, id: \.self) { place in
                                    Button(action: {
                                        selectCampusPlace(place)
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(place.name)
                                                    .foregroundColor(.primary)
                                                    .font(.subheadline)
                                                if let coordinates = place.coordinatesString {
                                                    Text(coordinates)
                                                        .foregroundColor(.secondary)
                                                        .font(.caption2)
                                                }
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                        }
                                        .padding(.vertical, 8)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                            .padding(.top, 4)
                        }
                    }
                }

                Section(header: Text("Smart Widget")) {
                    Toggle("Enable Smart Route Switching", isOn: Binding(
                        get: { UserDefaults(suiteName: "group.com.bahnblitz.app")?.bool(forKey: "smartWidget.smartSwitchingEnabled") ?? true },
                        set: { UserDefaults(suiteName: "group.com.bahnblitz.app")?.set($0, forKey: "smartWidget.smartSwitchingEnabled") }
                    ))

                    Toggle("Use Time-Based Fallback", isOn: Binding(
                        get: { UserDefaults(suiteName: "group.com.bahnblitz.app")?.bool(forKey: "smartWidget.useTimeBasedFallback") ?? true },
                        set: { UserDefaults(suiteName: "group.com.bahnblitz.app")?.set($0, forKey: "smartWidget.useTimeBasedFallback") }
                    ))

                    Toggle("Vacation Mode", isOn: Binding(
                        get: { UserDefaults(suiteName: "group.com.bahnblitz.app")?.bool(forKey: "smartWidget.vacationMode") ?? false },
                        set: { UserDefaults(suiteName: "group.com.bahnblitz.app")?.set($0, forKey: "smartWidget.vacationMode") }
                    ))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location Sensitivity")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Slider(value: Binding(
                            get: { UserDefaults(suiteName: "group.com.bahnblitz.app")?.double(forKey: "smartWidget.locationSensitivity") ?? 1.0 },
                            set: { UserDefaults(suiteName: "group.com.bahnblitz.app")?.set($0, forKey: "smartWidget.locationSensitivity") }
                        ), in: 0.5...2.0, step: 0.1)

                        let sensitivity = UserDefaults(suiteName: "group.com.bahnblitz.app")?.double(forKey: "smartWidget.locationSensitivity") ?? 1.0
                        let radiusText = sensitivity < 1.0 ? "Smaller detection zones" :
                                        sensitivity > 1.0 ? "Larger detection zones" : "Normal detection zones"

                        Text(radiusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    NavigationLink(destination: SmartWidgetWeekdaySettingsView()) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text("Weekday Route Preferences")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button("Reset Smart Widget Settings") {
                        resetSmartWidgetSettings()
                    }
                    .foregroundColor(.red)
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
                    Button("Test Widget Data Flow") { testWidgetDataFlow() }
                    Button("Clear Offline Cache") { clearCache() }
                    Button("Trigger Background Refresh") {
                        #if APP_EXTENSION
                        Task { await ExtensionBackgroundRefreshService.shared.triggerManualRefresh() }
                        #else
                        // For main app, we need to handle this differently since factory might not be available
                        // This button will be disabled in main app for now
                        print("Background refresh not available in this context")
                        #endif
                    }
                    Link("Privacy Policy", destination: AppConstants.privacyPolicyURL)
                    Link("Terms of Service", destination: AppConstants.termsOfServiceURL)
                    Button("Rate App") { openReview() }
                    Button("Report Issue") { reportIssue() }
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Done", action: { dismiss() }) } }
            .sheet(isPresented: $showSemesterTicketSetup) {
                SemesterTicketSetupView()
            }
        }
    }

    // MARK: - Search Handlers
    private func handleHomeQueryChange(from oldValue: String, to newValue: String) {
        // Cancel previous search task
        homeSearchTask?.cancel()
        homeSearchError = nil

        // Clear results if query is empty
        if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            homeResults = []
            return
        }

        // Don't search if too short
        if newValue.count < minimumSearchCharacters {
            homeResults = []
            return
        }

        // Debounce search
        homeSearchTask = Task {
            try? await Task.sleep(for: .seconds(searchDebounceSeconds))
            if !Task.isCancelled {
                await performHomeSearch()
            }
        }
    }

    private func handleCampusQueryChange(from oldValue: String, to newValue: String) {
        // Cancel previous search task
        campusSearchTask?.cancel()
        campusSearchError = nil

        // Clear results if query is empty
        if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            campusResults = []
            return
        }

        // Don't search if too short
        if newValue.count < minimumSearchCharacters {
            campusResults = []
            return
        }

        // Debounce search
        campusSearchTask = Task {
            try? await Task.sleep(for: .seconds(searchDebounceSeconds))
            if !Task.isCancelled {
                await performCampusSearch()
            }
        }
    }

    private func performHomeSearch() async {
        guard !homeQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        await MainActor.run {
            isSearchingHome = true
            homeSearchError = nil
        }

        do {
            let results = try await api.searchLocations(query: homeQuery, limit: 8)
            await MainActor.run {
                homeResults = results
                isSearchingHome = false
                if results.isEmpty {
                    homeSearchError = "No results found. Try a different search term."
                }
            }
        } catch {
            await MainActor.run {
                isSearchingHome = false
                homeSearchError = "Search failed. Please check your connection."
                homeResults = []
            }
        }
    }

    private func performCampusSearch() async {
        guard !campusQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        await MainActor.run {
            isSearchingCampus = true
            campusSearchError = nil
        }

        do {
            let results = try await api.searchLocations(query: campusQuery, limit: 8)
            await MainActor.run {
                campusResults = results
                isSearchingCampus = false
                if results.isEmpty {
                    campusSearchError = "No results found. Try a different search term."
                }
            }
        } catch {
            await MainActor.run {
                isSearchingCampus = false
                campusSearchError = "Search failed. Please check your connection."
                campusResults = []
            }
        }
    }

    // MARK: - Selection Handlers
    private func selectHomePlace(_ place: Place) {
        settings.homePlace = place
        homeQuery = place.name
        homeResults = []
        homeSearchError = nil
        homeSearchTask?.cancel()
    }

    private func selectCampusPlace(_ place: Place) {
        settings.campusPlace = place
        campusQuery = place.name
        campusResults = []
        campusSearchError = nil
        campusSearchTask?.cancel()
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

    private func testWidgetDataFlow() {
        // Test the SharedStore data flow for widgets
        print("🧪 SETTINGS: Testing widget data flow...")

        // Test saving a sample snapshot
        let sampleSnapshot = WidgetSnapshot(
            routeId: UUID(),
            routeName: "Test Route",
            leaveInMinutes: 15,
            departure: Date().addingTimeInterval(900),
            arrival: Date().addingTimeInterval(2700),
            walkingTime: 8 // Sample walking time for test
        )

        SharedStore.shared.save(snapshot: sampleSnapshot)
        print("🧪 SETTINGS: Sample snapshot saved")

        // Test loading it back
        if let loadedSnapshot = SharedStore.shared.loadSnapshot() {
            print("✅ SETTINGS: Snapshot loaded successfully: \(loadedSnapshot.routeName)")
        } else {
            print("❌ SETTINGS: Failed to load snapshot")
        }

        // Reload widget timelines
        WidgetCenter.shared.reloadAllTimelines()
        print("🔄 SETTINGS: Widget timelines reloaded")
    }

    private func resetSmartWidgetSettings() {
        let defaults = UserDefaults(suiteName: "group.com.bahnblitz.app")

        // Reset all smart widget settings to defaults
        defaults?.set(true, forKey: "smartWidget.smartSwitchingEnabled")
        defaults?.set(true, forKey: "smartWidget.useTimeBasedFallback")
        defaults?.set(false, forKey: "smartWidget.vacationMode")
        defaults?.set(1.0, forKey: "smartWidget.locationSensitivity")
        defaults?.removeObject(forKey: "smartWidget.manualRouteOverride")
        defaults?.removeObject(forKey: "smartWidget.weekdayRoutes")

        // Reload widgets to apply changes
        WidgetCenter.shared.reloadAllTimelines()

        print("🔄 SETTINGS: Smart widget settings reset to defaults")
    }
}

// MARK: - Smart Widget Weekday Settings View
struct SmartWidgetWeekdaySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var weekdayRoutes: [String: UUID] = [:]
    @State private var routes: [Route] = []

    private let dayNames = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    private let displayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    var body: some View {
        List {
            Section(header: Text("Weekday Route Preferences"),
                   footer: Text("Set specific routes for each day of the week. If no route is set for a day, the smart widget will use its regular logic.")) {

                ForEach(0..<dayNames.count, id: \.self) { index in
                    let dayName = dayNames[index]
                    let displayName = displayNames[index]

                    NavigationLink(destination: RouteSelectionView(
                        selectedRouteId: weekdayRoutes[dayName],
                        dayName: displayName,
                        onRouteSelected: { routeId in
                            weekdayRoutes[dayName] = routeId
                            saveWeekdayRoutes()
                        }
                    )) {
                        HStack {
                            Text(displayName)
                            Spacer()
                            if let routeId = weekdayRoutes[dayName],
                               let route = routes.first(where: { $0.id == routeId }) {
                                Text(route.name)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            } else {
                                Text("Auto")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                Button("Clear All Weekday Preferences") {
                    weekdayRoutes.removeAll()
                    saveWeekdayRoutes()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Weekday Routes")
        .navigationBarItems(trailing: Button("Done") { dismiss() })
        .onAppear {
            loadWeekdayRoutes()
            loadRoutes()
        }
    }

    private func loadWeekdayRoutes() {
        let defaults = UserDefaults(suiteName: "group.com.bahnblitz.app")
        if let data = defaults?.data(forKey: "smartWidget.weekdayRoutes") {
            weekdayRoutes = (try? JSONDecoder().decode([String: UUID].self, from: data)) ?? [:]
        }
    }

    private func saveWeekdayRoutes() {
        let defaults = UserDefaults(suiteName: "group.com.bahnblitz.app")
        if let data = try? JSONEncoder().encode(weekdayRoutes) {
            defaults?.set(data, forKey: "smartWidget.weekdayRoutes")
        }

        // Reload widgets to apply changes
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func loadRoutes() {
        // Load routes from SharedStore
        let defaults = UserDefaults(suiteName: "group.com.bahnblitz.app")
        if let data = defaults?.data(forKey: "routes") {
            routes = (try? JSONDecoder().decode([Route].self, from: data)) ?? []
        }
    }
}

// MARK: - Route Selection View
struct RouteSelectionView: View {
    let selectedRouteId: UUID?
    let dayName: String
    let onRouteSelected: (UUID?) -> Void

    @State private var routes: [Route] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section(header: Text("Select Route for \(dayName)")) {
                Button(action: {
                    onRouteSelected(nil)
                    dismiss()
                }) {
                    HStack {
                        Text("Auto (Smart Detection)")
                        Spacer()
                        if selectedRouteId == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }

                ForEach(routes, id: \.id) { route in
                    Button(action: {
                        onRouteSelected(route.id)
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(route.name)
                                    .font(.headline)
                                Text("\(route.origin.name) → \(route.destination.name)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedRouteId == route.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("\(dayName) Route")
        .onAppear {
            loadRoutes()
        }
    }

    private func loadRoutes() {
        let defaults = UserDefaults(suiteName: "group.com.bahnblitz.app")
        if let data = defaults?.data(forKey: "routes") {
            routes = (try? JSONDecoder().decode([Route].self, from: data)) ?? []
        }
    }
}