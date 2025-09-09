import Testing
import Foundation
@testable import TrainViewer

struct PrivacyManagerTests {
    
    // MARK: - Setup and Teardown
    
    private func clearUserDefaults() {
        let keys = [
            "journey_tracking_consent",
            "journey_tracking_enabled", 
            "anonymized_export_enabled",
            "data_retention_months",
            "privacy_consent_version",
            "privacy_consent_date"
        ]
        
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    // MARK: - Initialization Tests
    
    @Test("PrivacyManager is a singleton")
    func testSingletonPattern() async throws {
        let manager1 = PrivacyManager.shared
        let manager2 = PrivacyManager.shared
        
        #expect(manager1 === manager2)
    }
    
    @Test("PrivacyManager initializes with default values for new installation")
    func testInitializationDefaults() async throws {
        clearUserDefaults()
        
        let manager = PrivacyManager()
        
        #expect(manager.hasJourneyTrackingConsent == false)
        #expect(manager.isJourneyTrackingEnabled == false)
        #expect(manager.isAnonymizedExportEnabled == true)
        #expect(manager.dataRetentionMonths == 12)
        #expect(manager.consentDate == nil)
        #expect(manager.consentVersion == nil)
        #expect(manager.needsConsentUpdate == true)
    }
    
    // MARK: - Consent Management Tests
    
    @Test("PrivacyManager handles journey tracking consent correctly")
    func testJourneyTrackingConsent() async throws {
        clearUserDefaults()
        let manager = PrivacyManager()
        
        // Initially no consent
        #expect(manager.hasJourneyTrackingConsent == false)
        
        // Grant consent
        manager.hasJourneyTrackingConsent = true
        
        #expect(manager.hasJourneyTrackingConsent == true)
        #expect(manager.consentDate != nil)
        #expect(manager.consentVersion == "1.0")
        #expect(manager.needsConsentUpdate == false)
    }
    
    @Test("PrivacyManager prevents enabling tracking without consent")
    func testTrackingWithoutConsent() async throws {
        clearUserDefaults()
        let manager = PrivacyManager()
        
        // Try to enable tracking without consent
        manager.isJourneyTrackingEnabled = true
        
        #expect(manager.isJourneyTrackingEnabled == false)
    }
    
    @Test("PrivacyManager allows enabling tracking with consent")
    func testTrackingWithConsent() async throws {
        clearUserDefaults()
        let manager = PrivacyManager()
        
        // Grant consent first
        manager.hasJourneyTrackingConsent = true
        
        // Now enable tracking
        manager.isJourneyTrackingEnabled = true
        
        #expect(manager.isJourneyTrackingEnabled == true)
    }
    
    @Test("PrivacyManager handles anonymized export setting")
    func testAnonymizedExportSetting() async throws {
        clearUserDefaults()
        let manager = PrivacyManager()
        
        #expect(manager.isAnonymizedExportEnabled == true) // Default
        
        manager.isAnonymizedExportEnabled = false
        #expect(manager.isAnonymizedExportEnabled == false)
        
        manager.isAnonymizedExportEnabled = true
        #expect(manager.isAnonymizedExportEnabled == true)
    }
    
    @Test("PrivacyManager handles data retention period")
    func testDataRetentionPeriod() async throws {
        clearUserDefaults()
        let manager = PrivacyManager()
        
        #expect(manager.dataRetentionMonths == 12) // Default
        
        // Test valid range
        manager.dataRetentionMonths = 6
        #expect(manager.dataRetentionMonths == 6)
        
        manager.dataRetentionMonths = 24
        #expect(manager.dataRetentionMonths == 24)
        
        // Test boundary conditions
        manager.dataRetentionMonths = 0 // Should be clamped to 1
        #expect(manager.dataRetentionMonths == 1)
        
        manager.dataRetentionMonths = 50 // Should be clamped to 36
        #expect(manager.dataRetentionMonths == 36)
        
        manager.dataRetentionMonths = -5 // Should be clamped to 1
        #expect(manager.dataRetentionMonths == 1)
    }
    
    // MARK: - Consent Actions Tests
    
    @Test("PrivacyManager requests journey tracking consent")
    func testRequestJourneyTrackingConsent() async throws {
        clearUserDefaults()
        let manager = PrivacyManager()
        
        let consentGranted = await manager.requestJourneyTrackingConsent()
        
        #expect(consentGranted == true)
        #expect(manager.hasJourneyTrackingConsent == true)
        #expect(manager.isJourneyTrackingEnabled == true)
        #expect(manager.isAnonymizedExportEnabled == true)
        #expect(manager.consentDate != nil)
        #expect(manager.consentVersion == "1.0")
    }
    
    @Test("PrivacyManager revokes consent and clears data")
    func testRevokeConsent() async throws {
        clearUserDefaults()
        let manager = PrivacyManager()
        
        // First grant consent
        manager.hasJourneyTrackingConsent = true
        manager.isJourneyTrackingEnabled = true
        
        // Then revoke it
        await manager.revokeConsent()
        
        #expect(manager.hasJourneyTrackingConsent == false)
        #expect(manager.isJourneyTrackingEnabled == false)
        #expect(manager.consentDate == nil)
        #expect(manager.consentVersion == nil)
    }
    
    @Test("PrivacyManager updates consent to current version")
    func testUpdateConsent() async throws {
        clearUserDefaults()
        let manager = PrivacyManager()
        
        // Grant initial consent
        manager.hasJourneyTrackingConsent = true
        let initialDate = manager.consentDate
        
        // Wait a moment to ensure different timestamp
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Update consent
        let updated = await manager.updateConsent()
        
        #expect(updated == true)
        #expect(manager.consentVersion == "1.0")
        #expect(manager.consentDate != initialDate) // Should be updated
        #expect(manager.needsConsentUpdate == false)
    }
    
    @Test("PrivacyManager handles consent update without prior consent")
    func testUpdateConsentWithoutPriorConsent() async throws {
        clearUserDefaults()
        let manager = PrivacyManager()
        
        let updated = await manager.updateConsent()
        
        #expect(updated == true)
        #expect(manager.hasJourneyTrackingConsent == true)
    }
    
    // MARK: - Data Protection Tests
    
    @Test("PrivacyManager anonymizes history data")
    func testAnonymizeHistoryData() async throws {
        let manager = PrivacyManager.shared
        
        let anonymizedData = manager.anonymizeHistoryData()
        
        #expect(!anonymizedData.isEmpty)
        #expect(anonymizedData.contains("Anonymized"))
    }
    
    @Test("PrivacyManager encrypts and decrypts data")
    func testEncryptDecryptData() async throws {
        let manager = PrivacyManager.shared
        
        let originalData = "Sensitive information".data(using: .utf8)!
        
        let encryptedData = try manager.encryptSensitiveData(originalData)
        #expect(encryptedData.count > 0)
        
        let decryptedData = try manager.decryptSensitiveData(encryptedData)
        #expect(decryptedData == originalData)
    }
    
    @Test("PrivacyManager clears private data")
    func testClearPrivateData() async throws {
        let manager = PrivacyManager.shared
        
        // Should complete without throwing
        await manager.clearPrivateData()
    }
    
    // MARK: - Privacy Information Tests
    
    @Test("PrivacyManager provides data collection summary")
    func testDataCollectionSummary() async throws {
        clearUserDefaults()
        let manager = PrivacyManager()
        
        // Test with tracking disabled
        let summaryDisabled = manager.getDataCollectionSummary()
        #expect(summaryDisabled.journeyHistory == false)
        #expect(summaryDisabled.locationData == true) // Always true
        #expect(summaryDisabled.routePreferences == true) // Always true
        #expect(summaryDisabled.usageStatistics == false)
        #expect(summaryDisabled.crashReports == false)
        #expect(summaryDisabled.analytics == false)
        
        // Test with tracking enabled
        manager.hasJourneyTrackingConsent = true
        manager.isJourneyTrackingEnabled = true
        
        let summaryEnabled = manager.getDataCollectionSummary()
        #expect(summaryEnabled.journeyHistory == true)
        #expect(summaryEnabled.usageStatistics == true)
    }
    
    @Test("PrivacyManager provides privacy rights information")
    func testPrivacyRights() async throws {
        let manager = PrivacyManager.shared
        
        let rights = manager.getPrivacyRights()
        
        #expect(rights.canAccessData == true)
        #expect(rights.canExportData == true)
        #expect(rights.canDeleteData == true)
        #expect(rights.canRevokeConsent == true)
        #expect(rights.canRequestAnonymization == true)
        #expect(rights.dataRetentionPeriod > 0)
    }
    
    // MARK: - DataCollectionSummary Tests
    
    @Test("DataCollectionSummary provides collected data types")
    func testDataCollectionSummaryTypes() async throws {
        let summary = DataCollectionSummary(
            journeyHistory: true,
            locationData: true,
            routePreferences: false,
            usageStatistics: true,
            crashReports: false,
            analytics: false
        )
        
        let types = summary.collectedDataTypes
        #expect(types.contains("Journey History"))
        #expect(types.contains("Location Data"))
        #expect(types.contains("Usage Statistics"))
        #expect(!types.contains("Route Preferences"))
        #expect(!types.contains("Crash Reports"))
        #expect(!types.contains("Analytics"))
    }
    
    @Test("DataCollectionSummary handles all disabled")
    func testDataCollectionSummaryAllDisabled() async throws {
        let summary = DataCollectionSummary(
            journeyHistory: false,
            locationData: false,
            routePreferences: false,
            usageStatistics: false,
            crashReports: false,
            analytics: false
        )
        
        let types = summary.collectedDataTypes
        #expect(types.isEmpty)
    }
    
    // MARK: - PrivacyRights Tests
    
    @Test("PrivacyRights provides rights description")
    func testPrivacyRightsDescription() async throws {
        let rights = PrivacyRights(
            canAccessData: true,
            canExportData: true,
            canDeleteData: false,
            canRevokeConsent: true,
            canRequestAnonymization: false,
            dataRetentionPeriod: 18
        )
        
        let description = rights.rightsDescription
        #expect(description.contains("Access your data"))
        #expect(description.contains("Export your data"))
        #expect(description.contains("Revoke consent"))
        #expect(description.contains("18 months"))
        #expect(!description.contains("Delete your data"))
        #expect(!description.contains("Request data anonymization"))
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("PrivacyManager handles consent version changes")
    func testConsentVersionChanges() async throws {
        clearUserDefaults()
        
        // Simulate old consent version
        UserDefaults.standard.set(true, forKey: "journey_tracking_consent")
        UserDefaults.standard.set("0.9", forKey: "privacy_consent_version")
        
        let manager = PrivacyManager()
        
        #expect(manager.hasJourneyTrackingConsent == true)
        #expect(manager.consentVersion == "0.9")
        #expect(manager.needsConsentUpdate == true)
    }
    
    @Test("PrivacyManager handles missing consent version")
    func testMissingConsentVersion() async throws {
        clearUserDefaults()
        
        // Simulate consent without version (legacy)
        UserDefaults.standard.set(true, forKey: "journey_tracking_consent")
        
        let manager = PrivacyManager()
        
        #expect(manager.hasJourneyTrackingConsent == true)
        #expect(manager.consentVersion == nil)
        #expect(manager.needsConsentUpdate == true)
    }
    
    @Test("PrivacyManager handles concurrent access")
    func testConcurrentAccess() async throws {
        clearUserDefaults()
        let manager = PrivacyManager()
        
        // Perform multiple concurrent operations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    if i % 2 == 0 {
                        manager.isAnonymizedExportEnabled = true
                    } else {
                        manager.dataRetentionMonths = 12 + i
                    }
                }
            }
        }
        
        // Should complete without issues
        #expect(manager.dataRetentionMonths >= 12)
    }
    
    @Test("PrivacyManager persists settings across instances")
    func testSettingsPersistence() async throws {
        clearUserDefaults()
        
        // Set values in first instance
        let manager1 = PrivacyManager()
        manager1.hasJourneyTrackingConsent = true
        manager1.isAnonymizedExportEnabled = false
        manager1.dataRetentionMonths = 18
        
        // Create second instance and verify values persist
        let manager2 = PrivacyManager()
        #expect(manager2.hasJourneyTrackingConsent == true)
        #expect(manager2.isAnonymizedExportEnabled == false)
        #expect(manager2.dataRetentionMonths == 18)
    }
}