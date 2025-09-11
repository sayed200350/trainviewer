import SwiftUI
import WidgetKit

extension View {
    func cardStyle() -> some View {
        self
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MainView: View {
    @EnvironmentObject var vm: RoutesViewModel
    @State private var showingAdd = false
    @State private var editingRoute: Route?
    @State private var showingSettings = false
    @State private var showingSemesterTickets = false
    @State private var toast: Toast?
    @State private var lastWidgetSelection: Route?

    var body: some View {
        NavigationView {
            ZStack {
                Color.brandDark.edgesIgnoringSafeArea(.all)

            Group {
                if vm.routes.isEmpty {
                    if vm.isRefreshing {
                        LoadingRoutesView(count: 3)
                    } else {
                        enhancedEmptyState
                    }
                } else {
                    mainContentView
                }
            }

                // Floating Action Button
                if !vm.routes.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                                    Spacer()
                            FloatingActionButton(action: { showingAdd = true })
                        }
                    }
                    .edgesIgnoringSafeArea(.bottom)
                }
            }
            .navigationTitle("BahnBlitz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            WidgetCenter.shared.reloadAllTimelines()
                            toast = Toast(message: "Widget refreshed")
                        }) {
                            Image(systemName: "arrow.clockwise.circle")
                                .foregroundColor(.accentOrange)
                        }
                        Button(action: { showingSemesterTickets = true }) {
                            Image(systemName: "ticket")
                                .foregroundColor(.brandBlue)
                        }
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gearshape")
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAdd, onDismiss: {
                vm.loadRoutes()
                Task { await vm.refreshAll() }
            }) {
                AddRouteView()
            }
            .sheet(item: $editingRoute, onDismiss: {
                vm.loadRoutes()
                Task { await vm.refreshAll() }
            }) { route in
                EditRouteView(route: route, routesViewModel: vm)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingSemesterTickets) {
                SemesterTicketListView()
            }
        }
        .toast($toast)
        .onChange(of: vm.isOffline) { isOffline in
            if isOffline { toast = Toast(message: "Offline – showing cached data") }
        }
        .overlay(
            Group {
                if vm.showAchievementCelebration, let achievement = vm.achievementToCelebrate {
                    AchievementCelebrationView(achievement: achievement, isPresented: $vm.showAchievementCelebration)
                }
            }
        )
        .preferredColorScheme(.dark)
    }

    private var enhancedEmptyState: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.brandBlue.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "tram.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.brandBlue)
                }

                VStack(spacing: 16) {
                    Text("Welcome to BahnBlitz")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Let's get you to your destination on time. Start by adding your first route.")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }

            VStack(spacing: 16) {
                Button(action: { showingAdd = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Add Your First Route")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentGreen)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.accentGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                }

                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.accentOrange)
                            .font(.system(size: 16))
                        Text("Never miss your train again")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.textSecondary)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.brandBlue)
                            .font(.system(size: 16))
                        Text("Smart notifications & reminders")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.textSecondary)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.accentGreen)
                            .font(.system(size: 16))
                        Text("Real-time updates & delays")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.textSecondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var mainContentView: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                statusIndicatorsSection
                routesSection
                widgetHintSection
            }
            .padding(.vertical, 20)
        }
        .refreshable { await vm.refreshAll() }
    }

    private var statusIndicatorsSection: some View {
        Group {
            if vm.isOffline {
                statusCard(
                    icon: "wifi.slash",
                    title: "Offline Mode",
                    message: "Showing cached data",
                    color: .warningColor
                )
            }

            if let classCard = vm.nextClass {
                nextClassCard(classCard)
            }

            if let selectedWidgetRoute = vm.getSelectedWidgetRoute() {
                widgetRouteCard(selectedWidgetRoute)
            }
        }
    }

    private var routesSection: some View {
        VStack(spacing: 16) {
            routesHeader
            routesList
        }
    }

    private var routesHeader: some View {
        HStack {
            Text("Your Routes")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            Spacer()
            Text("\(vm.routes.count)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.elevatedBackground)
                .cornerRadius(8)
        }
        .padding(.horizontal, 20)
    }

    private var routesList: some View {
        Group {
            ForEach(vm.routes) { route in
                NavigationLink(destination: RouteDetailView(route: route).environmentObject(vm)) {
                    routeCardView(for: route)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(action: { editingRoute = route }) {
                        Label("Edit Route", systemImage: "pencil")
                    }
                    Button(action: {
                        vm.deleteRouteByObject(route)
                        toast = Toast(message: "Route deleted")
                    }) {
                        Label("Delete Route", systemImage: "trash")
                    }
                }
            }
            .padding(.horizontal, 20)

            // Show loading skeleton for additional routes during refresh
            if vm.isRefreshing && vm.routes.count < 3 {
                ForEach(0..<(3 - vm.routes.count)) { _ in
                    RouteCardSkeleton()
                        .padding(.horizontal, 20)
                        .opacity(0.7)
                }
            }
        }
    }

    private func routeCardView(for route: Route) -> some View {
        RouteCardView(
            route: route,
            status: vm.statusByRouteId[route.id],
            onWidgetSelect: { selectedRoute in
                vm.selectRouteForWidget(routeId: selectedRoute.id)
                lastWidgetSelection = selectedRoute
                toast = Toast(message: "Widget updated to show '\(selectedRoute.name)'")
            },
            onEdit: { editingRoute = $0 },
            onDelete: { vm.deleteRouteByObject($0) }
        )
    }

    private var widgetHintSection: some View {
        Group {
            if !vm.routes.isEmpty && vm.getSelectedWidgetRoute() == nil {
                widgetHintCard()
            }
        }
    }

    private func statusCard(icon: String, title: String, message: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                Text(message)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .cardStyle()
        .padding(.horizontal, 20)
    }

    private func nextClassCard(_ classCard: ClassSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "graduationcap.fill")
                    .foregroundColor(.accentOrange)
                    .font(.system(size: 16))
                Text("Next Class")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(classCard.eventTitle)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text("Leave in \(classCard.leaveInMinutes) min • via \(classCard.routeName)")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(16)
        .cardStyle()
        .padding(.horizontal, 20)
    }

    private func widgetRouteCard(_ route: Route) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .foregroundColor(.accentOrange)
                .font(.system(size: 16))

            VStack(alignment: .leading, spacing: 2) {
                Text("Widget Route")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text(route.name)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Text("Active")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.accentGreen)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentGreen.opacity(0.1))
                .cornerRadius(6)
        }
        .padding(16)
        .cardStyle()
        .padding(.horizontal, 20)
    }

    private func widgetHintCard() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .foregroundColor(.accentOrange)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text("Choose Widget Route")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text("Tap 'Widget' on any route to display it on your home screen")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .cardStyle()
        .padding(.horizontal, 20)
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.accentGreen)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.accentGreen.opacity(0.3), radius: 8, x: 0, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}
