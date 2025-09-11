import SwiftUI
import CoreLocation
import UserNotifications

// MARK: - Onboarding Test View
// This view can be used for testing the onboarding flow independently
struct OnboardingTestView: View {
    @State private var onboardingCompleted = false
    @State private var showOnboarding = true

    var body: some View {
        VStack {
            if showOnboarding {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showOnboarding = false
                        onboardingCompleted = true
                    }
                }
            } else {
                // Test completion screen
                VStack(spacing: 20) {
                    Text("🎉 Onboarding Completed!")
                        .font(.title)
                        .foregroundColor(.green)

                    Text("Status: \(onboardingCompleted ? "✅ Complete" : "❌ Incomplete")")
                        .font(.headline)

                    Text("UserSettingsStore.onboardingCompleted: \(UserSettingsStore.shared.onboardingCompleted ? "✅ True" : "❌ False")")
                        .font(.subheadline)

                    // Permission status display
                    VStack(spacing: 10) {
                        Text("Permission Status:")
                            .font(.headline)

                        HStack {
                            Text("Location:")
                            Text(getLocationStatus())
                                .foregroundColor(getLocationStatusColor())
                        }

                        HStack {
                            Text("Notifications:")
                            Text(getNotificationStatus())
                                .foregroundColor(getNotificationStatusColor())
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)

                    Button("Reset & Test Again") {
                        UserSettingsStore.shared.onboardingCompleted = false
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showOnboarding = true
                            onboardingCompleted = false
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
        }
    }

    private func getLocationStatus() -> String {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When In Use"
        @unknown default: return "Unknown"
        }
    }

    private func getLocationStatusColor() -> Color {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: return .green
        case .denied, .restricted: return .red
        default: return .orange
        }
    }

    private func getNotificationStatus() -> String {
        // This would need to be checked asynchronously in a real implementation
        return "Check in Settings"
    }

    private func getNotificationStatusColor() -> Color {
        return .orange
    }
}

// MARK: - Quick Onboarding Preview
struct OnboardingQuickPreview: View {
    var body: some View {
        TabView {
            ForEach(OnboardingStep.allCases) { step in
                VStack {
                    Text(step.title)
                        .font(.title)
                    Text(step.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    switch step {
                    case .welcome:
                        WelcomeStepView()
                    case .features:
                        FeaturesStepView()
                    case .smartWidget:
                        SmartWidgetStepView()
                    case .permissions:
                        PermissionsStepView(viewModel: OnboardingViewModel())
                    case .setup:
                        SetupStepView(viewModel: OnboardingViewModel())
                    }

                    Spacer()
                }
                .padding()
                .tabItem {
                    Text(step.title)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct OnboardingTestView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingTestView()
                .previewDisplayName("Full Onboarding Test")

            OnboardingQuickPreview()
                .previewDisplayName("Quick Step Preview")
        }
    }
}