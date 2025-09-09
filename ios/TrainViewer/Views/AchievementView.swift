import SwiftUI

/// Achievement badge view component
struct AchievementBadge: View {
    let type: AchievementType
    let isEarned: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(isEarned ? type.color : Color.gray.opacity(0.3))
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(isEarned ? type.color.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 2)
                )
                .shadow(color: isEarned ? type.color.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)

            Image(systemName: type.iconName)
                .font(.system(size: size * 0.5))
                .foregroundColor(.white)
                .opacity(isEarned ? 1.0 : 0.5)
        }
        .scaleEffect(isEarned ? 1.0 : 0.8)
    }
}

/// Achievement celebration overlay
struct AchievementCelebrationView: View {
    let achievement: AchievementType
    @Binding var isPresented: Bool

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var particles: [Particle] = []

    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGPoint
        var life: Double
        var color: Color
    }

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismiss()
                }

            // Celebration content
            VStack(spacing: 24) {
                ZStack {
                    // Animated background circles
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(achievement.color.opacity(0.2))
                            .frame(width: 200 + CGFloat(index * 40), height: 200 + CGFloat(index * 40))
                            .scaleEffect(scale)
                            .opacity(opacity)
                    }

                    // Main achievement icon
                    ZStack {
                        Circle()
                            .fill(achievement.color)
                            .frame(width: 120, height: 120)
                            .shadow(color: achievement.color.opacity(0.5), radius: 20, x: 0, y: 0)

                        Image(systemName: achievement.iconName)
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(scale)
                }

                VStack(spacing: 12) {
                    Text("Achievement Unlocked!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)

                    Text(achievement.rawValue)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(achievement.color)

                    Text(achievement.description)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                // Celebration particles
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: 8, height: 8)
                        .position(particle.position)
                }
            }
        }
        .onAppear {
            startCelebration()
        }
    }

    private func startCelebration() {
        // Create particles
        particles = (0..<20).map { _ in
            Particle(
                position: CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2),
                velocity: CGPoint(
                    x: CGFloat.random(in: -3...3),
                    y: CGFloat.random(in: -3...3)
                ),
                life: 1.0,
                color: achievement.color.opacity(0.8)
            )
        }

        // Animate entrance
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            scale = 1.0
            opacity = 1.0
        }

        // Animate particles
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            particles = particles.map { particle in
                var updated = particle
                updated.position.x += updated.velocity.x
                updated.position.y += updated.velocity.y
                updated.life -= 0.02
                return updated
            }.filter { $0.life > 0 }

            if particles.isEmpty {
                timer.invalidate()
            }
        }

        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            dismiss()
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
            scale = 0.8
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

/// Achievement progress indicator
struct AchievementProgressView: View {
    let route: Route
    let showAll: Bool

    private var earnedAchievements: [AchievementType] {
        AchievementType.allCases.filter { $0.isEarned(by: route) }
    }

    private var nextAchievement: AchievementType? {
        AchievementType.allCases.first { !$0.isEarned(by: route) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showAll {
                // Show all achievement badges
                HStack(spacing: 8) {
                    ForEach(AchievementType.allCases, id: \.self) { achievement in
                        AchievementBadge(
                            type: achievement,
                            isEarned: achievement.isEarned(by: route),
                            size: 24
                        )
                    }
                }
            } else {
                // Show next achievement progress
                if let next = nextAchievement {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            AchievementBadge(type: next, isEarned: false, size: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(next.rawValue)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(.textPrimary)

                                Text("\(route.usageCount)/\(getTargetCount(for: next)) uses")
                                    .font(.system(size: 10, weight: .regular, design: .rounded))
                                    .foregroundColor(.textSecondary)
                            }
                        }

                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 4)

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(next.color)
                                    .frame(width: geometry.size.width * progress(for: next), height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }
            }
        }
    }

    private func getTargetCount(for achievement: AchievementType) -> Int {
        switch achievement {
        case .firstUse: return 1
        case .regularTraveler: return 10
        case .loyalCommuter: return 50
        case .veteranExplorer: return 100
        case .milestoneMaster: return 250
        }
    }

    private func progress(for achievement: AchievementType) -> CGFloat {
        let target = getTargetCount(for: achievement)
        return min(CGFloat(route.usageCount) / CGFloat(target), 1.0)
    }
}

#Preview {
    VStack(spacing: 20) {
        AchievementBadge(type: .loyalCommuter, isEarned: true, size: 32)
        AchievementBadge(type: .firstUse, isEarned: false, size: 32)

        AchievementProgressView(
            route: Route.create(
                name: "Test Route",
                origin: Place(rawId: nil, name: "Origin", latitude: 0, longitude: 0),
                destination: Place(rawId: nil, name: "Destination", latitude: 0, longitude: 0),
                usageCount: 25
            ),
            showAll: false
        )

        AchievementProgressView(
            route: Route.create(
                name: "Test Route",
                origin: Place(rawId: nil, name: "Origin", latitude: 0, longitude: 0),
                destination: Place(rawId: nil, name: "Destination", latitude: 0, longitude: 0),
                usageCount: 75
            ),
            showAll: true
        )
    }
    .padding()
    .background(Color.brandDark.edgesIgnoringSafeArea(.all))
    .preferredColorScheme(.dark)
}
