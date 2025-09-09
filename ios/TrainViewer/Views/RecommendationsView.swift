import SwiftUI

/// Personalized route recommendations based on user behavior
struct RecommendationsView: View {
    @EnvironmentObject var vm: RoutesViewModel
    @State private var selectedTimeOfDay: TimeOfDay = .now
    @State private var recommendations: [RouteRecommendation] = []


    var body: some View {
        NavigationView {
            ZStack {
                Color.brandDark.edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Smart Recommendations")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)

                                Text("Routes you'll love based on your habits")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(.textSecondary)
                            }
                            Spacer()
                        }

                        // Time of day selector
                        HStack(spacing: 12) {
                            ForEach(TimeOfDay.allCases, id: \.self) { timeOfDay in
                                TimeOfDayButton(
                                    timeOfDay: timeOfDay,
                                    isSelected: selectedTimeOfDay == timeOfDay,
                                    action: { selectedTimeOfDay = timeOfDay }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .background(Color.brandDark)

                    // Recommendations list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(recommendations) { recommendation in
                                RecommendationCard(recommendation: recommendation)
                            }

                            if recommendations.isEmpty {
                                emptyRecommendationsView
                            }
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                generateRecommendations()
            }
            .onChange(of: selectedTimeOfDay) { _ in
                generateRecommendations()
            }
        }
    }

    private var emptyRecommendationsView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.brandBlue.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundColor(.brandBlue)
            }

            VStack(spacing: 12) {
                Text("Getting to know your habits")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Use your routes a few more times and we'll start giving you personalized recommendations!")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
    }

    private func generateRecommendations() {
        recommendations = vm.generateRecommendations(for: selectedTimeOfDay)
    }
}

/// Time of day selector button
struct TimeOfDayButton: View {
    let timeOfDay: TimeOfDay
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: timeOfDay.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : .textSecondary)

                Text(timeOfDay.rawValue)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : .textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentGreen : Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentGreen.opacity(0.3) : Color.borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Individual recommendation card
struct RecommendationCard: View {
    let recommendation: RouteRecommendation
    @EnvironmentObject var vm: RoutesViewModel

    var body: some View {
        HStack(spacing: 16) {
            // Route indicator
            VStack(spacing: 4) {
                Circle()
                    .fill(recommendation.route.color.color)
                    .frame(width: 12, height: 12)

                Rectangle()
                    .fill(Color.borderColor)
                    .frame(width: 2, height: 20)
                    .cornerRadius(1)

                Circle()
                    .fill(Color.accentGreen)
                    .frame(width: 8, height: 8)
            }

            VStack(alignment: .leading, spacing: 8) {
                // Route name and reason
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recommendation.route.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.textPrimary)

                        Text(recommendation.reason)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    // Confidence indicator
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            ForEach(0..<recommendation.confidenceLevel, id: \.self) { _ in
                                Circle()
                                    .fill(Color.accentGreen)
                                    .frame(width: 4, height: 4)
                            }
                        }

                        Text("\(Int(recommendation.confidenceScore * 100))%")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.accentGreen)
                    }
                }

                // Route preview
                HStack(spacing: 8) {
                    Text(recommendation.route.origin.name)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)

                    Text(recommendation.route.destination.name)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                }

                // Usage stats
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)

                        Text("\(recommendation.route.usageCount) trips")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.textSecondary)
                    }

                    if let lastUsed = recommendation.lastUsed {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)

                            Text(lastUsed.formattedTimeAgo())
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.textSecondary)
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
    }
}

// MARK: - Extensions
extension Date {
    func formattedTimeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    RecommendationsView()
        .environmentObject(RoutesViewModel())
        .preferredColorScheme(.dark)
}
