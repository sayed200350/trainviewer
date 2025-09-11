import SwiftUI
import UIKit
import CoreLocation
import UserNotifications

// MARK: - Onboarding Step Definition
enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome = 0
    case features = 1
    case smartWidget = 2
    case permissions = 3
    case setup = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome: return "Welcome to TrainViewer"
        case .features: return "Powerful Features"
        case .smartWidget: return "Smart Route Switching"
        case .permissions: return "Enable Smart Features"
        case .setup: return "Let's Get Started"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome: return "Your intelligent companion for public transportation"
        case .features: return "Discover what makes TrainViewer special"
        case .smartWidget: return "Set up automatic route switching based on your location"
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
            icon: "location.circle.fill",
            title: "Smart Route Switching",
            description: "Your widget automatically shows the right route based on your location - no manual switching needed!",
            color: .accentOrange
        ),

        FeatureHighlight(
            icon: "star.fill",
            title: "Widget Support",
            description: "Check your next departure right from your home screen with beautiful, informative widgets.",
            color: .brandBlue
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
        if Bundle.main.bundlePath.hasSuffix(".app") {
            Task {
                let notificationSettings = await UNUserNotificationCenter.current().notificationSettings()
                await MainActor.run {
                    notificationPermissionGranted = notificationSettings.authorizationStatus == .authorized
                    notificationPermissionDenied = notificationSettings.authorizationStatus == .denied
                }
            }
        } else {
            // In extension context, assume notifications are not available
            notificationPermissionGranted = false
            notificationPermissionDenied = true
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
        // Only available in main app, not in extensions
        if Bundle.main.bundlePath.hasSuffix(".app") {
            UserSettingsStore.shared.onboardingCompleted = true
        }
    }

    @MainActor
    func requestLocationPermission() async {
        guard !locationPermissionGranted else { return }

        isRequestingLocationPermission = true
        defer { isRequestingLocationPermission = false }

        // Request location permission using the existing LocationService
        // Only available in main app, not in extensions
        if Bundle.main.bundlePath.hasSuffix(".app") {
            LocationService.shared.requestAuthorization()

            // Wait a moment for the system dialog to appear and be handled
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

            // Check the status again
            let status = CLLocationManager.authorizationStatus()
            locationPermissionGranted = status == .authorizedWhenInUse || status == .authorizedAlways
            locationPermissionDenied = status == .denied || status == .restricted
        } else {
            // In extension context, assume permission is denied
            locationPermissionGranted = false
            locationPermissionDenied = true
        }
    }

    @MainActor
    func requestNotificationPermission() async {
        guard !notificationPermissionGranted else { return }

        isRequestingNotificationPermission = true
        defer { isRequestingNotificationPermission = false }

        // Only available in main app, not in extensions
        if Bundle.main.bundlePath.hasSuffix(".app") {
            do {
                let granted = await NotificationService.shared.requestAuthorization()
                notificationPermissionGranted = granted
                notificationPermissionDenied = !granted
            }
        } else {
            // In extension context, assume permission is denied
            notificationPermissionGranted = false
            notificationPermissionDenied = true
        }
    }

    func openSettings() {
        // Settings opening is disabled in extensions and main app for now
        // This prevents UIApplication.shared compilation issues
        // Users can manually navigate to settings if needed
    }
}

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.brandDark,
                    Color(hex: "#1a1a1a"),
                    Color.brandDark
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Progress indicator and skip button
                headerView

                // Main content area
                contentArea
                    .frame(maxHeight: .infinity)

                // Navigation buttons
                footerView
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .preferredColorScheme(.dark)
        .alert("Skip Setup?", isPresented: $viewModel.showSkipConfirmation) {
            Button("Continue Setup", role: .cancel) {}
            Button("Skip", role: .destructive) {
                viewModel.completeOnboarding()
                onComplete()
            }
        } message: {
            Text("You can always set up your routes later in the app settings.")
        }
    }

    private var headerView: some View {
        HStack {
            // Progress indicator
            VStack(alignment: .leading, spacing: 8) {
                Text("Step \(viewModel.currentStep.rawValue + 1) of \(OnboardingStep.allCases.count)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.textSecondary)

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentGreen)
                            .frame(width: geometry.size.width * viewModel.progress, height: 4)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
                    }
                }
                .frame(height: 4)
            }

            Spacer()

            // Skip button
            if viewModel.currentStep != .setup {
                Button(action: { viewModel.showSkipConfirmation = true }) {
                    Text("Skip")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 20)
    }

    private var contentArea: some View {
        TabView(selection: $viewModel.currentStep) {
            ForEach(OnboardingStep.allCases) { step in
                stepContent(for: step)
                    .tag(step)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
        .disabled(true) // Disable swipe gestures, use buttons instead
    }

    @ViewBuilder
    private func stepContent(for step: OnboardingStep) -> some View {
        VStack(spacing: 32) {
            Spacer()

            // Step content with transition effects
            Group {
                switch step {
                case .welcome:
                    WelcomeStepView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .features:
                    FeaturesStepView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .smartWidget:
                    SmartWidgetStepView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .permissions:
                    PermissionsStepView(viewModel: viewModel)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .setup:
                    SetupStepView(viewModel: viewModel)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.4), value: viewModel.currentStep)

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var footerView: some View {
        VStack(spacing: 16) {
            // Page indicators
            HStack(spacing: 8) {
                ForEach(OnboardingStep.allCases) { step in
                    Circle()
                        .fill(step.rawValue <= viewModel.currentStep.rawValue ? Color.accentGreen : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.currentStep)
                }
            }

            // Navigation buttons
            HStack(spacing: 12) {
                // Back button
                if viewModel.currentStep != .welcome {
                    Button(action: {
                        // Add haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        viewModel.previousStep()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.cardBackground)
                        .foregroundColor(.textPrimary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Next/Complete button
                Button(action: {
                    // Add haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()

                    if viewModel.currentStep.isLast {
                        viewModel.completeOnboarding()
                        onComplete()
                    } else {
                        viewModel.nextStep()
                    }
                }) {
                    HStack(spacing: 8) {
                        Text(viewModel.currentStep.isLast ? "Get Started" : "Next")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                        if !viewModel.currentStep.isLast {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.currentStep.isLast ? Color.accentGreen : Color.brandBlue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: (viewModel.currentStep.isLast ? Color.accentGreen : Color.brandBlue).opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Step Content Views
struct WelcomeStepView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            // Icon with bounce animation
            ZStack {
                Circle()
                    .fill(Color.brandBlue.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)

                Image(systemName: "tram.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.brandBlue)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
            }
            .onAppear {
                isAnimating = true
            }

            // Title and description
            VStack(spacing: 16) {
                Text("Welcome to TrainViewer")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Your intelligent companion for public transportation. Never miss your train again with smart notifications and real-time updates.")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
        }
    }
}

struct FeaturesStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Title
            VStack(spacing: 8) {
                Text("Powerful Features")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text("Everything you need for stress-free travel")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
            }

            // Features grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(FeatureHighlight.features.prefix(4)) { feature in
                    FeatureCard(feature: feature)
                }
            }
        }
    }
}

struct PermissionsStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Title
            VStack(spacing: 8) {
                Text("Enable Smart Features")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text("Get the most out of TrainViewer with these permissions")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
            }

            // Permissions list
            VStack(spacing: 16) {
                ForEach(PermissionRequest.permissions) { permission in
                    PermissionCard(
                        permission: permission,
                        viewModel: viewModel
                    )
                }
            }

            // Note
            Text("You can change these permissions anytime in Settings")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }
}

struct SmartWidgetStepView: View {
    @State private var homeQuery: String = ""
    @State private var campusQuery: String = ""
    @State private var homeResults: [Place] = []
    @State private var campusResults: [Place] = []
    @State private var selectedHome: Place?
    @State private var selectedCampus: Place?

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.accentOrange.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "location.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.accentOrange)
            }

            // Title and description
            VStack(spacing: 16) {
                Text("Smart Route Switching")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text("Set up your home and work/campus locations to enable automatic route switching. Your widget will know which route to show based on where you are!")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }

            // Location setup section
            VStack(spacing: 20) {
                // Home location
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "house.fill")
                            .foregroundColor(.accentOrange)
                            .font(.system(size: 16))
                        Text("Home Location")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        if selectedHome != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.successColor)
                                .font(.system(size: 16))
                        }
                    }

                    TextField("Search for your home station", text: $homeQuery)
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                        .onChange(of: homeQuery) { newValue in
                            searchLocations(query: newValue, for: .home)
                        }

                    if !homeResults.isEmpty {
                        ScrollView {
                            VStack(spacing: 4) {
                                ForEach(homeResults.prefix(3), id: \.id) { place in
                                    Button(action: {
                                        selectedHome = place
                                        homeQuery = place.name
                                        homeResults = []
                                    }) {
                                        HStack {
                                            Text(place.name)
                                                .foregroundColor(.textPrimary)
                                            Spacer()
                                            if selectedHome?.id == place.id {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.accentOrange)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 120)
                        .background(Color.cardBackground)
                        .cornerRadius(8)
                    }
                }

                // Campus/Work location
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "building.2.fill")
                            .foregroundColor(.accentOrange)
                            .font(.system(size: 16))
                        Text("Campus/Work Location")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        if selectedCampus != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.successColor)
                                .font(.system(size: 16))
                        }
                    }

                    TextField("Search for your campus/work station", text: $campusQuery)
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                        .onChange(of: campusQuery) { newValue in
                            searchLocations(query: newValue, for: .campus)
                        }

                    if !campusResults.isEmpty {
                        ScrollView {
                            VStack(spacing: 4) {
                                ForEach(campusResults.prefix(3), id: \.id) { place in
                                    Button(action: {
                                        selectedCampus = place
                                        campusQuery = place.name
                                        campusResults = []
                                    }) {
                                        HStack {
                                            Text(place.name)
                                                .foregroundColor(.textPrimary)
                                            Spacer()
                                            if selectedCampus?.id == place.id {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.accentOrange)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 120)
                        .background(Color.cardBackground)
                        .cornerRadius(8)
                    }
                }

                // Preview of smart switching
                if selectedHome != nil && selectedCampus != nil {
                    VStack(spacing: 12) {
                        Text("🎯 Smart Widget Ready!")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.successColor)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.accentOrange)
                                    .font(.system(size: 14))
                                Text("At **\(selectedHome!.name)** → Shows route to **\(selectedCampus!.name)**")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(.textSecondary)
                            }

                            HStack(spacing: 8) {
                                Image(systemName: "building.2.fill")
                                    .foregroundColor(.accentOrange)
                                    .font(.system(size: 14))
                                Text("At **\(selectedCampus!.name)** → Shows route back to **\(selectedHome!.name)**")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .padding(12)
                        .background(Color.successColor.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .onDisappear {
            // Save the selected locations when user moves to next step
            if let home = selectedHome, let campus = selectedCampus {
                UserSettingsStore.shared.homePlace = home
                UserSettingsStore.shared.campusPlace = campus
            }
        }
    }

    private func searchLocations(query: String, for type: LocationType) {
        guard query.count >= 2 else {
            if type == .home {
                homeResults = []
            } else {
                campusResults = []
            }
            return
        }

        // For demo purposes, provide some sample locations
        // In a real implementation, this would call the transport API
        let sampleLocations = [
            Place(rawId: nil, name: "München Hauptbahnhof", latitude: 48.1402, longitude: 11.5580),
            Place(rawId: nil, name: "München Ostbahnhof", latitude: 48.1270, longitude: 11.6040),
            Place(rawId: nil, name: "Stuttgart Hauptbahnhof", latitude: 48.7843, longitude: 9.1818),
            Place(rawId: nil, name: "Berlin Hauptbahnhof", latitude: 52.5250, longitude: 13.3690)
        ]

        let filtered = sampleLocations.filter { place in
            place.name.localizedCaseInsensitiveContains(query)
        }

        if type == .home {
            homeResults = filtered
        } else {
            campusResults = filtered
        }
    }

    private enum LocationType {
        case home, campus
    }
}

struct SetupStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.accentGreen.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.accentGreen)
            }

            // Title and description
            VStack(spacing: 16) {
                Text("Let's Get Started")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text("Set up your first route to start receiving smart notifications and real-time updates.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }

            // Quick setup hint
            VStack(spacing: 12) {
                Text("What you'll do next:")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(.accentGreen)
                            .font(.system(size: 16))
                        Text("Add your departure and arrival stations")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.textSecondary)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(.accentGreen)
                            .font(.system(size: 16))
                        Text("Set your preferred travel time")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.textSecondary)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(.accentGreen)
                            .font(.system(size: 16))
                        Text("Enable notifications and widgets")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Supporting Views
struct FeatureCard: View {
    let feature: FeatureHighlight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: feature.icon)
                    .font(.system(size: 20))
                    .foregroundColor(feature.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text(feature.description)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .lineLimit(3)
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }
}

struct PermissionCard: View {
    let permission: PermissionRequest
    @ObservedObject var viewModel: OnboardingViewModel

    var isGranted: Bool {
        switch permission.permissionType {
        case .location:
            return viewModel.locationPermissionGranted
        case .notifications:
            return viewModel.notificationPermissionGranted
        }
    }

    var isDenied: Bool {
        switch permission.permissionType {
        case .location:
            return viewModel.locationPermissionDenied
        case .notifications:
            return viewModel.notificationPermissionDenied
        }
    }

    var isRequesting: Bool {
        switch permission.permissionType {
        case .location:
            return viewModel.isRequestingLocationPermission
        case .notifications:
            return viewModel.isRequestingNotificationPermission
        }
    }

    var buttonText: String {
        if isGranted {
            return "Granted"
        } else if isDenied {
            return "Settings"
        } else if isRequesting {
            return "Requesting..."
        } else {
            return "Allow"
        }
    }

    var buttonColor: Color {
        if isGranted {
            return .successColor
        } else if isDenied {
            return .warningColor
        } else {
            return .textPrimary
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 48, height: 48)

                Image(systemName: permission.icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(permission.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)

                    if permission.isRequired {
                        Text("Required")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.warningColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.warningColor.opacity(0.1))
                            .cornerRadius(6)
                    }

                    if isDenied {
                        Text("Denied")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.errorColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.errorColor.opacity(0.1))
                            .cornerRadius(6)
                    }
                }

                Text(permission.description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)

                if isDenied {
                    Text("Go to Settings to enable this permission")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(action: {
                // Add haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()

                if isDenied {
                    viewModel.openSettings()
                } else {
                    Task {
                        switch permission.permissionType {
                        case .location:
                            await viewModel.requestLocationPermission()
                        case .notifications:
                            await viewModel.requestNotificationPermission()
                        }
                    }
                }
            }) {
                HStack(spacing: 8) {
                    if isRequesting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.7)
                    }

                    Text(buttonText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(minWidth: 80)
                .background(buttonBackgroundColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(buttonBorderColor, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isRequesting)
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }

    private var iconColor: Color {
        if isGranted {
            return .successColor
        } else if isDenied {
            return .errorColor
        } else {
            return permission.isRequired ? .warningColor : .brandBlue
        }
    }

    private var iconBackgroundColor: Color {
        if isGranted {
            return Color.successColor.opacity(0.1)
        } else if isDenied {
            return Color.errorColor.opacity(0.1)
        } else {
            return permission.isRequired ? Color.warningColor.opacity(0.1) : Color.brandBlue.opacity(0.1)
        }
    }

    private var buttonBackgroundColor: Color {
        if isGranted {
            return Color.successColor
        } else if isDenied {
            return Color.warningColor
        } else {
            return Color.brandBlue
        }
    }

    private var buttonBorderColor: Color {
        if isGranted {
            return Color.successColor.opacity(0.3)
        } else if isDenied {
            return Color.warningColor.opacity(0.3)
        } else {
            return Color.brandBlue.opacity(0.3)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(onComplete: {})
            .preferredColorScheme(.dark)
    }
}
