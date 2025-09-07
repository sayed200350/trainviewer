import SwiftUI

struct RefreshIntervalSettingsView: View {
    @Binding var selectedInterval: RefreshInterval
    let route: Route?
    let onIntervalChanged: (RefreshInterval) -> Void
    
    @State private var showingAdaptiveInfo = false
    @State private var showingBatteryInfo = false
    
    private let adaptiveService = AdaptiveRefreshService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Refresh Interval")
                    .font(.headline)
                
                Text("How often should this route check for updates?")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Interval Selection
            VStack(alignment: .leading, spacing: 12) {
                ForEach(RefreshInterval.allCases, id: \.self) { interval in
                    RefreshIntervalRow(
                        interval: interval,
                        isSelected: selectedInterval == interval,
                        route: route,
                        onTap: {
                            selectedInterval = interval
                            onIntervalChanged(interval)
                        }
                    )
                }
            }
            
            // Adaptive Information
            if let route = route {
                AdaptiveRefreshInfoView(route: route)
            }
            
            // Battery Optimization Info
            BatteryOptimizationInfoView()
        }
        .padding()
    }
}

struct RefreshIntervalRow: View {
    let interval: RefreshInterval
    let isSelected: Bool
    let route: Route?
    let onTap: () -> Void
    
    @State private var adaptiveInterval: TimeInterval?
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(interval.displayName)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if let route = route, let adaptive = adaptiveInterval {
                        Text("Adaptive: \(formatInterval(adaptive))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if interval == .manual {
                        Text("Updates only when you open the app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            calculateAdaptiveInterval()
        }
    }
    
    private func calculateAdaptiveInterval() {
        guard let route = route else { return }
        
        let service = AdaptiveRefreshService.shared
        adaptiveInterval = service.getAdaptiveRefreshInterval(for: route)
    }
    
    private func formatInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
}

struct AdaptiveRefreshInfoView: View {
    let route: Route
    
    @State private var refreshStrategy: RefreshStrategy = .normal
    @State private var efficiencyScore: Double = 1.0
    @State private var showingDetails = false
    
    private let adaptiveService = AdaptiveRefreshService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { showingDetails.toggle() }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Adaptive Refresh")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Strategy: \(refreshStrategy.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if showingDetails {
                VStack(alignment: .leading, spacing: 8) {
                    Text(refreshStrategy.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Efficiency Score:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(efficiencyScore * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(efficiencyColor)
                    }
                    
                    // Battery optimization suggestions
                    let suggestions = adaptiveService.getBatteryOptimizationSuggestions()
                    if !suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "info.circle")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    
                                    Text(suggestion)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
        .onAppear {
            updateAdaptiveInfo()
        }
    }
    
    private var efficiencyColor: Color {
        if efficiencyScore > 0.8 {
            return .green
        } else if efficiencyScore > 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func updateAdaptiveInfo() {
        refreshStrategy = adaptiveService.getRefreshStrategy(for: route)
        efficiencyScore = adaptiveService.getRefreshEfficiencyScore(for: route)
    }
}

struct BatteryOptimizationInfoView: View {
    @State private var batteryLevel: Float = 1.0
    @State private var isCharging: Bool = false
    @State private var showingBatteryDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { showingBatteryDetails.toggle() }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Battery Optimization")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Battery: \(Int(batteryLevel * 100))%\(isCharging ? " (Charging)" : "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: showingBatteryDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if showingBatteryDetails {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Refresh intervals automatically adjust based on battery level and charging status to optimize battery life.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if batteryLevel < 0.2 && !isCharging {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "battery.25")
                                .font(.caption)
                                .foregroundColor(.red)
                            
                            Text("Low battery detected. Refresh intervals are increased to preserve battery life.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if isCharging {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Text("Device is charging. Normal refresh intervals are used.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
        .onAppear {
            updateBatteryInfo()
        }
    }
    
    private func updateBatteryInfo() {
        batteryLevel = UIDevice.current.batteryLevel
        isCharging = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
    }
}

// MARK: - Preview

struct RefreshIntervalSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        RefreshIntervalSettingsView(
            selectedInterval: .constant(.fiveMinutes),
            route: Route.create(
                name: "Home → Work",
                origin: Place(rawId: "1", name: "Home", latitude: 52.5, longitude: 13.4),
                destination: Place(rawId: "2", name: "Work", latitude: 52.6, longitude: 13.5)
            ),
            onIntervalChanged: { _ in }
        )
        .previewLayout(.sizeThatFits)
    }
}