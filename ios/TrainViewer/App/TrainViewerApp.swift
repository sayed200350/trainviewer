import SwiftUI

@main
struct TrainViewerApp: App {
    @StateObject private var routesVM = RoutesViewModel()
    @State private var deepLinkRouteId: UUID?

    init() {
        BackgroundRefreshService.shared.register()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainView()
                    .environmentObject(routesVM)
                    .onAppear {
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
                    .onOpenURL { url in
                        if url.scheme == "trainviewer", url.host == "route", let idStr = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "id" })?.value, let id = UUID(uuidString: idStr) {
                            deepLinkRouteId = id
                        }
                    }
                    .sheet(item: $deepLinkRouteId, onDismiss: { deepLinkRouteId = nil }) { id in
                        if let route = routesVM.routes.first(where: { $0.id == id }) {
                            NavigationView { RouteDetailView(route: route) }
                        } else {
                            Text("Route not found")
                        }
                    }
            }
        }
    }
}