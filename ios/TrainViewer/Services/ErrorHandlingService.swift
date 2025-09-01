import Foundation
import CoreLocation

/// Enhanced error handling service for better user experience
final class ErrorHandlingService {
    
    /// User-friendly error categories
    enum ErrorCategory {
        case networkConnection
        case locationResolution
        case noJourneysFound
        case serviceDisruption
        case rateLimited
        case invalidInput
        case temporaryUnavailable
        case unknown
        
        var displayTitle: String {
            switch self {
            case .networkConnection: return "Connection Issue"
            case .locationResolution: return "Location Not Found"
            case .noJourneysFound: return "No Routes Available"
            case .serviceDisruption: return "Service Disruption"
            case .rateLimited: return "Too Many Requests"
            case .invalidInput: return "Invalid Input"
            case .temporaryUnavailable: return "Service Temporarily Unavailable"
            case .unknown: return "Unexpected Error"
            }
        }
        
        var displayMessage: String {
            switch self {
            case .networkConnection: 
                return "Please check your internet connection and try again."
            case .locationResolution: 
                return "We couldn't find that location. Try searching for a nearby station or address."
            case .noJourneysFound: 
                return "No routes found for your search. Try adjusting your departure time or destination."
            case .serviceDisruption: 
                return "Transit services are currently disrupted. We'll show alternative options when available."
            case .rateLimited: 
                return "Please wait a moment before searching again."
            case .invalidInput: 
                return "Please check your search terms and try again."
            case .temporaryUnavailable: 
                return "The service is temporarily unavailable. Please try again in a few minutes."
            case .unknown: 
                return "Something went wrong. Please try again."
            }
        }
        
        var suggestedActions: [ErrorAction] {
            switch self {
            case .networkConnection:
                return [.retry, .checkConnection]
            case .locationResolution:
                return [.useCurrentLocation, .searchNearby, .enterCoordinates]
            case .noJourneysFound:
                return [.adjustTime, .searchNearby, .reverseRoute]
            case .serviceDisruption:
                return [.showAlternatives, .checkStatus, .retry]
            case .rateLimited:
                return [.waitAndRetry]
            case .invalidInput:
                return [.editSearch, .useCurrentLocation]
            case .temporaryUnavailable:
                return [.retry, .checkStatus]
            case .unknown:
                return [.retry, .reportIssue]
            }
        }
    }
    
    /// Suggested actions for error recovery
    enum ErrorAction: CaseIterable {
        case retry
        case checkConnection
        case useCurrentLocation
        case searchNearby
        case enterCoordinates
        case adjustTime
        case reverseRoute
        case showAlternatives
        case checkStatus
        case waitAndRetry
        case editSearch
        case reportIssue
        
        var displayText: String {
            switch self {
            case .retry: return "Try Again"
            case .checkConnection: return "Check Connection"
            case .useCurrentLocation: return "Use Current Location"
            case .searchNearby: return "Search Nearby"
            case .enterCoordinates: return "Enter Coordinates"
            case .adjustTime: return "Change Time"
            case .reverseRoute: return "Reverse Route"
            case .showAlternatives: return "Show Alternatives"
            case .checkStatus: return "Check Service Status"
            case .waitAndRetry: return "Wait & Retry"
            case .editSearch: return "Edit Search"
            case .reportIssue: return "Report Issue"
            }
        }
        
        var systemImageName: String {
            switch self {
            case .retry: return "arrow.clockwise"
            case .checkConnection: return "wifi.exclamationmark"
            case .useCurrentLocation: return "location"
            case .searchNearby: return "magnifyingglass"
            case .enterCoordinates: return "map"
            case .adjustTime: return "clock"
            case .reverseRoute: return "arrow.up.arrow.down"
            case .showAlternatives: return "arrow.triangle.branch"
            case .checkStatus: return "info.circle"
            case .waitAndRetry: return "clock.arrow.circlepath"
            case .editSearch: return "pencil"
            case .reportIssue: return "exclamationmark.bubble"
            }
        }
    }
    
    /// Comprehensive error information for UI
    struct ErrorInfo {
        let category: ErrorCategory
        let title: String
        let message: String
        let suggestedActions: [ErrorAction]
        let canRetryAutomatically: Bool
        let retryDelay: TimeInterval?
        let originalError: Error?
        
        init(category: ErrorCategory, canRetryAutomatically: Bool = false, retryDelay: TimeInterval? = nil, originalError: Error? = nil) {
            self.category = category
            self.title = category.displayTitle
            self.message = category.displayMessage
            self.suggestedActions = category.suggestedActions
            self.canRetryAutomatically = canRetryAutomatically
            self.retryDelay = retryDelay
            self.originalError = originalError
        }
    }
    
    /// Fallback options for location resolution
    struct LocationFallbackOptions {
        let useCurrentLocation: Bool
        let searchNearbyStations: Bool
        let allowCoordinateEntry: Bool
        let suggestedAlternatives: [String]
        
        static let `default` = LocationFallbackOptions(
            useCurrentLocation: true,
            searchNearbyStations: true,
            allowCoordinateEntry: true,
            suggestedAlternatives: ["Central Station", "Main Station", "Airport"]
        )
    }
    
    // MARK: - Error Analysis and Categorization
    
    func analyzeError(_ error: Error) -> ErrorInfo {
        print("🔍 [ErrorHandlingService] Analyzing error: \(error)")
        
        // Handle API-specific errors
        if let apiError = error as? APIError {
            return analyzeAPIError(apiError)
        }
        
        // Handle URL/network errors
        if let urlError = error as? URLError {
            return analyzeURLError(urlError)
        }
        
        // Handle location errors
        if let locationError = error as? CLError {
            return analyzeLocationError(locationError)
        }
        
        // Default fallback
        return ErrorInfo(category: .unknown, originalError: error)
    }
    
    private func analyzeAPIError(_ error: APIError) -> ErrorInfo {
        switch error {
        case .invalidURL:
            return ErrorInfo(category: .invalidInput, originalError: error)
            
        case .requestFailed(let status, _):
            if status == 429 {
                return ErrorInfo(
                    category: .rateLimited,
                    canRetryAutomatically: true,
                    retryDelay: 30,
                    originalError: error
                )
            } else if status >= 500 {
                return ErrorInfo(
                    category: .temporaryUnavailable,
                    canRetryAutomatically: true,
                    retryDelay: 60,
                    originalError: error
                )
            } else if status == 404 {
                return ErrorInfo(category: .locationResolution, originalError: error)
            } else {
                return ErrorInfo(category: .unknown, originalError: error)
            }
            
        case .rateLimited(let retryAfter):
            return ErrorInfo(
                category: .rateLimited,
                canRetryAutomatically: true,
                retryDelay: retryAfter ?? 30,
                originalError: error
            )
            
        case .network(_):
            return ErrorInfo(category: .networkConnection, originalError: error)
            
        case .tooManyRetries:
            return ErrorInfo(category: .temporaryUnavailable, originalError: error)
            
        case .decodingFailed(_), .noData:
            return ErrorInfo(
                category: .temporaryUnavailable,
                canRetryAutomatically: true,
                retryDelay: 10,
                originalError: error
            )
            
        case .requestCoalesced:
            // This isn't really an error for the user
            return ErrorInfo(category: .unknown, originalError: error)
        }
    }
    
    private func analyzeURLError(_ error: URLError) -> ErrorInfo {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return ErrorInfo(category: .networkConnection, originalError: error)
            
        case .timedOut:
            return ErrorInfo(
                category: .temporaryUnavailable,
                canRetryAutomatically: true,
                retryDelay: 15,
                originalError: error
            )
            
        case .cannotFindHost, .dnsLookupFailed:
            return ErrorInfo(category: .temporaryUnavailable, originalError: error)
            
        default:
            return ErrorInfo(category: .networkConnection, originalError: error)
        }
    }
    
    private func analyzeLocationError(_ error: CLError) -> ErrorInfo {
        switch error.code {
        case .locationUnknown, .geocodeFoundNoResult:
            return ErrorInfo(category: .locationResolution, originalError: error)
            
        case .denied:
            return ErrorInfo(category: .invalidInput, originalError: error)
            
        case .network:
            return ErrorInfo(category: .networkConnection, originalError: error)
            
        default:
            return ErrorInfo(category: .locationResolution, originalError: error)
        }
    }
    
    // MARK: - Smart Fallback Strategies
    
    func generateLocationFallbacks(
        for query: String,
        userLocation: CLLocation? = nil
    ) async -> LocationFallbackOptions {
        
        var alternatives: [String] = []
        
        // Add common station variations
        let commonVariations = generateLocationVariations(for: query)
        alternatives.append(contentsOf: commonVariations)
        
        // Add nearby major stations if we have user location
        if let location = userLocation {
            let nearbyStations = await findNearbyMajorStations(near: location)
            alternatives.append(contentsOf: nearbyStations)
        }
        
        // Add generic major stations for the region
        alternatives.append(contentsOf: ["Hauptbahnhof", "Central Station", "Airport"])
        
        return LocationFallbackOptions(
            useCurrentLocation: userLocation != nil,
            searchNearbyStations: userLocation != nil,
            allowCoordinateEntry: true,
            suggestedAlternatives: Array(Set(alternatives).prefix(5))
        )
    }
    
    private func generateLocationVariations(for query: String) -> [String] {
        var variations: [String] = []
        
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add/remove common suffixes
        let suffixes = ["Bahnhof", "Station", "Hbf", "Hauptbahnhof"]
        
        for suffix in suffixes {
            // Add suffix if not present
            if !cleanQuery.lowercased().contains(suffix.lowercased()) {
                variations.append("\(cleanQuery) \(suffix)")
            }
            
            // Remove suffix if present
            if cleanQuery.lowercased().hasSuffix(suffix.lowercased()) {
                let withoutSuffix = String(cleanQuery.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
                if !withoutSuffix.isEmpty {
                    variations.append(withoutSuffix)
                }
            }
        }
        
        // Add common abbreviations
        let abbreviations: [String: String] = [
            "hbf": "hauptbahnhof",
            "bf": "bahnhof",
            "str": "straße"
        ]
        
        for (short, long) in abbreviations {
            if cleanQuery.lowercased().contains(short) {
                variations.append(cleanQuery.replacingOccurrences(of: short, with: long, options: .caseInsensitive))
            }
            if cleanQuery.lowercased().contains(long) {
                variations.append(cleanQuery.replacingOccurrences(of: long, with: short, options: .caseInsensitive))
            }
        }
        
        return variations
    }
    
    private func findNearbyMajorStations(near location: CLLocation) async -> [String] {
        // This would integrate with your location resolver to find actual nearby stations
        // For now, return some common German station names as examples
        return [
            "Hauptbahnhof",
            "Ostbahnhof", 
            "Westbahnhof",
            "Südbahnhof",
            "Nordbahnhof"
        ]
    }
    
    // MARK: - Journey Fallback Strategies
    
    func generateJourneyFallbacks(
        from: Place,
        to: Place,
        originalDepartureTime: Date
    ) -> [JourneyFallbackStrategy] {
        
        var strategies: [JourneyFallbackStrategy] = []
        
        // Time-based fallbacks
        strategies.append(.adjustDepartureTime(originalDepartureTime.addingTimeInterval(900))) // +15 min
        strategies.append(.adjustDepartureTime(originalDepartureTime.addingTimeInterval(-900))) // -15 min
        strategies.append(.adjustDepartureTime(originalDepartureTime.addingTimeInterval(1800))) // +30 min
        
        // Location-based fallbacks (if locations have coordinates)
        if from.hasValidCoordinates && to.hasValidCoordinates {
            strategies.append(.expandSearchRadius)
        }
        
        // Route reversal (sometimes helps with data availability)
        strategies.append(.reverseRoute)
        
        return strategies
    }
    
    enum JourneyFallbackStrategy {
        case adjustDepartureTime(Date)
        case expandSearchRadius
        case reverseRoute
        
        var displayText: String {
            switch self {
            case .adjustDepartureTime(let time):
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "Try departing at \(formatter.string(from: time))"
            case .expandSearchRadius:
                return "Search nearby stations"
            case .reverseRoute:
                return "Try reverse route"
            }
        }
    }
}

// MARK: - Error Recovery Coordinator

extension ErrorHandlingService {
    
    /// Attempt automatic error recovery with fallback strategies
    func attemptRecovery(
        for error: Error,
        with context: ErrorRecoveryContext
    ) async throws -> ErrorRecoveryResult {
        
        let errorInfo = analyzeError(error)
        
        if errorInfo.canRetryAutomatically {
            return try await attemptAutomaticRetry(errorInfo: errorInfo, context: context)
        } else {
            return .requiresUserInput(errorInfo)
        }
    }
    
    private func attemptAutomaticRetry(
        errorInfo: ErrorInfo,
        context: ErrorRecoveryContext
    ) async throws -> ErrorRecoveryResult {
        
        if let delay = errorInfo.retryDelay {
            print("⏳ [ErrorHandlingService] Waiting \(delay)s before retry...")
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Attempt the recovery based on context
        switch context {
        case .locationSearch(let query):
            // Try location search with variations
            return .retryWithFallback(.locationVariations(generateLocationVariations(for: query)))
            
        case .journeyPlanning(let from, let to, let time):
            // Try journey planning with adjusted parameters
            let fallbacks = generateJourneyFallbacks(from: from, to: to, originalDepartureTime: time)
            return .retryWithFallback(.journeyFallbacks(fallbacks))
            
        case .journeyRefresh:
            // For refresh failures, fall back to full planning
            return .retryWithFallback(.forceFullReplanning)
        }
    }
    
    enum ErrorRecoveryContext {
        case locationSearch(String)
        case journeyPlanning(Place, Place, Date)
        case journeyRefresh
    }
    
    enum ErrorRecoveryResult {
        case recovered
        case retryWithFallback(FallbackStrategy)
        case requiresUserInput(ErrorInfo)
    }
    
    enum FallbackStrategy {
        case locationVariations([String])
        case journeyFallbacks([JourneyFallbackStrategy])
        case forceFullReplanning
    }
}
