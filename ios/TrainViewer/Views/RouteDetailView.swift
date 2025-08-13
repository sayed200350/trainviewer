import SwiftUI

struct RouteDetailView: View {
    let route: Route
    @StateObject private var vm: RouteDetailViewModel
    @State private var showScheduledAlert = false
    @State private var showingShare = false

    init(route: Route) {
        self.route = route
        _vm = StateObject(wrappedValue: RouteDetailViewModel(route: route))
    }

    var body: some View {
        List {
            Section(header: Text(route.name)) {
                HStack {
                    Text(route.origin.name)
                    Image(systemName: "arrow.right")
                    Text(route.destination.name)
                }
                HStack {
                    if let first = vm.options.first {
                        Button(action: { scheduleReminder(for: first) }) {
                            Label("Remind me to leave", systemImage: "bell")
                        }
                    }
                    Spacer()
                    Button(action: { showingShare = true }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }

            if vm.isLoading {
                Section { ProgressView("Loading...") }
            }

            if let error = vm.errorMessage {
                Section { Text(error).foregroundColor(.red) }
            }

            if !vm.options.isEmpty {
                Section(header: Text("Next Departures")) {
                    ForEach(vm.options) { option in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("\(time(option.departure)) → \(time(option.arrival))")
                                Spacer()
                                if let platform = option.platform { Text("Platform \(platform)") }
                            }
                            if let delay = option.delayMinutes, delay > 0 {
                                Text("Delay: \(delay) min").font(.caption).foregroundColor(.orange)
                            }
                            if let warnings = option.warnings, !warnings.isEmpty {
                                ForEach(warnings, id: \.self) { w in
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                                        Text(w).font(.caption)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Details")
        .refreshable { await vm.refresh() }
        .onAppear { Task { await vm.refresh() } }
        .alert("Reminder scheduled", isPresented: $showScheduledAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("We'll remind you before departure.")
        }
        .sheet(isPresented: $showingShare) {
            let message: String
            if let first = vm.options.first {
                message = "\(route.name): leave in ~\(max(0, Int(first.departure.timeIntervalSince(Date())/60))) min (\(time(first.departure)) → \(time(first.arrival)))"
            } else {
                message = route.name
            }
            ShareSheet(activityItems: [message])
        }
    }

    private func scheduleReminder(for option: JourneyOption) {
        let leaveAt = option.departure.addingTimeInterval(TimeInterval(-route.preparationBufferMinutes * 60))
        Task { await NotificationService.shared.scheduleLeaveReminder(routeName: route.name, leaveAt: leaveAt); showScheduledAlert = true }
    }

    private func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}