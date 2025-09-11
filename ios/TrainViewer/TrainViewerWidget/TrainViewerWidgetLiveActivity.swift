//
//  TrainViewerLiveActivity.swift
//  TrainViewerWidget
//
//  Created by Xcode Template
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Attributes
struct BahnBlitzAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var routeName: String
        var leaveInMinutes: Int
        var departureTime: Date
        var arrivalTime: Date
        var platform: String?
        var lineName: String?
        var delayMinutes: Int?
        var walkingTime: Int?
        var status: String
    }

    var routeId: String
    var originName: String
    var destinationName: String
}

// MARK: - Live Activity Widget
struct BahnBlitzLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BahnBlitzAttributes.self) { context in
            // Lock screen/banner UI
            BahnBlitzLockScreenLiveActivityView(context: context)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.originName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.attributes.destinationName)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatTime(context.state.departureTime))
                            .font(.title3)
                            .fontWeight(.semibold)
                        if let delay = context.state.delayMinutes, delay > 0 {
                            Text("+\(delay)min")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 8) {
                        if let platform = context.state.platform {
                            Label(platform, systemImage: "tram.fill")
                                .font(.caption)
                        }
                        if let walkingTime = context.state.walkingTime {
                            Label("\(walkingTime)min", systemImage: "figure.walk")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.secondary)
                }
            } compactLeading: {
                Image(systemName: "tram.fill")
                    .foregroundColor(.blue)
            } compactTrailing: {
                Text(formatTime(context.state.departureTime))
                    .font(.system(size: 12, weight: .semibold))
            } minimal: {
                Image(systemName: "tram.fill")
                    .foregroundColor(.blue)
            }
        }
    }

    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "delayed": return .orange
        case "cancelled": return .red
        default: return .blue
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Lock Screen View
struct BahnBlitzLockScreenLiveActivityView: View {
    let context: ActivityViewContext<BahnBlitzAttributes>

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor(for: context.state.status))
                    .frame(width: 40, height: 40)

                Image(systemName: "tram.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.routeName)
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Text(context.attributes.originName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    Image(systemName: "arrow.right")
                        .font(.caption)
                    Text(context.attributes.destinationName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }

                HStack(spacing: 8) {
                    Text(formatTime(context.state.departureTime))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    if let delay = context.state.delayMinutes, delay > 0 {
                        Text("+\(delay)min")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                if context.state.leaveInMinutes <= 0 {
                    Text("DEPART NOW")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                } else {
                    Text("Leave in \(context.state.leaveInMinutes) min")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .activityBackgroundTint(statusColor(for: context.state.status))
    }

    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "delayed": return .orange
        case "cancelled": return .red
        default: return .blue
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
