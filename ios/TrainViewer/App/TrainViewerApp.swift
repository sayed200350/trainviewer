import SwiftUI

// Wrapper view to ensure RoutesViewModel is always available
struct RoutesViewModelProvider<Content: View>: View {
    @StateObject private var routesVM = RoutesViewModel()
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .environmentObject(routesVM)
            .onAppear {
                // Load routes when the view appears
                routesVM.loadRoutes()
                // Start smart departure refresh monitoring
                routesVM.startSmartDepartureRefresh()
                // Trigger initial refresh for fresh data
                Task {
                    await routesVM.performInitialRefresh()
                }
            }
    }
}

// Helper view for route detail sheets
struct RouteDetailSheet: View {
    @EnvironmentObject var routesViewModel: RoutesViewModel
    let routeId: UUID?

    var body: some View {
        if let routeId = routeId, let route = routesViewModel.routes.first(where: { $0.id == routeId }) {
            NavigationView {
                RouteDetailView(route: route)
            }
            .onAppear { AnalyticsService.shared.screen("RouteDetailView") }
        } else {
            Text("Route not found")
        }
    }
}

// Helper view for global deep link overlay
struct DeepLinkOverlay: View {
    @EnvironmentObject var routesViewModel: RoutesViewModel
    let routeId: UUID?
    let onClose: () -> Void

    var body: some View {
        if let routeId = routeId, let route = routesViewModel.routes.first(where: { $0.id == routeId }) {
            NavigationView {
                RouteDetailView(route: route)
            }
            .frame(height: UIScreen.main.bounds.height * 0.8)
            .cornerRadius(20)
            .padding(.horizontal, 20)
        } else {
            VStack(spacing: 20) {
                Text("Route not found")
                    .font(.headline)
                Button("Close") {
                    onClose()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(40)
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, 40)
        }
    }
}

@main
struct TrainViewerApp: App {
    @State private var deepLinkRouteId: UUID?
    @State private var showOnboarding = !UserSettingsStore.shared.onboardingCompleted

    init() {
        BackgroundRefreshFactory.createService().register()

        // Initialize notification service
        SemesterTicketNotificationService.shared.registerNotificationCategories()
        SemesterTicketNotificationService.shared.refreshNotificationsIfNeeded()

        // App initialized
    }


    var body: some Scene {
        WindowGroup {
            RoutesViewModelProvider {
                ZStack {
                    if showOnboarding {
                        OnboardingView {
                            // Onboarding completed
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showOnboarding = false
                            }
                        }
                        .transition(.opacity)
                    } else {
                        NavigationStack {
                            MainView()
                                .onAppear {
                                    AnalyticsService.shared.sessionStart()
                                    AnalyticsService.shared.screen("MainView")
                                    // RoutesViewModel will be available via environment object
                                    LocationService.shared.requestAuthorization()
                                    Task { _ = await NotificationService.shared.requestAuthorization() }
                                    Task { _ = await EventKitService.shared.requestAccess() }
                                    BackgroundRefreshFactory.createService().schedule()
                                    if let id = SharedStore.shared.takePendingRoute() {
                                        deepLinkRouteId = id
                                    }
                                }
                                .onDisappear {
                                    AnalyticsService.shared.sessionEnd()
                                }
                                .onOpenURL { url in
                                    // Handle widget deep links: trainviewer://route/{routeId}
                                    if url.scheme == "trainviewer", url.host == "route", let routeIdStr = url.pathComponents.last, let routeId = UUID(uuidString: routeIdStr) {
                                        deepLinkRouteId = routeId
                                    }
                                    // Handle existing bahnblitz scheme for backward compatibility
                                    else if url.scheme == "bahnblitz", url.host == "route", let idStr = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "id" })?.value, let id = UUID(uuidString: idStr) {
                                        deepLinkRouteId = id
                                    }
                                }
                                .sheet(isPresented: .constant(deepLinkRouteId != nil), onDismiss: { deepLinkRouteId = nil }) {
                                    RouteDetailSheet(routeId: deepLinkRouteId)
                                }
                        }
                        .transition(.opacity)
                    }

                    // Deep link sheet that works for both onboarding and main view
                    if deepLinkRouteId != nil {
                        Color.black.opacity(0.5)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                deepLinkRouteId = nil
                            }

                        VStack {
                            Spacer()
                            DeepLinkOverlay(routeId: deepLinkRouteId) {
                                deepLinkRouteId = nil
                            }
                            Spacer()
                        }
                    }
                }
            }
            .onOpenURL { url in
                // Handle widget deep links: trainviewer://route/{routeId}
                if url.scheme == "trainviewer", url.host == "route", let routeIdStr = url.pathComponents.last, let routeId = UUID(uuidString: routeIdStr) {
                    deepLinkRouteId = routeId
                }
                // Handle existing bahnblitz scheme for backward compatibility
                else if url.scheme == "bahnblitz", url.host == "route", let idStr = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "id" })?.value, let id = UUID(uuidString: idStr) {
                    deepLinkRouteId = id
                }
            }
        }
    }
}