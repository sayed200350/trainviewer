import Foundation

final class DBTransportAPI: TransportAPI {
    private let client: APIClient
    private let provider: ProviderPreference

    init(client: APIClient = .shared, provider: ProviderPreference = .db) {
        self.client = client
        self.provider = provider
    }

    private var baseURL: URL {
        switch provider {
        case .db: return AppConstants.dbBaseURL
        case .vbb: return AppConstants.vbbBaseURL
        case .auto: return AppConstants.dbBaseURL // Default to DB for auto mode
        }
    }

    func searchLocations(query: String, limit: Int = 8) async throws -> [Place] {
        return try await resolveLocationSafely(query: query, limit: limit)
    }
    
    /// Enhanced location resolution with URL encoding and fallback strategies
    private func resolveLocationSafely(query: String, limit: Int) async throws -> [Place] {
        print("🔍 [DBTransportAPI] Resolving location for query: '\(query)'")
        
        // Step 1: Try direct location search with URL encoding
        do {
            let places = try await searchLocationsSafely(query: query, limit: limit)
            if !places.isEmpty {
                print("✅ [DBTransportAPI] Found \(places.count) places via direct search")
                return places
            }
        } catch {
            print("⚠️ [DBTransportAPI] Direct search failed: \(error)")
        }
        
        // Step 2: Try query variations
        let variations = generateQueryVariations(query)
        for variation in variations {
            do {
                let places = try await searchLocationsSafely(query: variation, limit: limit)
                if !places.isEmpty {
                    print("✅ [DBTransportAPI] Found \(places.count) places via variation: '\(variation)'")
                    return places
                }
            } catch {
                print("⚠️ [DBTransportAPI] Variation search failed for '\(variation)': \(error)")
                continue
            }
        }
        
        print("❌ [DBTransportAPI] No locations found for query: '\(query)'")
        return []
    }
    
    /// Search for locations with proper URL encoding
    private func searchLocationsSafely(query: String, limit: Int) async throws -> [Place] {
        guard var components = URLComponents(url: baseURL.appendingPathComponent("locations"), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        
        // Properly URL-encode the query
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? query
        
        components.queryItems = [
            URLQueryItem(name: "query", value: encodedQuery),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "poi", value: "false"),        // Focus on transit stops
            URLQueryItem(name: "addresses", value: "false")   // Exclude addresses for cleaner results
        ]
        
        guard let url = components.url else { 
            throw APIError.invalidURL 
        }
        
        print("🌐 [DBTransportAPI] Searching: \(url)")
        
        let results: [DBPlace] = try await client.get(url, as: [DBPlace].self)
        
        return results.compactMap { place in
            guard let name = place.name else { return nil }
            return Place(
                rawId: place.id, 
                name: name, 
                latitude: place.location?.latitude, 
                longitude: place.location?.longitude
            )
        }
    }
    
    /// Generate query variations for fuzzy matching
    private func generateQueryVariations(_ query: String) -> [String] {
        var variations: [String] = []
        
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try without common prefixes/suffixes
        let prefixesToRemove = ["bahnhof", "station", "hbf", "hauptbahnhof"]
        let suffixesToRemove = ["bahnhof", "station", "hbf", "hauptbahnhof"]
        
        for prefix in prefixesToRemove {
            if trimmed.lowercased().hasPrefix(prefix.lowercased()) {
                let withoutPrefix = String(trimmed.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                if !withoutPrefix.isEmpty {
                    variations.append(withoutPrefix)
                }
            }
        }
        
        for suffix in suffixesToRemove {
            if trimmed.lowercased().hasSuffix(suffix.lowercased()) {
                let withoutSuffix = String(trimmed.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
                if !withoutSuffix.isEmpty {
                    variations.append(withoutSuffix)
                }
            }
        }
        
        // Try common abbreviations
        let abbreviations: [String: String] = [
            "hbf": "hauptbahnhof",
            "hauptbahnhof": "hbf",
            "bf": "bahnhof",
            "bahnhof": "bf"
        ]
        
        for (abbrev, full) in abbreviations {
            let queryLower = trimmed.lowercased()
            if queryLower.contains(abbrev) {
                let expanded = queryLower.replacingOccurrences(of: abbrev, with: full)
                variations.append(expanded)
            }
        }
        
        return Array(Set(variations)) // Remove duplicates
    }

    func nextJourneyOptions(from: Place, to: Place, results: Int = AppConstants.defaultResultsCount) async throws -> [JourneyOption] {
        print("🚂 [DBTransportAPI] Fetching journeys from \(from.name) to \(to.name)")
        print("🚂 [DBTransportAPI] Provider: \(provider)")
        print("🚂 [DBTransportAPI] Base URL: \(baseURL)")
        print("🚂 [DBTransportAPI] Stopovers enabled: true")
        
        var components = URLComponents(url: baseURL.appendingPathComponent("journeys"), resolvingAgainstBaseURL: false)
        var items: [URLQueryItem] = [
            URLQueryItem(name: "results", value: String(results)),
            URLQueryItem(name: "stopovers", value: "true"),
            URLQueryItem(name: "remarks", value: "true"),
            URLQueryItem(name: "language", value: "en")
        ]
        
        // from - with safe encoding and fallback resolution
        if let id = from.rawId, !id.isEmpty {
            // URL-encode the ID to handle special characters
            if let encodedId = id.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                items.append(URLQueryItem(name: "from", value: encodedId))
                print("🚂 [DBTransportAPI] Using FROM ID: \(encodedId)")
            } else {
                print("⚠️ [DBTransportAPI] Failed to encode FROM ID: \(id)")
                throw APIError.invalidURL
            }
        } else if let lat = from.latitude, let lon = from.longitude {
            items.append(URLQueryItem(name: "from.latitude", value: String(lat)))
            items.append(URLQueryItem(name: "from.longitude", value: String(lon)))
            // Add name as label for better context
            if let encodedName = from.name.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                items.append(URLQueryItem(name: "from.name", value: encodedName))
            }
            print("🚂 [DBTransportAPI] Using FROM coordinates: \(lat), \(lon) with name: \(from.name)")
        } else {
            print("❌ [DBTransportAPI] FROM place has no ID or coordinates! Attempting fallback resolution...")
            // Try to resolve the location again as a fallback
            let resolvedPlaces = try await resolveLocationSafely(query: from.name, limit: 8)
            if let resolvedPlace = resolvedPlaces.first {
                if let id = resolvedPlace.rawId, !id.isEmpty {
                    if let encodedId = id.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                        items.append(URLQueryItem(name: "from", value: encodedId))
                        print("🚂 [DBTransportAPI] Using resolved FROM ID: \(encodedId)")
                    }
                } else if let lat = resolvedPlace.latitude, let lon = resolvedPlace.longitude {
                    items.append(URLQueryItem(name: "from.latitude", value: String(lat)))
                    items.append(URLQueryItem(name: "from.longitude", value: String(lon)))
                    print("🚂 [DBTransportAPI] Using resolved FROM coordinates: \(lat), \(lon)")
                } else {
                    throw APIError.invalidURL
                }
            } else {
                throw APIError.invalidURL
            }
        }
        
        // to - with safe encoding and fallback resolution
        if let id = to.rawId, !id.isEmpty {
            // URL-encode the ID to handle special characters
            if let encodedId = id.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                items.append(URLQueryItem(name: "to", value: encodedId))
                print("🚂 [DBTransportAPI] Using TO ID: \(encodedId)")
            } else {
                print("⚠️ [DBTransportAPI] Failed to encode TO ID: \(id)")
                throw APIError.invalidURL
            }
        } else if let lat = to.latitude, let lon = to.longitude {
            items.append(URLQueryItem(name: "to.latitude", value: String(lat)))
            items.append(URLQueryItem(name: "to.longitude", value: String(lon)))
            // Add name as label for better context
            if let encodedName = to.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                items.append(URLQueryItem(name: "to.name", value: encodedName))
            }
            print("🚂 [DBTransportAPI] Using TO coordinates: \(lat), \(lon) with name: \(to.name)")
        } else {
            print("❌ [DBTransportAPI] TO place has no ID or coordinates! Attempting fallback resolution...")
            // Try to resolve the location again as a fallback
            let resolvedPlaces = try await resolveLocationSafely(query: to.name, limit: 8)
            if let resolvedPlace = resolvedPlaces.first {
                if let id = resolvedPlace.rawId, !id.isEmpty {
                    if let encodedId = id.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                        items.append(URLQueryItem(name: "to", value: encodedId))
                        print("🚂 [DBTransportAPI] Using resolved TO ID: \(encodedId)")
                    }
                } else if let lat = resolvedPlace.latitude, let lon = resolvedPlace.longitude {
                    items.append(URLQueryItem(name: "to.latitude", value: String(lat)))
                    items.append(URLQueryItem(name: "to.longitude", value: String(lon)))
                    print("🚂 [DBTransportAPI] Using resolved TO coordinates: \(lat), \(lon)")
                } else {
                    throw APIError.invalidURL
                }
            } else {
                throw APIError.invalidURL
            }
        }
        
        components?.queryItems = items
        guard let url = components?.url else { throw APIError.invalidURL }
        
        print("🚂 [DBTransportAPI] Full URL: \(url)")
        print("🚂 [DBTransportAPI] Query items: \(items)")
        
        let response = try await client.get(url, as: DBJourneysResponse.self)
        
        print("🚂 [DBTransportAPI] Raw response received:")
        print("🚂 [DBTransportAPI] - Number of journeys: \(response.journeys.count)")
        
        let journeyOptions = response.journeys.compactMap { journey -> JourneyOption? in
            let option = journey.toJourneyOption()
            if let option = option {
                print("🚂 [DBTransportAPI] Journey option: \(option.departure) → \(option.arrival) (Line: \(option.lineName ?? "Unknown"), Platform: \(option.platform ?? "Unknown"))")
            } else {
                print("⚠️ [DBTransportAPI] Failed to convert journey to option")
            }
            return option
        }
        
        print("🚂 [DBTransportAPI] Raw journey options count: \(journeyOptions.count)")
        
        // Filter out invalid options and return all valid upcoming options
        let validOptions = selectValidJourneyOptions(from: journeyOptions)

        print("🎯 [DBTransportAPI] Returning \(validOptions.count) valid journey options")
        return validOptions
    }
    
    /// Filters out invalid journey options and returns all valid ones
    private func selectValidJourneyOptions(from options: [JourneyOption]) -> [JourneyOption] {
        print("🎯 [DBTransportAPI] Filtering \(options.count) options for validity")

        let validOptions = options.filter { option in
            // 1. Filter out options with excessive delays (>30 minutes)
            if let delay = option.delayMinutes, delay > 30 {
                print("❌ [DBTransportAPI] Filtered out option with excessive delay: \(delay) minutes")
                return false
            }

            // 2. Filter out options with unreasonable journey times (>4 hours for most journeys)
            if option.totalMinutes > 240 {
                print("❌ [DBTransportAPI] Filtered out option with unreasonable journey time: \(option.totalMinutes) minutes")
                return false
            }

            // 3. Filter out options with severe warnings (using structured remark analysis)
            if let warnings = option.warnings, !warnings.isEmpty {
                // For now, allow options with warnings but you could filter based on severity
                print("⚠️ [DBTransportAPI] Option has \(warnings.count) warnings")
            }

            // 4. Filter out past departures (more than 5 minutes ago)
            let now = Date()
            let timeSinceDeparture = now.timeIntervalSince(option.departure)
            if timeSinceDeparture > 300 { // 5 minutes ago
                print("❌ [DBTransportAPI] Filtered out past departure: \(option.departure)")
                return false
            }

            return true
        }

        // Sort by departure time (earliest first)
        let sortedOptions = validOptions.sorted { $0.departure < $1.departure }

        print("✅ [DBTransportAPI] Found \(sortedOptions.count) valid journey options")
        return sortedOptions
    }

    /// Selects the best journey option based on multiple criteria
    private func selectBestJourneyOption(from options: [JourneyOption]) -> JourneyOption? {
        guard !options.isEmpty else { return nil }
        
        print("🎯 [DBTransportAPI] Selecting best option from \(options.count) options")
        
        // Filter out options that don't make sense
        let validOptions = options.filter { option in
            // 1. Filter out options with excessive delays (>30 minutes)
            if let delay = option.delayMinutes, delay > 30 {
                print("❌ [DBTransportAPI] Filtered out option with excessive delay: \(delay) minutes")
                return false
            }
            
            // 2. Filter out options with unreasonable journey times (>4 hours for most journeys)
            if option.totalMinutes > 240 {
                print("❌ [DBTransportAPI] Filtered out option with unreasonable journey time: \(option.totalMinutes) minutes")
                return false
            }
            
            // 3. Filter out options with severe warnings (using structured remark analysis)
            if let warnings = option.warnings, !warnings.isEmpty {
                // Re-parse the warnings to check severity
                let mockRemarks = warnings.map { warning in
                    DBRemark(type: nil, code: nil, text: warning, summary: nil)
                }
                let remarkParser = RemarkParser()
                let parsedRemarks = remarkParser.parseRemarks(mockRemarks)
                let remarkSummary = remarkParser.getRemarkSummary(parsedRemarks)
                
                if remarkSummary.shouldFilterJourney() {
                    print("❌ [DBTransportAPI] Filtered out option with severe disruptions: \(remarkSummary.getSummaryText() ?? "Unknown issue")")
                    return false
                }
            }
            
            // 4. Filter out options departing in the past
            if option.departure < Date() {
                print("❌ [DBTransportAPI] Filtered out option departing in the past: \(option.departure)")
                return false
            }
            
            return true
        }
        
        print("🎯 [DBTransportAPI] Valid options after filtering: \(validOptions.count)")
        
        guard !validOptions.isEmpty else { return nil }
        
        // Score each option based on multiple criteria
        let scoredOptions = validOptions.map { option -> (JourneyOption, Double) in
            var score: Double = 0.0
            
            // 1. Departure time preference (earlier is better, but not too early)
            let now = Date()
            let minutesUntilDeparture = option.departure.timeIntervalSince(now) / 60.0
            
            if minutesUntilDeparture < 0 {
                score -= 1000 // Heavy penalty for past departures
            } else if minutesUntilDeparture < 5 {
                score += 50 // Good for very soon departures
            } else if minutesUntilDeparture < 30 {
                score += 100 // Best for departures within 30 minutes
            } else if minutesUntilDeparture < 60 {
                score += 80 // Good for departures within an hour
            } else if minutesUntilDeparture < 120 {
                score += 60 // Acceptable for departures within 2 hours
            } else {
                score += 40 // Lower score for departures more than 2 hours away
            }
            
            // 2. Journey duration (shorter is better)
            let durationScore = Double(max(0, 120 - option.totalMinutes)) // Max 120 minutes gets 0 points, shorter gets more
            score += durationScore
            
            // 3. Delay penalty (no delay is best)
            if let delay = option.delayMinutes {
                score -= Double(delay * 2) // Each minute of delay reduces score by 2
            }
            
            // 4. Platform preference (known platform is better)
            if let platform = option.platform, !platform.isEmpty {
                score += 10
            }
            
            // 5. Line preference (known line is better)
            if let lineName = option.lineName, !lineName.isEmpty {
                score += 10
            }
            
            // 6. Warning penalty (each warning reduces score)
            if let warnings = option.warnings {
                score -= Double(warnings.count * 5)
            }
            
            print("🎯 [DBTransportAPI] Option scored: \(option.departure) → \(option.arrival) (Score: \(score), Duration: \(option.totalMinutes)min, Delay: \(option.delayMinutes ?? 0)min)")
            
            return (option, score)
        }
        
        // Sort by score (highest first) and return the best
        let sortedOptions = scoredOptions.sorted { $0.1 > $1.1 }
        
        if let bestOption = sortedOptions.first {
            print("🎯 [DBTransportAPI] Best option selected with score \(bestOption.1): \(bestOption.0.departure) → \(bestOption.0.arrival)")
            return bestOption.0
        }
        
        return nil
    }
    
    // MARK: - Refresh Journey
    
    func refreshJourney(refreshToken: String) async throws -> JourneyOption? {
        print("🔄 [DBTransportAPI] Refreshing journey with token: \(refreshToken)")
        
        // URL-encode the refresh token to handle special characters
        guard let encodedToken = refreshToken.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("❌ [DBTransportAPI] Failed to encode refresh token")
            throw APIError.invalidURL
        }
        
        let url = baseURL.appendingPathComponent("journeys/\(encodedToken)")
        
        print("🌐 [DBTransportAPI] Refresh URL: \(url)")
        
        do {
            let response = try await client.get(url, as: DBJourneysResponse.self)
            
            print("🔄 [DBTransportAPI] Refresh response received:")
            print("🔄 [DBTransportAPI] - Number of updated journeys: \(response.journeys.count)")
            
            // Take the first (and usually only) journey from the refresh response
            guard let firstJourney = response.journeys.first else {
                print("⚠️ [DBTransportAPI] No journey data in refresh response")
                return nil
            }
            
            let refreshedOption = firstJourney.toJourneyOption()
            
            if let option = refreshedOption {
                print("✅ [DBTransportAPI] Successfully refreshed journey: \(option.departure) → \(option.arrival)")
                print("🔄 [DBTransportAPI] Updated delay: \(option.delayMinutes ?? 0) minutes")
                print("🔄 [DBTransportAPI] Updated warnings: \(option.warnings?.count ?? 0)")
            } else {
                print("❌ [DBTransportAPI] Failed to convert refreshed journey to option")
            }
            
            return refreshedOption
            
        } catch {
            print("❌ [DBTransportAPI] Journey refresh failed: \(error)")
            
            // For refresh failures, we don't want to crash the app
            // The caller can decide whether to fall back to full re-planning
            if case APIError.requestFailed(let status, _) = error {
                if status == 404 {
                    print("⚠️ [DBTransportAPI] Refresh token expired or invalid")
                    return nil
                }
            }
            
            throw error
        }
    }
}