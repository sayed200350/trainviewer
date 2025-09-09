import SwiftUI

/// Skeleton loading view component for smooth loading experiences
struct SkeletonView: View {
    let height: CGFloat
    let width: CGFloat?
    let cornerRadius: CGFloat

    @State private var isAnimating = false

    private var gradientColors: [Color] {
        [
            Color.gray.opacity(0.2),
            Color.gray.opacity(0.3),
            Color.gray.opacity(0.2)
        ]
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.cardBackground)
                .frame(width: width, height: height)

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: width ?? height, height: height)
                .offset(x: isAnimating ? (width ?? height) : -(width ?? height))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .frame(width: width, height: height)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

/// Skeleton route card for loading states
struct RouteCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header skeleton
            HStack(alignment: .center, spacing: 12) {
                // Color indicator skeleton
                SkeletonView(height: 12, width: 12, cornerRadius: 6)

                VStack(alignment: .leading, spacing: 4) {
                    // Route name skeleton
                    SkeletonView(height: 16, width: 120, cornerRadius: 4)

                    // Status skeleton
                    HStack(spacing: 8) {
                        SkeletonView(height: 12, width: 60, cornerRadius: 4)
                        SkeletonView(height: 12, width: 40, cornerRadius: 4)
                    }
                }

                Spacer()

                // Action buttons skeleton
                HStack(spacing: 8) {
                    SkeletonView(height: 16, width: 16, cornerRadius: 4)
                    SkeletonView(height: 24, width: 50, cornerRadius: 6)
                }
            }

            // Route path visualization skeleton
            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    SkeletonView(height: 8, width: 8, cornerRadius: 4)
                    SkeletonView(height: 16, width: 2, cornerRadius: 1)
                    SkeletonView(height: 8, width: 8, cornerRadius: 4)
                }

                VStack(alignment: .leading, spacing: 2) {
                    SkeletonView(height: 14, width: 100, cornerRadius: 4)
                    SkeletonView(height: 14, width: 80, cornerRadius: 4)
                }
            }

            // Departures preview skeleton
            VStack(alignment: .leading, spacing: 6) {
                SkeletonView(height: 12, width: 80, cornerRadius: 4)

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
    }
}

/// Skeleton empty state for initial loading
struct EmptyStateSkeleton: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    SkeletonView(height: 120, width: 120, cornerRadius: 60)

                    SkeletonView(height: 48, width: 48, cornerRadius: 24)
                        .offset(y: -8)
                }

                VStack(spacing: 16) {
                    SkeletonView(height: 28, width: 200, cornerRadius: 4)
                    SkeletonView(height: 16, width: 280, cornerRadius: 4)
                    SkeletonView(height: 16, width: 240, cornerRadius: 4)
                }
            }

            VStack(spacing: 16) {
                SkeletonView(height: 50, width: 280, cornerRadius: 12)

                VStack(spacing: 12) {
                    ForEach(0..<3) { _ in
                        HStack(spacing: 12) {
                            SkeletonView(height: 16, width: 16, cornerRadius: 4)
                            SkeletonView(height: 14, width: 120, cornerRadius: 4)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

/// Loading overlay with skeleton cards
struct LoadingRoutesView: View {
    let count: Int

    var body: some View {
        VStack(spacing: 16) {
            // Header skeleton
            HStack {
                SkeletonView(height: 20, width: 120, cornerRadius: 4)
                Spacer()
                SkeletonView(height: 14, width: 40, cornerRadius: 6)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.elevatedBackground)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)

            // Route cards skeleton
            ForEach(0..<count) { _ in
                RouteCardSkeleton()
                    .padding(.horizontal, 20)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SkeletonView(height: 20, width: 150, cornerRadius: 4)
        RouteCardSkeleton()
        EmptyStateSkeleton()
    }
    .padding()
    .background(Color.brandDark.edgesIgnoringSafeArea(.all))
    .preferredColorScheme(.dark)
}
