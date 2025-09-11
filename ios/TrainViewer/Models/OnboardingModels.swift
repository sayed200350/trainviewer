import SwiftUI
import CoreLocation
import UserNotifications

// MARK: - Onboarding Step Definition
enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome = 0
    case features = 1
    case permissions = 2
    case setup = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome: return "Welcome to TrainViewer"
        case .features: return "Powerful Features"
        case .permissions: return "Enable Smart Features"
        case .setup: return "Let's Get Started"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome: return "Your intelligent companion for public transportation"
        case .features: return "Discover what makes TrainViewer special"
        case .permissions: return "Allow access for the best experience"
        case .setup: return "Set up your first route in seconds"
        }
    }

    var isLast: Bool {
        self == OnboardingStep.allCases.last
    }

    var nextStep: OnboardingStep? {
        OnboardingStep(rawValue: rawValue + 1)
    }

    var previousStep: OnboardingStep? {
        rawValue > 0 ? OnboardingStep(rawValue: rawValue - 1) : nil
    }
}

// MARK: - Feature Highlight
struct FeatureHighlight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color

    static let features: [FeatureHighlight] = [
        FeatureHighlight(
            icon: "bell.badge.fill",
            title: "Smart Notifications",
            description: "Get reminded when it's time to leave for your train, with real-time updates for delays and platform changes.",
            color: .brandBlue
        ),
        FeatureHighlight(
            icon: "location.fill",
            title: "Live Updates",
            description: "Never miss a connection with real-time departure information and walking time calculations.",
            color: .accentGreen
        ),
        FeatureHighlight(
            icon: "star.fill",
            title: "Widget Support",
            description: "Check your next departure right from your home screen with beautiful, informative widgets.",
            color: .accentOrange
        ),
        FeatureHighlight(
            icon: "clock.fill",
            title: "Journey History",
            description: "Track your travel patterns and optimize your routes with detailed journey analytics.",
            color: .infoColor
        ),
        FeatureHighlight(
            icon: "battery.100",
            title: "Battery Optimized",
            description: "Smart refresh intervals and offline support ensure you never run out of battery when you need it most.",
            color: .successColor
        ),
        FeatureHighlight(
            icon: "hand.raised.fill",
            title: "Privacy First",
            description: "Your location and travel data stay private. We only use what's necessary to get you where you need to go.",
            color: .warningColor
        )
    ]
}

// MARK: - Permission Request
struct PermissionRequest: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let permissionType: PermissionType
    let isRequired: Bool

    enum PermissionType {
        case location
        case notifications
    }

    static let permissions: [PermissionRequest] = [
        PermissionRequest(
            icon: "location.fill",
            title: "Location Access",
            description: "Used to calculate walking time to stations and provide location-based suggestions.",
            permissionType: .location,
            isRequired: false
        ),
        PermissionRequest(
            icon: "bell.fill",
            title: "Notifications",
            description: "Receive timely reminders for your departures and alerts about delays.",
            permissionType: .notifications,
            isRequired: false
        )
    ]
}

// MARK: - Onboarding State
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var isAnimating = false
    @Published var showSkipConfirmation = false

    // Permission states
    @Published var locationPermissionGranted = false
    @Published var locationPermissionDenied = false
    @Published var notificationPermissionGranted = false
    @Published var notificationPermissionDenied = false
    @Published var isRequestingLocationPermission = false
    @Published var isRequestingNotificationPermission = false

    // Setup states
    @Published var hasCompletedSetup = false
    @Published var showSetupFlow = false

    private let locationManager = CLLocationManager()

    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(OnboardingStep.allCases.count)
    }

    init() {
        checkInitialPermissionStatus()
    }

    private func checkInitialPermissionStatus() {
        // Check location permission status
        let locationStatus = CLLocationManager.authorizationStatus()
        locationPermissionGranted = locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways
        locationPermissionDenied = locationStatus == .denied || locationStatus == .restricted

        // Check notification permission status
        Task {
            let notificationSettings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                notificationPermissionGranted = notificationSettings.authorizationStatus == .authorized
                notificationPermissionDenied = notificationSettings.authorizationStatus == .denied
            }
        }
    }

    func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isAnimating = true
            if let next = currentStep.nextStep {
                currentStep = next
            }
        }

        // Reset animation after transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isAnimating = false
        }
    }

    func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isAnimating = true
            if let previous = currentStep.previousStep {
                currentStep = previous
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isAnimating = false
        }
    }

    func skipToSetup() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isAnimating = true
            currentStep = .setup
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isAnimating = false
        }
    }

    func completeOnboarding() {
        // Mark onboarding as completed in UserSettingsStore
        UserSettingsStore.shared.onboardingCompleted = true
    }

    @MainActor
    func requestLocationPermission() async {
        guard !locationPermissionGranted else { return }

        isRequestingLocationPermission = true
        defer { isRequestingLocationPermission = false }

        // Request location permission using the existing LocationService
        LocationService.shared.requestAuthorization()

        // Wait a moment for the system dialog to appear and be handled
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Check the status again
        let status = CLLocationManager.authorizationStatus()
        locationPermissionGranted = status == .authorizedWhenInUse || status == .authorizedAlways
        locationPermissionDenied = status == .denied || status == .restricted
    }

    @MainActor
    func requestNotificationPermission() async {
        guard !notificationPermissionGranted else { return }

        isRequestingNotificationPermission = true
        defer { isRequestingNotificationPermission = false }

        do {
            let granted = await NotificationService.shared.requestAuthorization()
            notificationPermissionGranted = granted
            notificationPermissionDenied = !granted
        }
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
