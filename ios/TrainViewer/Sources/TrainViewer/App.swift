import SwiftUI
import CoreData
import WidgetKit

@main
struct TrainViewerApp: App {
    private let persistenceController = PersistenceController.shared
    @Environment(\.openURL) private var openURL
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .ignoresSafeArea(.all)
                .task { syncPreferences() }
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }
}

extension TrainViewerApp {
    private func syncPreferences() {
        let appPrefs = AppPreferences.shared
        let userRepo = UserRepository()
        guard let user = try? userRepo.getOrCreateLocalUser() else { return }
        if let json = user.preferencesJSON, !json.isEmpty {
            appPrefs.importFromJSON(json)
        } else if let json = appPrefs.exportToJSON() {
            user.preferencesJSON = json
            try? persistenceController.viewContext.save()
        }
    }

    private func handleIncomingURL(_ url: URL) {
        // scheme: trainviewer://route/<id>
        guard url.scheme == "trainviewer" else { return }
        let components = url.pathComponents
        if components.count >= 3, components[1] == "route" {
            let id = components[2]
            NotificationCenter.default.post(name: Notification.Name("OpenRouteById"), object: id)
        }
    }
}

