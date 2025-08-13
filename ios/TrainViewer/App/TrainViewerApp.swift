import SwiftUI

@main
struct TrainViewerApp: App {
    @StateObject private var routesVM = RoutesViewModel()
    @State private var deepLinkRouteId: UUID?
    @State private var openTicket: Bool = false

    init() {
        BackgroundRefreshService.shared.register()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainView()
                    .environmentObject(routesVM)
                    .onAppear {
                        AnalyticsService.shared.sessionStart()
                        AnalyticsService.shared.screen("MainView")
                        routesVM.loadRoutes()
                        Task { await routesVM.refreshAll() }
                        LocationService.shared.requestAuthorization()
                        Task { _ = await NotificationService.shared.requestAuthorization() }
                        Task { _ = await EventKitService.shared.requestAccess() }
                        BackgroundRefreshService.shared.schedule()
                        if let id = SharedStore.shared.takePendingRoute() {
                            deepLinkRouteId = id
                        }
                    }
                    .onDisappear {
                        AnalyticsService.shared.sessionEnd()
                    }
                    .onOpenURL { url in
                        guard url.scheme == "trainviewer" else { return }
                        if url.host == "route", let idStr = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "id" })?.value, let id = UUID(uuidString: idStr) {
                            deepLinkRouteId = id
                        } else if url.host == "show-ticket" {
                            openTicket = true
                        }
                    }
                    .sheet(item: $deepLinkRouteId, onDismiss: { deepLinkRouteId = nil }) { id in
                        if let route = routesVM.routes.first(where: { $0.id == id }) {
                            NavigationView { RouteDetailView(route: route) }
                                .onAppear { AnalyticsService.shared.screen("RouteDetailView") }
                        } else {
                            Text("Route not found")
                        }
                    }
                    .sheet(isPresented: $openTicket) { NavigationView { TicketView() } }
            }
        }
    }
}