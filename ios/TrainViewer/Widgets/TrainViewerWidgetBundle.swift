import WidgetKit
import SwiftUI

@main
struct TrainViewerWidgetBundle: WidgetBundle {
    init() {
        print("🔧 WIDGET BUNDLE: TrainViewerWidgetBundle initialized")
    }
    
    var body: some Widget {
        print("🔧 WIDGET BUNDLE: Creating widget bundle body")
        return Group {
            TrainViewerWidget()
            TrainViewerRouteWidget()
        }
    }
}