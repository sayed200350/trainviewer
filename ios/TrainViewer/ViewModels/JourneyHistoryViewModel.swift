import Foundation
import SwiftUI

/// ViewModel for managing journey history and statistics display
@MainActor
final class JourneyHistoryViewModel: ObservableObject {
    @Published private(set) var historyEntries: [JourneyHistoryEntry] = []
    @Published private(set) var statistics: JourneyStatistics?
    @Published private(set) var routeStatistics: [UUID: JourneyStatistics] = [:]
    @Published var selectedTimeRange: TimeRange = .lastMonth
    @Published var selectedRouteId: UUID?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    // Privacy and settings
    @Published var isTrackingEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isTrackingEnabled, forKey: "journey_tracking_enabled")
            if !isTrackingEnabled {
                // Clear current data when tracking is disabled
                historyEntries = []
                statistics = nil
                routeStatistics = [:]
            }
        }
    }
    
    @Published var isAnonymizedExportEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isAnonymizedExportEnabled, forKey: "anonymized_export_enabled")
        }
    }
    
    private let historyService: JourneyHistoryService
    private let settings: UserSettingsStore
    
    init(historyService: JourneyHistoryService = .shared, settings: UserSettingsStore = .shared) {
        self.historyService = historyService
        self.settings = settings
        
        // Load privacy settings
        self.isTrackingEnabled = UserDefaults.standard.bool(forKey: "journey_tracking_enabled")
        self.isAnonymizedExportEnabled = UserDefaults.standard.bool(forKey: "anonymized_export_enabled")
        
        // Set default values if not previously set
        if UserDefaults.standard.object(forKey: "journey_tracking_enabled") == nil {
            self.isTrackingEnabled = true
        }
        if UserDefaults.standard.object(forKey: "anonymized_export_enabled") == nil {
            self.isAnonymizedExportEnabled = true
        }
    }
    
    // MARK: - Data Loading
    
    /// Loads journey history for the selected time range and route
    func loadHistory() async {
        guard isTrackingEnabled else {
            print("📊 [JourneyHistoryViewModel] Journey tracking is disabled")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            if let routeId = selectedRouteId {
                historyEntries = try await historyService.fetchHistory(for: routeId, timeRange: selectedTimeRange)
                statistics = try await historyService.generateRouteStatistics(for: routeId, timeRange: selectedTimeRange)
            } else {
                historyEntries = try await historyService.fetchHistory(for: selectedTimeRange)
                statistics = try await historyService.generateStatistics(for: selectedTimeRange)
            }
            
            print("📊 [JourneyHistoryViewModel] Loaded \(historyEntries.count) history entries")
        } catch {
            errorMessage = "Failed to load journey history: \(error.localizedDescription)"
            print("❌ [JourneyHistoryViewModel] Failed to load history: \(error)")
        }
        
        isLoading = false
    }
    
    /// Loads statistics for all routes
    func loadRouteStatistics(for routes: [Route]) async {
        guard isTrackingEnabled else { return }
        
        var newRouteStatistics: [UUID: JourneyStatistics] = [:]
        
        await withTaskGroup(of: (UUID, JourneyStatistics?).self) { group in
            for route in routes {
                group.addTask { [weak self] in
                    guard let self = self else { return (route.id, nil) }
                    do {
                        let stats = try await self.historyService.generateRouteStatistics(for: route.id, timeRange: self.selectedTimeRange)
                        return (route.id, stats)
                    } catch {
                        print("❌ [JourneyHistoryViewModel] Failed to load stats for route \(route.name): \(error)")
                        return (route.id, nil)
                    }
                }
            }
            
            for await (routeId, stats) in group {
                if let stats = stats {
                    newRouteStatistics[routeId] = stats
                }
            }
        }
        
        routeStatistics = newRouteStatistics
        print("📊 [JourneyHistoryViewModel] Loaded statistics for \(newRouteStatistics.count) routes")
    }
    
    /// Records a new journey entry
    func recordJourney(_ entry: JourneyHistoryEntry) async {
        guard isTrackingEnabled else {
            print("📊 [JourneyHistoryViewModel] Journey tracking is disabled, not recording")
            return
        }
        
        do {
            try await historyService.recordJourney(entry)
            
            // Refresh data if the new entry falls within current view
            if shouldIncludeInCurrentView(entry) {
                await loadHistory()
            }
            
            print("✅ [JourneyHistoryViewModel] Recorded journey for route: \(entry.routeName)")
        } catch {
            errorMessage = "Failed to record journey: \(error.localizedDescription)"
            print("❌ [JourneyHistoryViewModel] Failed to record journey: \(error)")
        }
    }
    
    /// Records a journey from a JourneyOption and Route
    func recordJourneyFromOption(_ option: JourneyOption, route: Route, wasSuccessful: Bool = true) async {
        guard isTrackingEnabled else { return }
        
        do {
            try await historyService.recordJourneyFromOption(option, route: route, wasSuccessful: wasSuccessful)
            
            // Refresh data if needed
            if selectedRouteId == nil || selectedRouteId == route.id {
                await loadHistory()
            }
            
            print("✅ [JourneyHistoryViewModel] Recorded journey from option for route: \(route.name)")
        } catch {
            errorMessage = "Failed to record journey: \(error.localizedDescription)"
            print("❌ [JourneyHistoryViewModel] Failed to record journey from option: \(error)")
        }
    }
    
    // MARK: - Data Management
    
    /// Exports journey history data
    func exportHistory() async -> Data? {
        do {
            if isAnonymizedExportEnabled {
                return try await historyService.exportAnonymizedHistory()
            } else {
                return try await historyService.exportHistory()
            }
        } catch {
            errorMessage = "Failed to export history: \(error.localizedDescription)"
            print("❌ [JourneyHistoryViewModel] Failed to export history: \(error)")
            return nil
        }
    }
    
    /// Clears all journey history
    func clearHistory() async {
        do {
            try await historyService.clearAllHistory()
            historyEntries = []
            statistics = nil
            routeStatistics = [:]
            print("🧹 [JourneyHistoryViewModel] Cleared all journey history")
        } catch {
            errorMessage = "Failed to clear history: \(error.localizedDescription)"
            print("❌ [JourneyHistoryViewModel] Failed to clear history: \(error)")
        }
    }
    
    /// Performs cleanup of old entries
    func performCleanup() async {
        do {
            try await historyService.cleanupOldEntries()
            await loadHistory() // Refresh after cleanup
            print("🧹 [JourneyHistoryViewModel] Performed history cleanup")
        } catch {
            errorMessage = "Failed to cleanup old entries: \(error.localizedDescription)"
            print("❌ [JourneyHistoryViewModel] Failed to cleanup: \(error)")
        }
    }
    
    // MARK: - Filtering and Selection
    
    /// Updates the selected time range and reloads data
    func updateTimeRange(_ timeRange: TimeRange) async {
        selectedTimeRange = timeRange
        await loadHistory()
    }
    
    /// Updates the selected route filter and reloads data
    func updateRouteFilter(_ routeId: UUID?) async {
        selectedRouteId = routeId
        await loadHistory()
    }
    
    /// Clears any error messages
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Computed Properties
    
    /// Filtered history entries based on current selection
    var filteredEntries: [JourneyHistoryEntry] {
        return historyEntries
    }
    
    /// Grouped history entries by date for display
    var groupedEntries: [Date: [JourneyHistoryEntry]] {
        let calendar = Calendar.current
        return Dictionary(grouping: historyEntries) { entry in
            calendar.startOfDay(for: entry.departureTime)
        }
    }
    
    /// Recent journey entries (last 10)
    var recentEntries: [JourneyHistoryEntry] {
        return Array(historyEntries.prefix(10))
    }
    
    /// Statistics summary for display
    var statisticsSummary: StatisticsSummary? {
        guard let stats = statistics else { return nil }
        
        return StatisticsSummary(
            totalJourneys: stats.totalJourneys,
            averageDelay: stats.averageDelayMinutes,
            onTimePercentage: stats.onTimePercentage,
            reliabilityScore: stats.reliabilityScore,
            mostUsedRoute: stats.mostUsedRouteName ?? "N/A",
            peakHours: stats.peakTravelHours
        )
    }
    
    /// Delay distribution for charts
    var delayDistribution: [DelayCategory: Int] {
        let distribution = Dictionary(grouping: historyEntries, by: { $0.delayCategory })
        return distribution.mapValues { $0.count }
    }
    
    /// Weekly travel pattern for charts
    var weeklyPattern: [String: Int] {
        guard let stats = statistics else { return [:] }
        
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var pattern: [String: Int] = [:]
        
        for (index, count) in stats.weeklyPattern.enumerated() {
            pattern[dayNames[index]] = count
        }
        
        return pattern
    }
    
    // MARK: - Privacy and Consent
    
    /// Requests user consent for journey tracking
    func requestTrackingConsent() -> Bool {
        // This would typically show a consent dialog
        // For now, we'll just return the current setting
        return isTrackingEnabled
    }
    
    /// Disables tracking and clears data
    func disableTrackingAndClearData() async {
        isTrackingEnabled = false
        await clearHistory()
    }
    
    // MARK: - Private Helper Methods
    
    private func shouldIncludeInCurrentView(_ entry: JourneyHistoryEntry) -> Bool {
        // Check if entry falls within current time range
        if let dateRange = selectedTimeRange.dateRange {
            guard dateRange.contains(entry.departureTime) else { return false }
        }
        
        // Check if entry matches current route filter
        if let routeId = selectedRouteId {
            return entry.routeId == routeId
        }
        
        return true
    }
}

// MARK: - Supporting Types

struct StatisticsSummary {
    let totalJourneys: Int
    let averageDelay: Double
    let onTimePercentage: Double
    let reliabilityScore: Double
    let mostUsedRoute: String
    let peakHours: [Int]
    
    var formattedAverageDelay: String {
        return String(format: "%.1f min", averageDelay)
    }
    
    var formattedOnTimePercentage: String {
        return String(format: "%.1f%%", onTimePercentage)
    }
    
    var formattedReliabilityScore: String {
        return String(format: "%.1f/5.0", reliabilityScore * 5.0)
    }
    
    var peakHoursText: String {
        if peakHours.isEmpty {
            return "No peak hours"
        }
        
        let hourStrings = peakHours.map { hour in
            let formatter = DateFormatter()
            formatter.dateFormat = "ha"
            let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
            return formatter.string(from: date).lowercased()
        }
        
        return hourStrings.joined(separator: ", ")
    }
}