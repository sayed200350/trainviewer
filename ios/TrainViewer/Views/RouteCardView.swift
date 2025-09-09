import SwiftUI
import UIKit

/// Modern route card component with Gen Z design aesthetics
struct RouteCardView: View {
    let route: Route
    let status: RouteStatus?
    let onWidgetSelect: (Route) -> Void
    let onEdit: (Route) -> Void
    let onDelete: (Route) -> Void

    @EnvironmentObject var vm: RoutesViewModel

    // Explicit public initializer to ensure accessibility
    public init(
        route: Route,
        status: RouteStatus?,
        onWidgetSelect: @escaping (Route) -> Void,
        onEdit: @escaping (Route) -> Void,
        onDelete: @escaping (Route) -> Void
    ) {
        self.route = route
        self.status = status
        self.onWidgetSelect = onWidgetSelect
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    private var routeStatusColor: Color {
        guard let status = status, !status.options.isEmpty else { return .textSecondary }

        // Check if any options have delays
        let hasDelays = status.options.contains { option in
            if let delay = option.delayMinutes {
                return delay > 0
            }
            return false
        }

        if hasDelays {
            return .warningColor
        }

        // Check if any options have warnings
        let hasWarnings = status.options.contains { option in
            return option.warnings != nil && !option.warnings!.isEmpty
        }

        if hasWarnings {
            return .accentOrange
        }

        return .successColor
    }

    private var routeStatusText: String {
        guard let status = status, !status.options.isEmpty else { return "Fetching..." }

        // Check if any options have delays
        let hasDelays = status.options.contains { option in
            if let delay = option.delayMinutes {
                return delay > 0
            }
            return false
        }

        if hasDelays {
            return "Delayed"
        }

        // Check if any options have warnings
        let hasWarnings = status.options.contains { option in
            return option.warnings != nil && !option.warnings!.isEmpty
        }

        if hasWarnings {
            return "Warning"
        }

        return "On Time"
    }

    private var leaveInText: String? {
        guard let leave = status?.leaveInMinutes else { return nil }
        if leave <= 0 {
            return "Leave now"
        } else if leave == 1 {
            return "Leave in 1 min"
        } else {
            return "Leave in \(leave) min"
        }
    }

    @State private var offset: CGSize = .zero
    @State private var isShowingLeftActions = false
    @State private var isShowingRightActions = false
    @State private var showingDeleteConfirmation = false

    private var swipeThreshold: CGFloat = 80
    private var maxSwipeOffset: CGFloat = 120

    var body: some View {
        ZStack {
            // Loading overlay when status is being fetched
            if status == nil {
                VStack(alignment: .leading, spacing: 12) {
                    // Header skeleton
                    HStack(alignment: .center, spacing: 12) {
                        SkeletonView(height: 12, width: 12, cornerRadius: 6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(route.name)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.textPrimary)

                            HStack(spacing: 8) {
                                SkeletonView(height: 12, width: 60, cornerRadius: 4)
                                Text("Fetching...")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.textSecondary)
                            }
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Button(action: {
                                var updatedRoute = route
                                updatedRoute.toggleFavorite()
                            }) {
                                Image(systemName: route.isFavorite ? "heart.fill" : "heart")
                                    .foregroundColor(route.isFavorite ? .accentRed : .textSecondary)
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(.borderless)

                            Button(action: { onWidgetSelect(route) }) {
                                HStack(spacing: 4) {
                                    Image(systemName: vm.getSelectedWidgetRoute()?.id == route.id ? "star.fill" : "star")
                                        .foregroundColor(vm.getSelectedWidgetRoute()?.id == route.id ? .accentOrange : .textSecondary)
                                        .font(.system(size: 14))
                                    Text("Widget")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.textSecondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(vm.getSelectedWidgetRoute()?.id == route.id ?
                                             Color.accentOrange.opacity(0.1) : Color.gray.opacity(0.1))
                                )
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    // Route path visualization
                    HStack(spacing: 8) {
                        VStack(spacing: 2) {
                            Circle()
                                .fill(Color.brandBlue)
                                .frame(width: 8, height: 8)
                            Rectangle()
                                .fill(Color.borderColor)
                                .frame(width: 2, height: 16)
                            Circle()
                                .fill(Color.accentGreen)
                                .frame(width: 8, height: 8)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(route.origin.name)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)

                            Text(route.destination.name)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)
                        }
                    }

                    // Loading departures
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Next departures")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.textSecondary)

                        HStack(spacing: 12) {
                            ForEach(0..<3) { _ in
                                VStack(spacing: 2) {
                                    SkeletonView(height: 13, width: 45, cornerRadius: 4)
                                    SkeletonView(height: 11, width: 45, cornerRadius: 4)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.elevatedBackground)
                                .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else {
                // Left action (Delete)
                if offset.width < 0 {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        Text("Delete")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: abs(min(offset.width, maxSwipeOffset)))
                    .frame(maxHeight: .infinity)
                    .background(Color.errorColor.opacity(0.9))
                    .cornerRadius(12)
                    .shadow(color: Color.errorColor.opacity(0.3), radius: 8, x: 0, y: 0)
                }
            }

            // Right action (Favorite)
            if offset.width > 0 {
                HStack {
                    VStack(spacing: 8) {
                        Image(systemName: route.isFavorite ? "heart.slash.fill" : "heart.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        Text(route.isFavorite ? "Unfavorite" : "Favorite")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: min(offset.width, maxSwipeOffset))
                    .frame(maxHeight: .infinity)
                    .background(route.isFavorite ? Color.warningColor.opacity(0.9) : Color.accentRed.opacity(0.9))
                    .cornerRadius(12)
                    .shadow(color: (route.isFavorite ? Color.warningColor : Color.accentRed).opacity(0.3), radius: 8, x: 0, y: 0)
                    Spacer()
                }
            }

            // Main card content
            VStack(alignment: .leading, spacing: 12) {
                // Header with route name and status
                HStack(alignment: .center, spacing: 12) {
                // Color indicator
                Circle()
                    .fill(route.color.color)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(route.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)

                    HStack(spacing: 8) {
                        if let leaveText = leaveInText {
                            Text(leaveText)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(routeStatusColor)
                        }

                        Text(routeStatusText)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.textSecondary)
                    }

                    // Achievement badges
                    if route.usageCount > 0 {
                        HStack(spacing: 4) {
                            ForEach(AchievementType.allCases.filter { $0.isEarned(by: route) }.prefix(3), id: \.self) { achievement in
                                AchievementBadge(type: achievement, isEarned: true, size: 14)
                            }
                        }
                        .padding(.top, 2)
                    }
                }

                Spacer()

                // Quick actions
                HStack(spacing: 8) {
                    // Favorite button
                    Button(action: {
                        var updatedRoute = route
                        updatedRoute.toggleFavorite()
                        // TODO: Update route in view model
                    }) {
                        Image(systemName: route.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(route.isFavorite ? .accentRed : .textSecondary)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.borderless)

                    // Widget button
                    Button(action: { onWidgetSelect(route) }) {
                        HStack(spacing: 4) {
                            Image(systemName: vm.getSelectedWidgetRoute()?.id == route.id ? "star.fill" : "star")
                                .foregroundColor(vm.getSelectedWidgetRoute()?.id == route.id ? .accentOrange : .textSecondary)
                                .font(.system(size: 14))
                            Text("Widget")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(vm.getSelectedWidgetRoute()?.id == route.id ?
                                     Color.accentOrange.opacity(0.1) : Color.gray.opacity(0.1))
                        )
                    }
                    .buttonStyle(.borderless)
                }
            }

            // Route path visualization
            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    Circle()
                        .fill(Color.brandBlue)
                        .frame(width: 8, height: 8)
                    Rectangle()
                        .fill(Color.borderColor)
                        .frame(width: 2, height: 16)
                    Circle()
                        .fill(Color.accentGreen)
                        .frame(width: 8, height: 8)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(route.origin.name)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)

                    Text(route.destination.name)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                }
            }

            // Upcoming departures preview
            if let options = status?.options, !options.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Next departures")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.textSecondary)

                    HStack(spacing: 12) {
                        ForEach(options.prefix(3)) { option in
                            VStack(spacing: 2) {
                                Text(formatTime(option.departure))
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.textPrimary)

                                Text(formatTime(option.arrival))
                                    .font(.system(size: 11, weight: .regular, design: .rounded))
                                    .foregroundColor(.textSecondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.elevatedBackground)
                            .cornerRadius(6)
                        }
                    }
                }
                }
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            .offset(x: offset.width)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        let translation = gesture.translation.width
                        // Limit the swipe distance
                        if translation > 0 {
                            // Right swipe (favorite)
                            offset.width = min(translation, maxSwipeOffset)
                        } else {
                            // Left swipe (delete)
                            offset.width = max(translation, -maxSwipeOffset)
                        }
                    }
                    .onEnded { gesture in
                        let translation = gesture.translation.width

                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if translation > swipeThreshold {
                                // Right swipe - toggle favorite
                                handleFavoriteToggle()
                                offset = .zero
                            } else if translation < -swipeThreshold {
                                // Left swipe - show delete confirmation
                                showingDeleteConfirmation = true
                                offset = .zero
                            } else {
                                // Not enough swipe distance, return to original position
                                offset = .zero
                            }
                        }
                    }
            )
            .confirmationDialog("Delete Route", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    onDelete(route)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete '\(route.name)'? This action cannot be undone.")
            }
            }
        }
    }

    private func handleFavoriteToggle() {
        // Create a haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Toggle favorite in the view model
        vm.toggleFavorite(for: route)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    let sampleRoute = Route.create(
        name: "Home to Work",
        origin: Place(rawId: nil, name: "Alexanderplatz", latitude: 52.5219, longitude: 13.4132),
        destination: Place(rawId: nil, name: "Friedrichstraße", latitude: 52.5176, longitude: 13.3889),
        color: .blue,
        isFavorite: true
    )

    let sampleStatus = RouteStatus(
        options: [
            JourneyOption(
                departure: Date().addingTimeInterval(600),
                arrival: Date().addingTimeInterval(1800),
                totalMinutes: 20
            ),
            JourneyOption(
                departure: Date().addingTimeInterval(1200),
                arrival: Date().addingTimeInterval(2100),
                totalMinutes: 15
            )
        ],
        leaveInMinutes: 5,
        lastUpdated: Date()
    )

    RouteCardView(
        route: sampleRoute,
        status: sampleStatus,
        onWidgetSelect: { _ in },
        onEdit: { _ in },
        onDelete: { _ in }
    )
    .environmentObject(RoutesViewModel())
    .padding()
    .background(Color.brandDark)
    .previewLayout(.sizeThatFits)
}
