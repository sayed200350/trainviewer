import WidgetKit
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

@main
struct BahnBlitzWidgetBundle: WidgetBundle {
    init() {
        print("🔧 WIDGET BUNDLE: BahnBlitzWidgetBundle initialized")
        #if canImport(ActivityKit)
        print("🔧 WIDGET BUNDLE: ActivityKit available: true")
        #else
        print("🔧 WIDGET BUNDLE: ActivityKit available: false")
        #endif
    }

    var body: some Widget {
        BahnBlitzWidget()
        SmartRouteWidget()
        #if canImport(ActivityKit)
        BahnBlitzLiveActivity()
        #endif
    }
}
