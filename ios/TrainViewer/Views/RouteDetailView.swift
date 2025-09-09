import SwiftUI

// Global time formatting helper
extension Date {
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

struct RouteDetailView: View {
    let route: Route
    @StateObject private var vm: RouteDetailViewModel
    @StateObject private var locationService = LocationService.shared
    @State private var showScheduledAlert = false
    @State private var showingShare = false
    @State private var showingJourneyStops = false
    @State private var selectedJourneyOption: JourneyOption?
    @State private var showingQuickActions = false
    @EnvironmentObject var routesViewModel: RoutesViewModel

    init(route: Route) {
        self.route = route
        _vm = StateObject(wrappedValue: RouteDetailViewModel(route: route))
    }


    // Helper function for scheduling reminders
    private func scheduleReminder(for option: JourneyOption) {
        let leaveAt = option.departure.addingTimeInterval(TimeInterval(-route.preparationBufferMinutes * 60))
        Task {
            await NotificationService.shared.scheduleLeaveReminder(routeName: route.name, leaveAt: leaveAt)
            showScheduledAlert = true
        }
    }

    private var shareMessage: String {
        if let first = vm.options.first {
            return "\(route.name): leave in ~\(max(0, Int(first.departure.timeIntervalSince(Date())/60))) min (\(first.departure.formattedTime()) → \(first.arrival.formattedTime()))"
        } else {
            return route.name
        }
    }

    var body: some View {
        ZStack {
            Color.brandDark.edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 24) {
                    // Route Header Card
                    routeHeaderCard

                    // Quick Actions Bar
                    quickActionsBar

                    // Journey Options
                    journeyOptionsSection
                }
                .padding(.vertical, 20)
            }
            .refreshable {
                await vm.refresh()
            }
        }
        .navigationTitle(route.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await vm.refresh()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingQuickActions = true }) {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showingShare) {
            ShareSheet(activityItems: [shareMessage])
        }
        .sheet(isPresented: $showingQuickActions) {
            QuickActionsSheet(route: route, onEdit: {}, onDelete: {})
        }
        .alert(isPresented: $showScheduledAlert) {
            Alert(
                title: Text("Reminder Set"),
                message: Text("We'll remind you when it's time to leave."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var routeHeaderCard: some View {
        VStack(spacing: 16) {
            // Route visualization
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Circle()
                        .fill(Color.brandBlue)
                        .frame(width: 12, height: 12)
                    Rectangle()
                        .fill(Color.borderColor)
                        .frame(width: 2, height: 24)
                    Circle()
                        .fill(Color.accentGreen)
                        .frame(width: 12, height: 12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(route.origin.name)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text("Origin")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(route.destination.name)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text("Destination")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                // Route color indicator
                Circle()
                    .fill(route.color.color)
                    .frame(width: 20, height: 20)
            }

            // Route stats
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(route.usageCount)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Text("Uses")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.textSecondary)
                }

                VStack(spacing: 4) {
                    Text(route.usageFrequency.displayName)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Text("Frequency")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.textSecondary)
                }

                VStack(spacing: 4) {
                    Text(route.createdAt.formatted(.relative(presentation: .named)))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Text("Created")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.borderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
    }

    private var quickActionsBar: some View {
        HStack(spacing: 16) {
            ActionButton(
                title: "Set Reminder",
                icon: "bell.fill",
                color: .brandBlue,
                action: {
                    if let first = vm.options.first {
                        scheduleReminder(for: first)
                    }
                }
            )
            .disabled(vm.options.isEmpty)

            ActionButton(
                title: "Share Route",
                icon: "square.and.arrow.up.fill",
                color: .accentGreen,
                action: { showingShare = true }
            )
        }
        .padding(.horizontal, 20)
    }

    private var journeyOptionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Available Departures")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(vm.options.count)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.elevatedBackground)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)

            // Show selected journey details if any
            if let selectedOption = selectedJourneyOption {
                if routesViewModel.isLoadingJourneyDetails {
                    HStack(spacing: 12) {
                        ProgressView()
                            .tint(.accentOrange)
                        Text("Loading journey details...")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Button(action: {
                            selectedJourneyOption = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.textTertiary)
                                .font(.system(size: 16))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .background(Color.elevatedBackground)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                } else if let journeyDetails = routesViewModel.selectedJourneyDetails {
                    JourneyStopsView(
                        journeyDetails: journeyDetails,
                        onClose: { selectedJourneyOption = nil }
                    )
                    .padding(.horizontal, 20)
                }
            }

            // Loading state
            if vm.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.accentOrange)
                        .scaleEffect(1.5)
                    Text("Loading departures...")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.textSecondary)
                }
                .padding(.vertical, 40)
            }
            // Error state
            else if let errorMessage = vm.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.warningColor)
                    Text("Unable to load departures")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                    Button(action: {
                        Task {
                            await vm.refresh()
                        }
                    }) {
                        Text("Try Again")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.accentGreen)
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 40)
            }
            // Departure options
            else if vm.options.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tram.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.textTertiary)
                    Text("No departures found")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.textSecondary)
                    Text("Check your connection or try refreshing")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.textTertiary)
                }
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(vm.options) { option in
                        JourneyOptionCard(
                            option: option,
                            onSelect: {
                                selectedJourneyOption = option
                                Task {
                                    await routesViewModel.loadJourneyDetails(for: option)
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Supporting Components

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 20))
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct JourneyOptionCard: View {
    let option: JourneyOption
    let onSelect: () -> Void

    private var statusColor: Color {
        if option.hasDelay {
            return .warningColor
        } else if option.hasWarnings {
            return .accentOrange
        } else {
            return .successColor
        }
    }

    private var statusText: String {
        if option.hasDelay {
            return "Delayed"
        } else if option.hasWarnings {
            return "Warning"
        } else {
            return "On Time"
        }
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Time information
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(option.departure.formattedTime()) → \(option.arrival.formattedTime())")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)

                    Text("\(option.totalMinutes) min • \(option.lineName ?? "Direct")")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Status and platform
                VStack(alignment: .trailing, spacing: 4) {
                    if let platform = option.platform {
                        Text("Platform \(platform)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.elevatedBackground)
                            .cornerRadius(6)
                    }

                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        Text(statusText)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(statusColor)
                    }
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .foregroundColor(.textTertiary)
                    .font(.system(size: 14))
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

}

struct QuickActionsSheet: View {
    let route: Route
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Text("Route Actions")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)

                VStack(spacing: 0) {
                    Button(action: onEdit) {
                        HStack(spacing: 12) {
                            Image(systemName: "pencil")
                                .foregroundColor(.brandBlue)
                                .font(.system(size: 18))
                            Text("Edit Route")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.textPrimary)
                            Spacer()
                        }
                        .padding(16)
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .background(Color.borderColor)

                    Button(action: onDelete) {
                        HStack(spacing: 12) {
                            Image(systemName: "trash")
                                .foregroundColor(.errorColor)
                                .font(.system(size: 18))
                            Text("Delete Route")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.errorColor)
                            Spacer()
                        }
                        .padding(16)
                    }
                    .buttonStyle(.plain)
                }
                .background(Color.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
            }
            .padding(20)

            Button(action: {}) {
                Text("Cancel")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.brandBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.brandDark)
    }
}

// MARK: - Journey Stops View
struct JourneyStopsView: View {
    let journeyDetails: JourneyDetails
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Journey Details")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textTertiary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }

            // Journey summary
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(journeyDetails.legs.count) legs")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text("\(journeyDetails.totalDuration) min total")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(journeyDetails.totalStops) stops")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text("Complete journey")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding(12)
            .background(Color.elevatedBackground)
            .cornerRadius(8)

            // Journey timeline
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(journeyDetails.legs.enumerated()), id: \.element.id) { index, leg in
                        JourneyLegView(
                            leg: leg,
                            legIndex: index,
                            totalLegs: journeyDetails.legs.count
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.borderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct JourneyLegView: View {
    let leg: JourneyLeg
    let legIndex: Int
    let totalLegs: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Origin stop
            StopRowView(
                stop: leg.origin,
                isOrigin: true,
                isDestination: false,
                legIndex: legIndex,
                totalLegs: totalLegs,
                showTransfer: legIndex < totalLegs - 1
            )

            // Intermediate stops
            ForEach(Array(leg.intermediateStops.enumerated()), id: \.element.id) { index, stop in
                StopRowView(
                    stop: stop,
                    isOrigin: false,
                    isDestination: false,
                    showConnection: index < leg.intermediateStops.count - 1,
                    legIndex: legIndex,
                    totalLegs: totalLegs,
                    showTransfer: index == leg.intermediateStops.count - 1 && legIndex < totalLegs - 1
                )
            }

            // Destination stop
            StopRowView(
                stop: leg.destination,
                isOrigin: false,
                isDestination: true,
                legIndex: legIndex,
                totalLegs: totalLegs
            )

            // Transfer indicator (if not the last leg)
            if legIndex < totalLegs - 1 {
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.borderColor)
                        .frame(width: 2, height: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Transfer to next leg")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.accentOrange)

                        if let nextLeg = leg.destination.scheduledArrival {
                            Text("Next departure: \(nextLeg.formattedTime())")
                                .font(.system(size: 11, weight: .regular, design: .rounded))
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.leading, 22)
            }
        }
    }
}

struct StopRowView: View {
    let stop: StopInfo
    let isOrigin: Bool
    let isDestination: Bool
    var showConnection: Bool = true
    let legIndex: Int
    let totalLegs: Int
    var showTransfer: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline indicator
            ZStack {
                if isOrigin {
                    Circle()
                        .fill(Color.brandBlue)
                        .frame(width: 12, height: 12)
                } else if isDestination {
                    Circle()
                        .fill(Color.accentGreen)
                        .frame(width: 12, height: 12)
                } else {
                    Circle()
                        .fill(Color.textTertiary)
                        .frame(width: 8, height: 8)
                }

                if showConnection && !isDestination {
                    Rectangle()
                        .fill(Color.borderColor)
                        .frame(width: 2, height: 24)
                        .offset(y: 18)
                }
            }
            .frame(width: 12)

            // Stop information
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    Text(stop.name)
                        .font(.system(size: isOrigin || isDestination ? 16 : 14,
                                    weight: isOrigin || isDestination ? .semibold : .regular,
                                    design: .rounded))
                        .foregroundColor(.textPrimary)

                    if let platform = stop.platform {
                        Text("Platform \(platform)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.elevatedBackground)
                            .cornerRadius(4)
                    }
                }

                // Time information
                HStack(spacing: 12) {
                    if let scheduled = stop.scheduledDeparture ?? stop.scheduledArrival {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(isOrigin ? "Departs" : isDestination ? "Arrives" : "Stops")
                                .font(.system(size: 10, weight: .regular, design: .rounded))
                                .foregroundColor(.textTertiary)
                            Text(scheduled.formattedTime())
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.textPrimary)
                        }
                    }

                    if let actual = stop.actualDeparture ?? stop.actualArrival,
                       let scheduled = stop.scheduledDeparture ?? stop.scheduledArrival {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Actual")
                                .font(.system(size: 10, weight: .regular, design: .rounded))
                                .foregroundColor(.textTertiary)
                            Text(actual.formattedTime())
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(delayColor(delay: actual.timeIntervalSince(scheduled)))
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.leading, 4)
    }

    private func delayColor(delay: TimeInterval) -> Color {
        let delayMinutes = delay / 60
        if delayMinutes > 5 {
            return .errorColor
        } else if delayMinutes > 0 {
            return .warningColor
        } else {
            return .successColor
        }
    }

}