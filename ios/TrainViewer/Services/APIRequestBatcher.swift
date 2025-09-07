import Foundation
import Combine
import CoreLocation

/// Batches multiple API requests to improve efficiency and reduce network overhead
final class APIRequestBatcher {
    static let shared = APIRequestBatcher()
    
    private let batchInterval: TimeInterval = 0.5 // 500ms batching window
    private let maxBatchSize: Int = 10
    private var pendingRequests: [BatchableRequest] = []
    private var batchTimer: Timer?
    private let queue = DispatchQueue(label: "APIRequestBatcher", qos: .userInitiated)
    
    // Request priority levels
    enum RequestPriority: Int, Comparable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3
        
        static func < (lhs: RequestPriority, rhs: RequestPriority) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
    
    // Batchable request wrapper
    struct BatchableRequest {
        let id: UUID = UUID()
        let route: Route
        let priority: RequestPriority
        let requestedAt: Date = Date()
        let completion: (Result<[JourneyOption], Error>) -> Void
        
        var isExpired: Bool {
            Date().timeIntervalSince(requestedAt) > 30.0 // 30 second timeout
        }
    }
    
    // Batch result
    struct BatchResult {
        let routeId: UUID
        let journeyOptions: [JourneyOption]?
        let error: Error?
    }
    
    private init() {}
    
    // MARK: - Public Interface
    
    /// Add a route request to the batch queue
    func addRequest(
        for route: Route,
        priority: RequestPriority = .normal,
        completion: @escaping (Result<[JourneyOption], Error>) -> Void
    ) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Check if we already have a pending request for this route
            if let existingIndex = self.pendingRequests.firstIndex(where: { $0.route.id == route.id }) {
                // Replace with higher priority request if applicable
                let existingRequest = self.pendingRequests[existingIndex]
                if priority > existingRequest.priority {
                    self.pendingRequests[existingIndex] = BatchableRequest(
                        route: route,
                        priority: priority,
                        completion: completion
                    )
                    print("🔄 [APIRequestBatcher] Updated request priority for route: \(route.name)")
                } else {
                    // Call completion with coalesced result
                    completion(.failure(APIError.requestCoalesced))
                }
                return
            }
            
            let request = BatchableRequest(
                route: route,
                priority: priority,
                completion: completion
            )
            
            self.pendingRequests.append(request)
            print("📦 [APIRequestBatcher] Added request for route: \(route.name) (priority: \(priority))")
            
            self.scheduleBatchProcessing()
        }
    }
    
    /// Process all pending requests immediately
    func flushPendingRequests() {
        queue.async { [weak self] in
            self?.processBatch()
        }
    }
    
    /// Get current batch statistics
    func getBatchStatistics() -> BatchStatistics {
        return queue.sync {
            return BatchStatistics(
                pendingRequestCount: pendingRequests.count,
                highPriorityCount: pendingRequests.filter { $0.priority >= .high }.count,
                expiredRequestCount: pendingRequests.filter { $0.isExpired }.count
            )
        }
    }
    
    // MARK: - Private Implementation
    
    private func scheduleBatchProcessing() {
        // Cancel existing timer
        batchTimer?.invalidate()
        
        // Check if we should process immediately
        if pendingRequests.count >= maxBatchSize || pendingRequests.contains(where: { $0.priority == .critical }) {
            processBatch()
            return
        }
        
        // Schedule batch processing
        DispatchQueue.main.async { [weak self] in
            self?.batchTimer = Timer.scheduledTimer(withTimeInterval: self?.batchInterval ?? 0.5, repeats: false) { _ in
                self?.queue.async {
                    self?.processBatch()
                }
            }
        }
    }
    
    private func processBatch() {
        guard !pendingRequests.isEmpty else { return }
        
        // Remove expired requests
        let expiredRequests = pendingRequests.filter { $0.isExpired }
        pendingRequests.removeAll { $0.isExpired }
        
        // Notify expired requests
        for expiredRequest in expiredRequests {
            expiredRequest.completion(.failure(APIError.network(URLError(.timedOut))))
        }
        
        guard !pendingRequests.isEmpty else { return }
        
        // Sort by priority (highest first)
        let requestsToProcess = pendingRequests.sorted { $0.priority > $1.priority }
        pendingRequests.removeAll()
        
        print("🚀 [APIRequestBatcher] Processing batch of \(requestsToProcess.count) requests")
        
        Task {
            await self.executeBatch(requestsToProcess)
        }
    }
    
    private func executeBatch(_ requests: [BatchableRequest]) async {
        // Group requests by similar origin/destination to optimize API calls
        let groupedRequests = groupRequestsByLocation(requests)
        
        for group in groupedRequests {
            await processRequestGroup(group)
        }
    }
    
    private func groupRequestsByLocation(_ requests: [BatchableRequest]) -> [[BatchableRequest]] {
        var groups: [[BatchableRequest]] = []
        var remainingRequests = requests
        
        while !remainingRequests.isEmpty {
            let firstRequest = remainingRequests.removeFirst()
            var currentGroup = [firstRequest]
            
            // Find requests with similar locations (within 1km)
            remainingRequests.removeAll { request in
                guard let firstOriginCoord = firstRequest.route.origin.coordinate,
                      let requestOriginCoord = request.route.origin.coordinate,
                      let firstDestCoord = firstRequest.route.destination.coordinate,
                      let requestDestCoord = request.route.destination.coordinate else {
                    return false
                }

                let originDistance = firstOriginCoord.distance(from: requestOriginCoord)
                let destinationDistance = firstDestCoord.distance(from: requestDestCoord)
                
                if originDistance < 1000 && destinationDistance < 1000 {
                    currentGroup.append(request)
                    return true
                }
                return false
            }
            
            groups.append(currentGroup)
        }
        
        return groups
    }
    
    private func processRequestGroup(_ requests: [BatchableRequest]) async {
        // For now, process each request individually
        // In a real implementation, you might batch similar requests into a single API call
        
        await withTaskGroup(of: Void.self) { group in
            for request in requests {
                group.addTask {
                    await self.processIndividualRequest(request)
                }
            }
        }
    }
    
    private func processIndividualRequest(_ request: BatchableRequest) async {
        do {
            // Use existing transport API to get journey options
            let transportAPI = TransportAPIFactory.createAPI()
            let journeyOptions = try await transportAPI.nextJourneyOptions(
                from: request.route.origin,
                to: request.route.destination,
                results: AppConstants.defaultResultsCount
            )
            
            DispatchQueue.main.async {
                request.completion(.success(journeyOptions))
            }
            
            print("✅ [APIRequestBatcher] Completed request for route: \(request.route.name)")
            
        } catch {
            DispatchQueue.main.async {
                request.completion(.failure(error))
            }
            
            print("❌ [APIRequestBatcher] Failed request for route: \(request.route.name) - \(error)")
        }
    }
}

// MARK: - Batch Statistics

struct BatchStatistics {
    let pendingRequestCount: Int
    let highPriorityCount: Int
    let expiredRequestCount: Int
    
    var description: String {
        return """
        Batch Statistics:
        - Pending: \(pendingRequestCount)
        - High Priority: \(highPriorityCount)
        - Expired: \(expiredRequestCount)
        """
    }
}

// MARK: - Coordinate Distance Extension

extension CLLocationCoordinate2D {
    func distance(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2)
    }
}

// MARK: - Convenience Extensions

extension APIRequestBatcher {
    /// Add a high priority request (for user-initiated actions)
    func addHighPriorityRequest(
        for route: Route,
        completion: @escaping (Result<[JourneyOption], Error>) -> Void
    ) {
        addRequest(for: route, priority: .high, completion: completion)
    }
    
    /// Add a critical priority request (for time-sensitive updates)
    func addCriticalRequest(
        for route: Route,
        completion: @escaping (Result<[JourneyOption], Error>) -> Void
    ) {
        addRequest(for: route, priority: .critical, completion: completion)
    }
    
    /// Add a low priority request (for background updates)
    func addBackgroundRequest(
        for route: Route,
        completion: @escaping (Result<[JourneyOption], Error>) -> Void
    ) {
        addRequest(for: route, priority: .low, completion: completion)
    }
}