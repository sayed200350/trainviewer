import SwiftUI

@main
struct TrainViewerApp: App {
    @StateObject private var routesVM = RoutesViewModel()
    @State private var deepLinkRouteId: UUID?

    init() {
        BackgroundRefreshFactory.createService().register()
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
                        BackgroundRefreshFactory.createService().schedule()
                        if let id = SharedStore.shared.takePendingRoute() {
                            deepLinkRouteId = id
                        }
                    }
                    .onDisappear {
                        AnalyticsService.shared.sessionEnd()
                    }
                    .onOpenURL { url in
                        if url.scheme == "trainviewer", url.host == "route", let idStr = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "id" })?.value, let id = UUID(uuidString: idStr) {
                            deepLinkRouteId = id
                        }
                    }
                    .sheet(isPresented: .constant(deepLinkRouteId != nil), onDismiss: { deepLinkRouteId = nil }) {
                        if let routeId = deepLinkRouteId, let route = routesVM.routes.first(where: { $0.id == routeId }) {
                            NavigationView { RouteDetailView(route: route) }
                                .onAppear { AnalyticsService.shared.screen("RouteDetailView") }
                        } else {
                            Text("Route not found")
                        }
                    }
            }
        }
    }
}