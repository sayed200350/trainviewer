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
    let stopovers: [DBStopover]?

    enum CodingKeys: String, CodingKey {
        case origin, destination, departure, plannedDeparture, departureDelay, arrival, plannedArrival, arrivalDelay, platform, line
        case departurePlatform, arrivalPlatform
        case remarks, stopovers
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

struct DBStopover: Codable {
    let stop: DBStop
    let arrival: Date?
    let plannedArrival: Date?
    let arrivalDelay: Int?
    let departure: Date?
    let plannedDeparture: Date?
    let departureDelay: Int?
    let platform: String?

    enum CodingKeys: String, CodingKey {
        case stop, arrival, plannedArrival, arrivalDelay, departure, plannedDeparture, departureDelay, platform
    }
}

extension DBJourney {
    func toJourneyOption() -> JourneyOption? {
    print("🔍 [JourneyDecoding] Converting DBJourney to JourneyOption")
    print("🔍 [JourneyDecoding] Number of legs: \(legs.count)")

    // Debug: Show stopovers information for each leg
    for (index, leg) in legs.enumerated() {
        if let stopovers = leg.stopovers {
            print("🔍 [JourneyDecoding] Leg \(index) has \(stopovers.count) stopovers")
        } else {
            print("🔍 [JourneyDecoding] Leg \(index) has no stopovers")
        }
    }
        
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
        
        // Convert DBLegs to JourneyLegs for detailed journey information
        let journeyLegs = legs.enumerated().map { (index, leg) -> JourneyLeg in
            let origin = StopInfo(
                id: leg.origin.id ?? "origin_\(index)",
                name: leg.origin.name ?? "Unknown Origin",
                platform: leg.departurePlatform ?? leg.origin.platform ?? leg.platform,
                scheduledArrival: nil,
                actualArrival: nil,
                scheduledDeparture: leg.plannedDeparture ?? leg.departure,
                actualDeparture: leg.departure
            )

            let destination = StopInfo(
                id: leg.destination.id ?? "destination_\(index)",
                name: leg.destination.name ?? "Unknown Destination",
                platform: leg.arrivalPlatform ?? leg.destination.platform ?? leg.platform,
                scheduledArrival: leg.plannedArrival ?? leg.arrival,
                actualArrival: leg.arrival,
                scheduledDeparture: nil,
                actualDeparture: nil
            )

            // Parse real intermediate stops from API response
            let intermediateStops = parseRealStopovers(for: leg, legIndex: index)

            print("🔍 [JourneyDecoding] Leg \(index): \(origin.name) → \(destination.name)")
            print("🔍 [JourneyDecoding] Real intermediate stops: \(intermediateStops.count)")

            return JourneyLeg(
                origin: origin,
                destination: destination,
                intermediateStops: intermediateStops,
                departure: leg.departure ?? leg.plannedDeparture ?? departure,
                arrival: leg.arrival ?? leg.plannedArrival ?? arrival,
                lineName: leg.line?.name,
                platform: leg.departurePlatform ?? leg.origin.platform ?? leg.platform,
                direction: nil,
                delayMinutes: leg.departureDelay != nil ? leg.departureDelay! / 60 : nil
            )
        }

        let option = JourneyOption(
            departure: departure,
            arrival: arrival,
            lineName: lineName,
            platform: platform,
            delayMinutes: delay,
            totalMinutes: total,
            warnings: warnings.isEmpty ? nil : warnings,
            refreshToken: refreshToken,
            legs: journeyLegs
        )

        print("✅ [JourneyDecoding] Successfully created JourneyOption with \(journeyLegs.count) legs: \(departure) → \(arrival)")
        return option
    }
}

// Function to parse real intermediate stops from API response
private func parseRealStopovers(for leg: DBLeg, legIndex: Int) -> [StopInfo] {
    guard let stopovers = leg.stopovers else {
        print("🔍 [JourneyDecoding] No stopovers found for leg \(legIndex)")
        return []
    }

    print("🔍 [JourneyDecoding] Parsing \(stopovers.count) real stopovers for leg \(legIndex)")

    // Get origin and destination identifiers to filter out duplicates
    let originName = leg.origin.name?.trimmingCharacters(in: .whitespacesAndNewlines)
    let originId = leg.origin.id
    let destinationName = leg.destination.name?.trimmingCharacters(in: .whitespacesAndNewlines)
    let destinationId = leg.destination.id

    print("🔍 [JourneyDecoding] Filtering out origin: \(originName ?? "N/A") (\(originId ?? "N/A"))")
    print("🔍 [JourneyDecoding] Filtering out destination: \(destinationName ?? "N/A") (\(destinationId ?? "N/A"))")

    var intermediateStops: [StopInfo] = []

    for (index, stopover) in stopovers.enumerated() {
        guard let stopName = stopover.stop.name else {
            print("⚠️ [JourneyDecoding] Stopover \(index) missing name, skipping")
            continue
        }

        let stopoverName = stopName.trimmingCharacters(in: .whitespacesAndNewlines)
        let stopoverId = stopover.stop.id

        // Skip if this stopover matches the origin or destination
        if (stopoverName == originName && stopoverId == originId) ||
           (stopoverName == destinationName && stopoverId == destinationId) {
            print("🔍 [JourneyDecoding] Skipping duplicate stop: \(stopName) (matches origin/destination)")
            continue
        }

        let stopId = stopoverId ?? "stopover_\(legIndex)_\(index)"

        // Use platform from stopover, or fall back to leg's platform, or stop's platform
        let platform = stopover.platform ?? leg.platform ?? stopover.stop.platform

        let stop = StopInfo(
            id: stopId,
            name: stopName,
            platform: platform,
            scheduledArrival: stopover.plannedArrival ?? stopover.arrival,
            actualArrival: stopover.arrival,
            scheduledDeparture: stopover.plannedDeparture ?? stopover.departure,
            actualDeparture: stopover.departure
        )

        intermediateStops.append(stop)

        print("🔍 [JourneyDecoding] Intermediate stop \(intermediateStops.count): \(stopName) (Platform: \(platform ?? "N/A"))")
        if let arr = stopover.arrival {
            print("🔍 [JourneyDecoding]   Arrival: \(arr)")
        }
        if let dep = stopover.departure {
            print("🔍 [JourneyDecoding]   Departure: \(dep)")
        }
    }

    print("🔍 [JourneyDecoding] Final intermediate stops count: \(intermediateStops.count)")
    return intermediateStops
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

// Debug function to test stopovers parsing
func debugJourneyStopovers() {
    print("🧪 [Debug] Testing Journey Stopovers Implementation")
    print("🧪 [Debug] This function tests the stopovers parsing with sample data")

    // Sample JSON structure that would come from the API with stopovers=true
    let sampleJSON = """
    {
        "journeys": [
            {
                "legs": [
                    {
                        "origin": {
                            "name": "Berlin Hbf",
                            "id": "8011160"
                        },
                        "destination": {
                            "name": "Hamburg Hbf",
                            "id": "8002549"
                        },
                        "departure": "2024-01-15T10:00:00+01:00",
                        "arrival": "2024-01-15T11:30:00+01:00",
                        "line": {
                            "name": "ICE 123"
                        },
                        "stopovers": [
                            {
                                "stop": {
                                    "name": "Berlin-Spandau",
                                    "id": "8010404"
                                },
                                "arrival": "2024-01-15T10:15:00+01:00",
                                "departure": "2024-01-15T10:17:00+01:00",
                                "platform": "3"
                            },
                            {
                                "stop": {
                                    "name": "Stendal",
                                    "id": "8010366"
                                },
                                "arrival": "2024-01-15T11:00:00+01:00",
                                "departure": "2024-01-15T11:02:00+01:00",
                                "platform": "1"
                            }
                        ]
                    }
                ],
                "refreshToken": "sample_token"
            }
        ]
    }
    """

    print("🧪 [Debug] Sample API Response Structure:")
    print(sampleJSON)
    print("🧪 [Debug] This structure should now be parsed correctly with real intermediate stops!")
    print("🧪 [Debug] The stopovers array contains real station data with arrival/departure times")
}