import Foundation

struct DBJourneysResponse: Codable {
    let journeys: [DBJourney]
}

struct DBJourney: Codable {
    let legs: [DBLeg]
    let refreshToken: String?
}

struct DBLeg: Codable {
    let origin: DBStop
    let destination: DBStop
    let departure: Date?
    let plannedDeparture: Date?
    let departureDelay: Int?
    let arrival: Date?
    let plannedArrival: Date?
    let arrivalDelay: Int?
    let platform: String?
    let line: DBLine?

    let departurePlatform: String?
    let arrivalPlatform: String?

    let remarks: [DBRemark]?

    enum CodingKeys: String, CodingKey {
        case origin, destination, departure, plannedDeparture, departureDelay, arrival, plannedArrival, arrivalDelay, platform, line
        case departurePlatform, arrivalPlatform
        case remarks
    }
}

struct DBStop: Codable {
    let name: String?
    let id: String?
    let platform: String?
}

struct DBLine: Codable {
    let name: String?
}

struct DBRemark: Codable {
    let type: String?
    let code: String?
    let text: String?
    let summary: String?
    
    init(type: String?, code: String?, text: String?, summary: String?) {
        self.type = type
        self.code = code
        self.text = text
        self.summary = summary
    }
}

extension DBJourney {
    func toJourneyOption() -> JourneyOption? {
        print("🔍 [JourneyDecoding] Converting DBJourney to JourneyOption")
        print("🔍 [JourneyDecoding] Number of legs: \(legs.count)")
        
        guard let first = legs.first else { 
            print("❌ [JourneyDecoding] No legs found")
            return nil 
        }
        guard let last = legs.last else { 
            print("❌ [JourneyDecoding] No last leg found")
            return nil 
        }
        
        print("🔍 [JourneyDecoding] First leg - Origin: \(first.origin.name ?? "Unknown"), Destination: \(first.destination.name ?? "Unknown")")
        print("🔍 [JourneyDecoding] Last leg - Origin: \(last.origin.name ?? "Unknown"), Destination: \(last.destination.name ?? "Unknown")")
        
        let dep = first.departure ?? first.plannedDeparture
        let arr = last.arrival ?? last.plannedArrival
        
        print("🔍 [JourneyDecoding] Departure: \(dep?.description ?? "nil") (planned: \(first.plannedDeparture?.description ?? "nil"))")
        print("🔍 [JourneyDecoding] Arrival: \(arr?.description ?? "nil") (planned: \(last.plannedArrival?.description ?? "nil"))")
        
        guard let departure = dep, let arrival = arr else { 
            print("❌ [JourneyDecoding] Missing departure or arrival time")
            return nil 
        }
        
        let delay = (first.departureDelay ?? 0) / 60
        let platform = first.departurePlatform ?? first.origin.platform ?? first.platform ?? legs.compactMap { $0.departurePlatform ?? $0.origin.platform ?? $0.platform }.first
        let lineName = first.line?.name
        let total = Int(arrival.timeIntervalSince(departure) / 60.0)
        
        // Use structured remark parsing instead of simple text extraction
        let remarkParser = RemarkParser()
        let allRemarks = legs.flatMap { $0.remarks ?? [] }
        let parsedRemarks = remarkParser.parseRemarks(allRemarks)
        let warnings: [String] = parsedRemarks
            .filter { $0.affectsJourney }
            .map { $0.displayText }
            .uniqued()
        
        print("🔍 [JourneyDecoding] Calculated values:")
        print("🔍 [JourneyDecoding] - Delay: \(delay) minutes")
        print("🔍 [JourneyDecoding] - Platform: \(platform ?? "Unknown")")
        print("🔍 [JourneyDecoding] - Line: \(lineName ?? "Unknown")")
        print("🔍 [JourneyDecoding] - Total journey time: \(total) minutes")
        print("🔍 [JourneyDecoding] - Warnings: \(warnings)")
        
        let option = JourneyOption(departure: departure, arrival: arrival, lineName: lineName, platform: platform, delayMinutes: delay, totalMinutes: total, warnings: warnings.isEmpty ? nil : warnings, refreshToken: refreshToken)
        
        print("✅ [JourneyDecoding] Successfully created JourneyOption: \(departure) → \(arrival)")
        return option
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}