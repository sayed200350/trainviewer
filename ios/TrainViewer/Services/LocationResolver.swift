import Foundation
import CoreLocation

/// Enhanced location resolution service with URL encoding and coordinate fallback
final class LocationResolver {
    private let client: APIClient
    private let baseURL: URL
    
    init(client: APIClient = .shared, baseURL: URL) {
        self.client = client
        self.baseURL = baseURL
    }
    
    /// Safely resolve a user text query to transit locations with fallback strategies
    func resolveLocation(query: String, limit: Int = 8) async throws -> [Place] {
        print("🔍 [LocationResolver] Resolving location for query: '\(query)'")
        
        // Step 1: Try direct location search with URL encoding
        do {
            let places = try await searchLocationsSafely(query: query, limit: limit)
            if !places.isEmpty {
                print("✅ [LocationResolver] Found \(places.count) places via direct search")
                return places
            }
        } catch {
            print("⚠️ [LocationResolver] Direct search failed: \(error)")
        }
        
        // Step 2: Try to parse as coordinates if the query looks like coordinates
        if let coordinate = parseCoordinates(from: query) {
            print("🎯 [LocationResolver] Query appears to be coordinates: \(coordinate)")
            do {
                let places = try await searchNearCoordinates(coordinate: coordinate, limit: limit)
                if !places.isEmpty {
                    print("✅ [LocationResolver] Found \(places.count) places near coordinates")
                    return places
                }
            } catch {
                print("⚠️ [LocationResolver] Coordinate search failed: \(error)")
            }
        }
        
        // Step 3: Try fuzzy search variations
        let variations = generateQueryVariations(query)
        for variation in variations {
            do {
                let places = try await searchLocationsSafely(query: variation, limit: limit)
                if !places.isEmpty {
                    print("✅ [LocationResolver] Found \(places.count) places via variation: '\(variation)'")
                    return places
                }
            } catch {
                print("⚠️ [LocationResolver] Variation search failed for '\(variation)': \(error)")
                continue
            }
        }
        
        print("❌ [LocationResolver] No locations found for query: '\(query)'")
        return []
    }
    
    /// Search for locations with proper URL encoding and filtering
    private func searchLocationsSafely(query: String, limit: Int) async throws -> [Place] {
        guard var components = URLComponents(url: baseURL.appendingPathComponent("locations"), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        
        // Properly URL-encode the query
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        
        components.queryItems = [
            URLQueryItem(name: "query", value: encodedQuery),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "poi", value: "false"),        // Focus on transit stops
            URLQueryItem(name: "addresses", value: "false")   // Exclude addresses for cleaner results
        ]
        
        guard let url = components.url else { 
            throw APIError.invalidURL 
        }
        
        print("🌐 [LocationResolver] Searching: \(url)")
        
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
    
    /// Search for locations near coordinates
    private func searchNearCoordinates(coordinate: CLLocationCoordinate2D, limit: Int) async throws -> [Place] {
        guard var components = URLComponents(url: baseURL.appendingPathComponent("locations/nearby"), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "distance", value: "1000"), // 1km radius
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else { 
            throw APIError.invalidURL 
        }
        
        print("🌐 [LocationResolver] Searching near coordinates: \(url)")
        
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
    
    /// Parse coordinate string patterns like "52.5200,13.4050" or "52.5200, 13.4050"
    private func parseCoordinates(from query: String) -> CLLocationCoordinate2D? {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try common coordinate patterns
        let patterns = [
            #"^(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)$"#,  // "lat,lon" or "lat, lon"
            #"^(-?\d+\.?\d*)\s+(-?\d+\.?\d*)$"#,       // "lat lon"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: cleanQuery, range: NSRange(cleanQuery.startIndex..., in: cleanQuery)) {
                
                if match.numberOfRanges == 3, // Full match + 2 groups
                   let latRange = Range(match.range(at: 1), in: cleanQuery),
                   let lonRange = Range(match.range(at: 2), in: cleanQuery),
                   let lat = Double(String(cleanQuery[latRange])),
                   let lon = Double(String(cleanQuery[lonRange])) {
                    
                    // Validate coordinate ranges
                    if abs(lat) <= 90 && abs(lon) <= 180 {
                        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    }
                }
            }
        }
        
        return nil
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
        
        return variations.uniqued()
    }
}

// MARK: - Enhanced Place Resolution

extension Place {
    /// Create a Place from coordinates with a generated name
    static func fromCoordinates(_ coordinate: CLLocationCoordinate2D, name: String? = nil) -> Place {
        let generatedName = name ?? "Location (\(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude)))"
        
        return Place(
            rawId: nil,
            name: generatedName,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
    
    /// Check if this place has valid coordinates
    var hasValidCoordinates: Bool {
        return latitude != nil && longitude != nil
    }
    
    /// Check if this place has a valid transit API ID
    var hasValidId: Bool {
        return rawId != nil && !rawId!.isEmpty
    }
}

// MARK: - Array Helper

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
