import Foundation

/// Manager for handling privacy settings and data protection
final class PrivacyManager {
    static let shared = PrivacyManager()
    
    private let userDefaults = UserDefaults.standard
    
    // Privacy setting keys
    private enum PrivacyKeys {
        static let journeyTrackingConsent = "journey_tracking_consent"
        static let journeyTrackingEnabled = "journey_tracking_enabled"
        static let anonymizedExportEnabled = "anonymized_export_enabled"
        static let dataRetentionMonths = "data_retention_months"
        static let consentVersion = "privacy_consent_version"
        static let consentDate = "privacy_consent_date"
    }
    
    // Current privacy policy version
    private let currentConsentVersion = "1.0"
    
    init() {
        // Perform migration if needed
        migratePrivacySettingsIfNeeded()
    }
    
    // MARK: - Consent Management
    
    /// Whether the user has provided consent for journey tracking
    var hasJourneyTrackingConsent: Bool {
        get {
            return userDefaults.bool(forKey: PrivacyKeys.journeyTrackingConsent)
        }
        set {
            userDefaults.set(newValue, forKey: PrivacyKeys.journeyTrackingConsent)
            if newValue {
                userDefaults.set(currentConsentVersion, forKey: PrivacyKeys.consentVersion)
                userDefaults.set(Date(), forKey: PrivacyKeys.consentDate)
            }
            print("🔒 [PrivacyManager] Journey tracking consent: \(newValue)")
        }
    }
    
    /// Whether journey tracking is currently enabled
    var isJourneyTrackingEnabled: Bool {
        get {
            return hasJourneyTrackingConsent && userDefaults.bool(forKey: "journey_tracking_enabled")
        }
        set {
            guard hasJourneyTrackingConsent else {
                print("⚠️ [PrivacyManager] Cannot enable tracking without consent")
                return
            }
            userDefaults.set(newValue, forKey: "journey_tracking_enabled")
            print("🔒 [PrivacyManager] Journey tracking enabled: \(newValue)")
        }
    }
    
    /// Whether anonymized export is enabled
    var isAnonymizedExportEnabled: Bool {
        get {
            return userDefaults.bool(forKey: "anonymized_export_enabled")
        }
        set {
            userDefaults.set(newValue, forKey: "anonymized_export_enabled")
            print("🔒 [PrivacyManager] Anonymized export enabled: \(newValue)")
        }
    }
    
    /// Data retention period in months
    var dataRetentionMonths: Int {
        get {
            let months = userDefaults.integer(forKey: "data_retention_months")
            return months > 0 ? months : 12 // Default to 12 months
        }
        set {
            userDefaults.set(max(1, min(36, newValue)), forKey: "data_retention_months") // Limit between 1-36 months
            print("🔒 [PrivacyManager] Data retention set to \(newValue) months")
        }
    }
    
    /// Date when consent was given
    var consentDate: Date? {
        return userDefaults.object(forKey: PrivacyKeys.consentDate) as? Date
    }
    
    /// Version of consent that was agreed to
    var consentVersion: String? {
        return userDefaults.string(forKey: PrivacyKeys.consentVersion)
    }
    
    /// Whether consent needs to be updated due to policy changes
    var needsConsentUpdate: Bool {
        guard let version = consentVersion else { return true }
        return version != currentConsentVersion
    }
    
    // MARK: - Consent Actions
    
    /// Requests user consent for journey tracking
    func requestJourneyTrackingConsent() async -> Bool {
        // In a real implementation, this would show a consent dialog
        // For now, we'll simulate the consent process
        
        print("🔒 [PrivacyManager] Requesting journey tracking consent")
        
        // This would typically present a UI dialog explaining:
        // - What data is collected
        // - How it's used
        // - User's rights
        // - Data retention policy
        
        // For implementation purposes, we'll assume consent is granted
        // In a real app, this would wait for user interaction
        
        hasJourneyTrackingConsent = true
        isJourneyTrackingEnabled = true
        isAnonymizedExportEnabled = true
        
        return hasJourneyTrackingConsent
    }
    
    /// Revokes consent and clears all tracking data
    func revokeConsent() async {
        print("🔒 [PrivacyManager] Revoking journey tracking consent")
        
        hasJourneyTrackingConsent = false
        userDefaults.removeObject(forKey: "journey_tracking_enabled")
        userDefaults.removeObject(forKey: PrivacyKeys.consentVersion)
        userDefaults.removeObject(forKey: PrivacyKeys.consentDate)
        
        // Clear all journey history data
        do {
            try await SimpleJourneyHistoryService.shared.clearAllHistory()
            print("🧹 [PrivacyManager] Cleared all journey history data")
        } catch {
            print("❌ [PrivacyManager] Failed to clear journey history: \(error)")
        }
    }
    
    /// Updates consent to the current version
    func updateConsent() async -> Bool {
        guard hasJourneyTrackingConsent else {
            return await requestJourneyTrackingConsent()
        }
        
        // Update to current version
        userDefaults.set(currentConsentVersion, forKey: PrivacyKeys.consentVersion)
        userDefaults.set(Date(), forKey: PrivacyKeys.consentDate)
        
        print("🔒 [PrivacyManager] Updated consent to version \(currentConsentVersion)")
        return true
    }
    
    // MARK: - Data Protection
    
    /// Anonymizes journey history data (placeholder implementation)
    func anonymizeHistoryData() -> String {
        return "Anonymized journey data would be processed here"
    }
    
    /// Encrypts sensitive data (placeholder implementation)
    func encryptSensitiveData(_ data: Data) throws -> Data {
        // In a real implementation, this would use proper encryption
        // For now, we'll just return the data as-is
        print("🔒 [PrivacyManager] Encrypting sensitive data (\(data.count) bytes)")
        return data
    }
    
    /// Decrypts sensitive data (placeholder implementation)
    func decryptSensitiveData(_ encryptedData: Data) throws -> Data {
        // In a real implementation, this would use proper decryption
        // For now, we'll just return the data as-is
        print("🔒 [PrivacyManager] Decrypting sensitive data (\(encryptedData.count) bytes)")
        return encryptedData
    }
    
    /// Clears all private data
    func clearPrivateData() async {
        print("🧹 [PrivacyManager] Clearing all private data")
        
        do {
            try await SimpleJourneyHistoryService.shared.clearAllHistory()
        } catch {
            print("❌ [PrivacyManager] Failed to clear journey history: \(error)")
        }
        
        // Clear other private data as needed
        // This could include cached location data, search history, etc.
    }
    
    // MARK: - Privacy Information
    
    /// Gets a summary of what data is collected
    func getDataCollectionSummary() -> DataCollectionSummary {
        return DataCollectionSummary(
            journeyHistory: isJourneyTrackingEnabled,
            locationData: true, // Location is always used for walking time calculations
            routePreferences: true, // Route configurations are always stored
            usageStatistics: isJourneyTrackingEnabled,
            crashReports: false, // Not implemented in this version
            analytics: false // Not implemented in this version
        )
    }
    
    /// Gets user's privacy rights information
    func getPrivacyRights() -> PrivacyRights {
        return PrivacyRights(
            canAccessData: true,
            canExportData: true,
            canDeleteData: true,
            canRevokeConsent: true,
            canRequestAnonymization: true,
            dataRetentionPeriod: dataRetentionMonths
        )
    }
    
    // MARK: - Migration
    
    private func migratePrivacySettingsIfNeeded() {
        // Check if this is a first-time setup
        if userDefaults.object(forKey: PrivacyKeys.journeyTrackingConsent) == nil {
            // Set default values for new installations
            isAnonymizedExportEnabled = true
            dataRetentionMonths = 12
            
            print("🔒 [PrivacyManager] Initialized privacy settings with defaults")
        }
        
        // Check if consent needs to be updated
        if needsConsentUpdate && hasJourneyTrackingConsent {
            print("🔒 [PrivacyManager] Consent update needed (current: \(consentVersion ?? "none"), required: \(currentConsentVersion))")
        }
    }
}

// MARK: - Supporting Types

struct DataCollectionSummary {
    let journeyHistory: Bool
    let locationData: Bool
    let routePreferences: Bool
    let usageStatistics: Bool
    let crashReports: Bool
    let analytics: Bool
    
    var collectedDataTypes: [String] {
        var types: [String] = []
        
        if journeyHistory { types.append("Journey History") }
        if locationData { types.append("Location Data") }
        if routePreferences { types.append("Route Preferences") }
        if usageStatistics { types.append("Usage Statistics") }
        if crashReports { types.append("Crash Reports") }
        if analytics { types.append("Analytics") }
        
        return types
    }
}

struct PrivacyRights {
    let canAccessData: Bool
    let canExportData: Bool
    let canDeleteData: Bool
    let canRevokeConsent: Bool
    let canRequestAnonymization: Bool
    let dataRetentionPeriod: Int
    
    var rightsDescription: [String] {
        var rights: [String] = []
        
        if canAccessData { rights.append("Access your data") }
        if canExportData { rights.append("Export your data") }
        if canDeleteData { rights.append("Delete your data") }
        if canRevokeConsent { rights.append("Revoke consent") }
        if canRequestAnonymization { rights.append("Request data anonymization") }
        
        rights.append("Data is retained for \(dataRetentionPeriod) months")
        
        return rights
    }
}