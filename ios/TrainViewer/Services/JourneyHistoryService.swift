import Foundation
import CoreData

// MARK: - JourneyHistoryEntity Extensions

extension JourneyHistoryEntity {
    func toModel() -> JourneyHistoryEntry {
        return JourneyHistoryEntry(
            id: id,
            routeId: routeId,
            routeName: routeName,
            departureTime: departureTime,
            arrivalTime: arrivalTime,
            actualDepartureTime: actualDepartureTime,
            actualArrivalTime: actualArrivalTime,
            delayMinutes: Int(delayMinutes),
            wasSuccessful: wasSuccessful,
            createdAt: createdAt
        )
    }
}

/// Service for managing journey history tracking and statistics
final class JourneyHistoryService {
    static let shared = JourneyHistoryService()
    
    private let context: NSManagedObjectContext
    private let maxHistoryEntries = 1000
    private let maxHistoryAgeMonths = 12
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
    }
    
    // MARK: - Recording Journeys
    
    /// Records a new journey entry
    func recordJourney(_ entry: JourneyHistoryEntry) async throws {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let entity = JourneyHistoryEntity(context: self.context)
                    entity.id = entry.id
                    entity.routeId = entry.routeId
                    entity.routeName = entry.routeName
                    entity.departureTime = entry.departureTime
                    entity.arrivalTime = entry.arrivalTime
                    entity.actualDepartureTime = entry.actualDepartureTime
                    entity.actualArrivalTime = entry.actualArrivalTime
                    entity.delayMinutes = Int16(entry.delayMinutes)
                    entity.wasSuccessful = entry.wasSuccessful
                    entity.createdAt = entry.createdAt
                    
                    // Link to route if it exists
                    let routeRequest = NSFetchRequest<RouteEntity>(entityName: "RouteEntity")
                    routeRequest.predicate = NSPredicate(format: "id == %@", entry.routeId as CVarArg)
                    if let routeEntity = try? self.context.fetch(routeRequest).first {
                        entity.route = routeEntity
                    }
                    
                    try self.context.save()
                    print("✅ [JourneyHistoryService] Recorded journey for route: \(entry.routeName)")
                    continuation.resume()
                } catch {
                    print("❌ [JourneyHistoryService] Failed to record journey: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Records a journey from a JourneyOption and Route
    func recordJourneyFromOption(_ option: JourneyOption, route: Route, wasSuccessful: Bool = true) async throws {
        let entry = JourneyHistoryEntry(
            routeId: route.id,
            routeName: route.name,
            departureTime: option.departure,
            arrivalTime: option.arrival,
            actualDepartureTime: option.delayMinutes != nil ? option.departure.addingTimeInterval(TimeInterval((option.delayMinutes ?? 0) * 60)) : nil,
            actualArrivalTime: option.delayMinutes != nil ? option.arrival.addingTimeInterval(TimeInterval((option.delayMinutes ?? 0) * 60)) : nil,
            delayMinutes: option.delayMinutes ?? 0,
            wasSuccessful: wasSuccessful
        )
        
        try await recordJourney(entry)
    }
    
    // MARK: - Retrieving History
    
    /// Fetches journey history for a specific time range
    func fetchHistory(for timeRange: TimeRange) async throws -> [JourneyHistoryEntry] {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request = NSFetchRequest<JourneyHistoryEntity>(entityName: "JourneyHistoryEntity")
                    
                    // Apply date filtering if needed
                    if let dateRange = timeRange.dateRange {
                        request.predicate = NSPredicate(
                            format: "departureTime >= %@ AND departureTime <= %@",
                            dateRange.start as NSDate,
                            dateRange.end as NSDate
                        )
                    }
                    
                    request.sortDescriptors = [NSSortDescriptor(key: "departureTime", ascending: false)]
                    
                    let entities = try self.context.fetch(request)
                    let entries = entities.map { $0.toModel() }
                    
                    print("📊 [JourneyHistoryService] Fetched \(entries.count) history entries for \(timeRange.displayName)")
                    continuation.resume(returning: entries)
                } catch {
                    print("❌ [JourneyHistoryService] Failed to fetch history: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Fetches journey history for a specific route
    func fetchHistory(for routeId: UUID, timeRange: TimeRange = .all) async throws -> [JourneyHistoryEntry] {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request = NSFetchRequest<JourneyHistoryEntity>(entityName: "JourneyHistoryEntity")
                    
                    var predicates = [NSPredicate(format: "routeId == %@", routeId as CVarArg)]
                    
                    // Apply date filtering if needed
                    if let dateRange = timeRange.dateRange {
                        predicates.append(NSPredicate(
                            format: "departureTime >= %@ AND departureTime <= %@",
                            dateRange.start as NSDate,
                            dateRange.end as NSDate
                        ))
                    }
                    
                    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
                    request.sortDescriptors = [NSSortDescriptor(key: "departureTime", ascending: false)]
                    
                    let entities = try self.context.fetch(request)
                    let entries = entities.map { $0.toModel() }
                    
                    print("📊 [JourneyHistoryService] Fetched \(entries.count) history entries for route \(routeId)")
                    continuation.resume(returning: entries)
                } catch {
                    print("❌ [JourneyHistoryService] Failed to fetch route history: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Statistics Generation
    
    /// Generates comprehensive journey statistics
    func generateStatistics(for timeRange: TimeRange = .all) async throws -> JourneyStatistics {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let entries = try self.fetchHistorySync(for: timeRange)
                    let statistics = self.computeStatistics(from: entries)
                    
                    print("📊 [JourneyHistoryService] Generated statistics for \(entries.count) journeys")
                    continuation.resume(returning: statistics)
                } catch {
                    print("❌ [JourneyHistoryService] Failed to generate statistics: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Generates statistics for a specific route
    func generateRouteStatistics(for routeId: UUID, timeRange: TimeRange = .all) async throws -> JourneyStatistics {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let entries = try self.fetchRouteHistorySync(for: routeId, timeRange: timeRange)
                    let statistics = self.computeStatistics(from: entries)
                    
                    print("📊 [JourneyHistoryService] Generated route statistics for \(entries.count) journeys")
                    continuation.resume(returning: statistics)
                } catch {
                    print("❌ [JourneyHistoryService] Failed to generate route statistics: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Data Management
    
    /// Cleans up old journey entries based on age and count limits
    func cleanupOldEntries() async throws {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    // Clean up by age
                    let calendar = Calendar.current
                    if let cutoffDate = calendar.date(byAdding: .month, value: -self.maxHistoryAgeMonths, to: Date()) {
                        let ageRequest = NSFetchRequest<JourneyHistoryEntity>(entityName: "JourneyHistoryEntity")
                        ageRequest.predicate = NSPredicate(format: "createdAt < %@", cutoffDate as NSDate)
                        
                        let oldEntries = try self.context.fetch(ageRequest)
                        for entry in oldEntries {
                            self.context.delete(entry)
                        }
                        
                        print("🧹 [JourneyHistoryService] Cleaned up \(oldEntries.count) old entries")
                    }
                    
                    // Clean up by count
                    let countRequest = NSFetchRequest<JourneyHistoryEntity>(entityName: "JourneyHistoryEntity")
                    countRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
                    
                    let allEntries = try self.context.fetch(countRequest)
                    if allEntries.count > self.maxHistoryEntries {
                        let entriesToDelete = Array(allEntries.dropFirst(self.maxHistoryEntries))
                        for entry in entriesToDelete {
                            self.context.delete(entry)
                        }
                        
                        print("🧹 [JourneyHistoryService] Cleaned up \(entriesToDelete.count) excess entries")
                    }
                    
                    try self.context.save()
                    continuation.resume()
                } catch {
                    print("❌ [JourneyHistoryService] Failed to cleanup old entries: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Exports journey history data
    func exportHistory() async throws -> Data {
        let entries = try await fetchHistory(for: .all)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(entries)
    }
    
    /// Exports anonymized history data for privacy
    func exportAnonymizedHistory() async throws -> Data {
        let entries = try await fetchHistory(for: .all)
        let anonymizedEntries = entries.map { AnonymizedHistoryEntry(from: $0) }
        let encoder = JSONEncoder()
        return try encoder.encode(anonymizedEntries)
    }
    
    /// Clears all journey history (for privacy compliance)
    func clearAllHistory() async throws {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request = NSFetchRequest<JourneyHistoryEntity>(entityName: "JourneyHistoryEntity")
                    let entries = try self.context.fetch(request)
                    
                    for entry in entries {
                        self.context.delete(entry)
                    }
                    
                    try self.context.save()
                    print("🧹 [JourneyHistoryService] Cleared all journey history (\(entries.count) entries)")
                    continuation.resume()
                } catch {
                    print("❌ [JourneyHistoryService] Failed to clear history: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func fetchHistorySync(for timeRange: TimeRange) throws -> [JourneyHistoryEntry] {
        let request = NSFetchRequest<JourneyHistoryEntity>(entityName: "JourneyHistoryEntity")
        
        if let dateRange = timeRange.dateRange {
            request.predicate = NSPredicate(
                format: "departureTime >= %@ AND departureTime <= %@",
                dateRange.start as NSDate,
                dateRange.end as NSDate
            )
        }
        
        request.sortDescriptors = [NSSortDescriptor(key: "departureTime", ascending: false)]
        
        let entities = try context.fetch(request)
        return entities.map { $0.toModel() }
    }
    
    private func fetchRouteHistorySync(for routeId: UUID, timeRange: TimeRange) throws -> [JourneyHistoryEntry] {
        let request = NSFetchRequest<JourneyHistoryEntity>(entityName: "JourneyHistoryEntity")
        
        var predicates = [NSPredicate(format: "routeId == %@", routeId as CVarArg)]
        
        if let dateRange = timeRange.dateRange {
            predicates.append(NSPredicate(
                format: "departureTime >= %@ AND departureTime <= %@",
                dateRange.start as NSDate,
                dateRange.end as NSDate
            ))
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(key: "departureTime", ascending: false)]
        
        let entities = try context.fetch(request)
        return entities.map { $0.toModel() }
    }
    
    private func computeStatistics(from entries: [JourneyHistoryEntry]) -> JourneyStatistics {
        guard !entries.isEmpty else {
            return JourneyStatistics()
        }
        
        let totalJourneys = entries.count
        let totalDelay = entries.reduce(0) { $0 + $1.delayMinutes }
        let averageDelayMinutes = Double(totalDelay) / Double(totalJourneys)
        
        // Find most used route
        let routeCounts = Dictionary(grouping: entries, by: { $0.routeId })
            .mapValues { $0.count }
        let mostUsedRoute = routeCounts.max(by: { $0.value < $1.value })
        let mostUsedRouteId = mostUsedRoute?.key
        let mostUsedRouteName = entries.first(where: { $0.routeId == mostUsedRouteId })?.routeName
        
        // Calculate peak travel hours
        let hourCounts = Dictionary(grouping: entries, by: { Calendar.current.component(.hour, from: $0.departureTime) })
            .mapValues { $0.count }
        let peakTravelHours = hourCounts.filter { $0.value >= max(1, totalJourneys / 10) }.map { $0.key }.sorted()
        
        // Calculate weekly pattern
        var weeklyPattern = Array(repeating: 0, count: 7)
        for entry in entries {
            let weekday = Calendar.current.component(.weekday, from: entry.departureTime) - 1 // Convert to 0-based
            weeklyPattern[weekday] += 1
        }
        
        // Calculate monthly trend
        let monthlyTrend = Dictionary(grouping: entries, by: { entry in
            let calendar = Calendar.current
            let year = calendar.component(.year, from: entry.departureTime)
            let month = calendar.component(.month, from: entry.departureTime)
            return String(format: "%04d-%02d", year, month)
        }).mapValues { $0.count }
        
        // Calculate reliability metrics
        let onTimeJourneys = entries.filter { $0.delayMinutes <= 2 }.count // Consider <= 2 minutes as "on time"
        let onTimePercentage = Double(onTimeJourneys) / Double(totalJourneys) * 100.0
        let reliabilityScore = min(1.0, onTimePercentage / 100.0)
        
        return JourneyStatistics(
            totalJourneys: totalJourneys,
            averageDelayMinutes: averageDelayMinutes,
            mostUsedRouteId: mostUsedRouteId,
            mostUsedRouteName: mostUsedRouteName,
            peakTravelHours: peakTravelHours,
            weeklyPattern: weeklyPattern,
            monthlyTrend: monthlyTrend,
            reliabilityScore: reliabilityScore,
            onTimePercentage: onTimePercentage
        )
    }
}