import SwiftUI

struct RouteDetailView: View {
    let route: Route
    @StateObject private var vm: RouteDetailViewModel
    @StateObject private var locationService = LocationService.shared
    @State private var showScheduledAlert = false
    @State private var showingShare = false

    init(route: Route) {
        self.route = route
        _vm = StateObject(wrappedValue: RouteDetailViewModel(route: route))
    }
    
    private var shareMessage: String {
        if let first = vm.options.first {
            return "\(route.name): leave in ~\(max(0, Int(first.departure.timeIntervalSince(Date())/60))) min (\(time(first.departure)) → \(time(first.arrival)))"
        } else {
            return route.name
        }
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
            
            // Location-based information section
            if locationService.authorizationStatus == .authorizedWhenInUse || locationService.authorizationStatus == .authorizedAlways {
                Section(header: Text("Location Information")) {
                    LocationInfoSection(route: route, locationService: locationService)
                }
            } else {
                Section(header: Text("Location Services")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enable location access for enhanced features:")
                        Text("• Walking time estimates")
                        Text("• Proximity detection")
                        Text("• Automatic route suggestions")
                        
                        Button("Enable Location Access") {
                            locationService.requestAuthorization()
                        }
                        .foregroundColor(.blue)
                    }
                    .font(.caption)
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
            Button("OK") { }
        }
        .sheet(isPresented: $showingShare) {
            ShareSheet(activityItems: [shareMessage])
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

// MARK: - Location Information Section

private struct LocationInfoSection: View {
    let route: Route
    @ObservedObject var locationService: LocationService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Walking time information
            if locationService.currentLocation != nil {
                walkingTimeSection
                proximitySection
            } else {
                Text("Waiting for location...")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
    
    @ViewBuilder
    private var walkingTimeSection: some View {
        let walkingTimes = locationService.calculateWalkingTimeForRoute(route)
        
        VStack(alignment: .leading, spacing: 4) {
            Label("Walking Times", systemImage: "figure.walk")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("To Origin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatWalkingTime(walkingTimes.toOrigin))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("To Destination")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatWalkingTime(walkingTimes.toDestination))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
    }
    
    @ViewBuilder
    private var proximitySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Check if user is near this route's locations
            let isNearOrigin = locationService.isNearPlace(route.origin, threshold: 200.0)
            let isNearDestination = locationService.isNearPlace(route.destination, threshold: 200.0)
            
            if isNearOrigin || isNearDestination {
                Label("Proximity Alert", systemImage: "location.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                
                if isNearOrigin {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("You're near \(route.origin.name)")
                            .font(.caption)
                    }
                }
                
                if isNearDestination {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("You're near \(route.destination.name)")
                            .font(.caption)
                    }
                }
            }
            
            // Show distance information
            if let originDistance = locationService.distanceToPlace(route.origin) {
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.blue)
                    Text("Origin: \(formatDistance(originDistance))")
                        .font(.caption)
                }
            }
            
            if let destDistance = locationService.distanceToPlace(route.destination) {
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.blue)
                    Text("Destination: \(formatDistance(destDistance))")
                        .font(.caption)
                }
            }
        }
    }
    
    private func formatWalkingTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        if minutes < 1 {
            return "< 1 min"
        } else if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m away"
        } else {
            let km = distance / 1000
            return String(format: "%.1fkm away", km)
        }
    }
}