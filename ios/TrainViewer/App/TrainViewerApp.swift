import SwiftUI

@main
struct TrainViewerApp: App {
    @StateObject private var routesVM = RoutesViewModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(routesVM)
                .onAppear {
                    routesVM.loadRoutes()
                    Task { await routesVM.refreshAll() }
                    LocationService.shared.requestAuthorization()
                    Task { _ = await NotificationService.shared.requestAuthorization() }
                }
        }
    }
}