import SwiftUI
import CoreData

struct ContentView: View {
    @State private var navigationPath: [String] = []

    var body: some View {
        ZStack {
            NavigationStack(path: $navigationPath) {
                HomeMapView()
                    .ignoresSafeArea()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.hidden, for: .navigationBar)
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(for: String.self) { routeId in
                        RouteDestination(routeId: routeId)
                    }
            }
            .ignoresSafeArea()
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenRouteById"))) { note in
                if let id = note.object as? String { navigationPath = [id] }
            }

            if !OnboardingManager.shared.isCompleted {
                Color.black.opacity(0.35).ignoresSafeArea()
                OnboardingFlowView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}

