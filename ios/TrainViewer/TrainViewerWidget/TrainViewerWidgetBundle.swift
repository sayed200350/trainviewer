import WidgetKit
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

@main
struct TrainViewerWidgetBundle: WidgetBundle {
    init() {
        print("🔧 WIDGET BUNDLE: TrainViewerWidgetBundle initialized")
        #if canImport(ActivityKit)
        print("🔧 WIDGET BUNDLE: ActivityKit available: true")
        #else
        print("🔧 WIDGET BUNDLE: ActivityKit available: false")
        #endif
    }

    var body: some Widget {
        TrainViewerWidget()
        #if canImport(ActivityKit)
        TrainViewerLiveActivity()
        #endif
    }
}
