import Foundation
import SwiftUI

/// Simplified ViewModel for basic journey history functionality
@MainActor
final class SimpleJourneyHistoryViewModel: ObservableObject {
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    // Privacy and settings
    @Published var isTrackingEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isTrackingEnabled, forKey: "journey_tracking_enabled")
        }
    }
    
    @Published var isAnonymizedExportEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isAnonymizedExportEnabled, forKey: "anonymized_export_enabled")
        }
    }
    
    private let historyService: SimpleJourneyHistoryService
    private let settings: UserSettingsStore
    
    init(historyService: SimpleJourneyHistoryService = .shared, settings: UserSettingsStore = .shared) {
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
    
    /// Records a journey from a JourneyOption and Route
    func recordJourneyFromOption(_ option: JourneyOption, route: Route, wasSuccessful: Bool = true) async {
        guard isTrackingEnabled else {
            print("📊 [SimpleJourneyHistoryViewModel] Journey tracking is disabled, not recording")
            return
        }
        
        do {
            try await historyService.recordJourneyFromOption(option, route: route, wasSuccessful: wasSuccessful)
            print("✅ [SimpleJourneyHistoryViewModel] Recorded journey from option for route: \(route.name)")
        } catch {
            errorMessage = "Failed to record journey: \(error.localizedDescription)"
            print("❌ [SimpleJourneyHistoryViewModel] Failed to record journey from option: \(error)")
        }
    }
    
    /// Clears all journey history
    func clearHistory() async {
        do {
            try await historyService.clearAllHistory()
            print("🧹 [SimpleJourneyHistoryViewModel] Cleared all journey history")
        } catch {
            errorMessage = "Failed to clear history: \(error.localizedDescription)"
            print("❌ [SimpleJourneyHistoryViewModel] Failed to clear history: \(error)")
        }
    }
    
    /// Clears any error messages
    func clearError() {
        errorMessage = nil
    }
    
    /// Disables tracking and clears data
    func disableTrackingAndClearData() async {
        isTrackingEnabled = false
        await clearHistory()
    }
}