import SwiftUI
import CoreData

struct RouteDestination: View {
    @Environment(\.managedObjectContext) private var context
    let routeId: String

    @FetchRequest var routes: FetchedResults<RouteEntity>

    init(routeId: String) {
        self.routeId = routeId
        _routes = FetchRequest<RouteEntity>(
            entity: RouteEntity.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "id == %@", routeId),
            animation: .default
        )
    }

    var body: some View {
        if let route = routes.first {
            RouteDetailView(route: route)
        } else {
            Text("Route not found")
        }
    }
}


