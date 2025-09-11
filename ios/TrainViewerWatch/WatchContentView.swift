import SwiftUI

struct WatchContentView: View {
    @State private var routeName: String = ""
    @State private var leaveMinutes: Int = 0

    var body: some View {
        VStack(spacing: 6) {
            Text(routeName.isEmpty ? "BahnBlitz" : routeName)
                .font(.headline)
                .lineLimit(1)
            Text(leaveMinutes <= 0 ? "Leave now" : "Leave in \(leaveMinutes) min")
                .font(.caption)
        }
        .onAppear(perform: load)
    }

    private func load() {
        if let snap = SharedStore.shared.loadSnapshot() {
            routeName = snap.routeName
            leaveMinutes = snap.leaveInMinutes
        }
    }
}