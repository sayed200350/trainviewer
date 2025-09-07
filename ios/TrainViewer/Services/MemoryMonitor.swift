import Foundation
import UIKit
import Combine

/// Monitors memory usage and handles memory pressure events
@MainActor
final class MemoryMonitor: ObservableObject {
    static let shared = MemoryMonitor()
    
    @Published var currentMemoryUsage: Int64 = 0
    @Published var isMemoryPressureHigh: Bool = false
    @Published var memoryWarningCount: Int = 0
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let memoryThresholdMB: Int64 = 150 // Alert when app uses more than 150MB
    
    // Memory pressure levels
    enum MemoryPressureLevel {
        case normal
        case warning
        case critical
        
        var description: String {
            switch self {
            case .normal: return "Normal"
            case .warning: return "Warning"
            case .critical: return "Critical"
            }
        }
    }
    
    @Published var currentPressureLevel: MemoryPressureLevel = .normal
    
    private init() {
        setupMemoryWarningNotification()
        startMonitoring()
    }
    
    deinit {
        // Perform cleanup directly to avoid main actor isolation issues
        timer?.invalidate()
        timer = nil
        print("📊 [MemoryMonitor] Stopped monitoring memory usage (deinit)")
    }
    
    // MARK: - Public Interface
    
    /// Start monitoring memory usage
    func startMonitoring() {
        guard timer == nil else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemoryUsage()
            }
        }
        
        updateMemoryUsage()
        print("📊 [MemoryMonitor] Started monitoring memory usage")
    }
    
    /// Stop monitoring memory usage
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        print("📊 [MemoryMonitor] Stopped monitoring memory usage")
    }
    
    /// Handle memory pressure by clearing caches and reducing memory usage
    func handleMemoryPressure() {
        print("⚠️ [MemoryMonitor] Handling memory pressure")
        
        // Clear image caches
        URLCache.shared.removeAllCachedResponses()
        
        // Clear any custom caches
        NotificationCenter.default.post(name: .memoryPressureDetected, object: nil)
        
        // Update pressure level
        currentPressureLevel = .critical
        isMemoryPressureHigh = true
        
        // Schedule pressure level reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.currentPressureLevel = .normal
            self?.isMemoryPressureHigh = false
        }
    }
    
    /// Get current memory usage in MB
    var memoryUsageMB: Double {
        return Double(currentMemoryUsage) / 1024.0 / 1024.0
    }
    
    /// Get memory usage as a percentage of available memory
    var memoryUsagePercentage: Double {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        return Double(currentMemoryUsage) / Double(totalMemory) * 100.0
    }
    
    // MARK: - Private Implementation
    
    private func setupMemoryWarningNotification() {
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.memoryWarningReceived()
                }
            }
            .store(in: &cancellables)
    }
    
    private func memoryWarningReceived() {
        memoryWarningCount += 1
        handleMemoryPressure()
        print("🚨 [MemoryMonitor] Memory warning received (count: \(memoryWarningCount))")
    }
    
    private func updateMemoryUsage() {
        currentMemoryUsage = getMemoryUsage()
        
        let usageMB = memoryUsageMB
        
        // Update pressure level based on usage
        if usageMB > Double(memoryThresholdMB) {
            if currentPressureLevel == .normal {
                currentPressureLevel = .warning
                isMemoryPressureHigh = true
                print("⚠️ [MemoryMonitor] Memory usage high: \(String(format: "%.1f", usageMB))MB")
            }
        } else if usageMB < Double(memoryThresholdMB) * 0.8 {
            if currentPressureLevel != .normal {
                currentPressureLevel = .normal
                isMemoryPressureHigh = false
                print("✅ [MemoryMonitor] Memory usage normalized: \(String(format: "%.1f", usageMB))MB")
            }
        }
    }
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let memoryPressureDetected = Notification.Name("memoryPressureDetected")
}

// MARK: - Memory Statistics

struct MemoryStatistics {
    let currentUsageMB: Double
    let peakUsageMB: Double
    let averageUsageMB: Double
    let memoryWarningCount: Int
    let pressureLevel: MemoryMonitor.MemoryPressureLevel
    
    var description: String {
        return """
        Memory Statistics:
        - Current: \(String(format: "%.1f", currentUsageMB))MB
        - Peak: \(String(format: "%.1f", peakUsageMB))MB
        - Average: \(String(format: "%.1f", averageUsageMB))MB
        - Warnings: \(memoryWarningCount)
        - Pressure: \(pressureLevel.description)
        """
    }
}

extension MemoryMonitor {
    /// Get comprehensive memory statistics
    func getStatistics() -> MemoryStatistics {
        return MemoryStatistics(
            currentUsageMB: memoryUsageMB,
            peakUsageMB: memoryUsageMB, // TODO: Track peak usage
            averageUsageMB: memoryUsageMB, // TODO: Track average usage
            memoryWarningCount: memoryWarningCount,
            pressureLevel: currentPressureLevel
        )
    }
}