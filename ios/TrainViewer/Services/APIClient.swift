import Foundation
import UIKit

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(status: Int, body: String)
    case decodingFailed(Error)
    case network(Error)
    case noData
    case rateLimited(retryAfter: TimeInterval?)
    case tooManyRetries
    case requestCoalesced

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .requestFailed(let status, let body): return "HTTP \(status): \(body)"
        case .decodingFailed(let err): return "Decoding failed: \(err.localizedDescription)"
        case .network(let err): return "Network error: \(err.localizedDescription)"
        case .noData: return "No data in response"
        case .rateLimited(let retryAfter): 
            let after = retryAfter.map { String(format: "%.1f", $0) } ?? "unknown"
            return "Rate limited, retry after: \(after)s"
        case .tooManyRetries: return "Too many retry attempts"
        case .requestCoalesced: return "Request was coalesced with existing request"
        }
    }
}

// MARK: - Cache Management

struct CachedResponse {
    let data: Data
    let etag: String?
    let maxAge: TimeInterval?
    let cachedAt: Date
    
    var isExpired: Bool {
        guard let maxAge = maxAge else { return false }
        return Date().timeIntervalSince(cachedAt) > maxAge
    }
}

final class HTTPCache {
    private var cache: [String: CachedResponse] = [:]
    private let queue = DispatchQueue(label: "HTTPCache", attributes: .concurrent)
    
    func store(url: String, data: Data, etag: String?, cacheControl: String?) {
        let maxAge = parseCacheControl(cacheControl)
        let response = CachedResponse(
            data: data,
            etag: etag,
            maxAge: maxAge,
            cachedAt: Date()
        )
        
        queue.async(flags: .barrier) {
            self.cache[url] = response
        }
    }
    
    func retrieve(url: String) -> CachedResponse? {
        return queue.sync {
            return cache[url]
        }
    }
    
    private func parseCacheControl(_ cacheControl: String?) -> TimeInterval? {
        guard let cacheControl = cacheControl else { return nil }
        
        // Parse max-age or s-maxage from Cache-Control header
        let components = cacheControl.components(separatedBy: ",")
        for component in components {
            let trimmed = component.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("max-age=") {
                let value = String(trimmed.dropFirst(8))
                return TimeInterval(value)
            } else if trimmed.hasPrefix("s-maxage=") {
                let value = String(trimmed.dropFirst(9))
                return TimeInterval(value)
            }
        }
        return nil
    }
}

// MARK: - Request Coalescing

actor RequestCoalescer {
    private var inFlightRequests: [String: Task<Data, Error>] = [:]
    
    func coalesceRequest<T: Decodable>(
        url: URL,
        as type: T.Type,
        makeRequest: @escaping () async throws -> (Data, URLResponse)
    ) async throws -> T {
        let key = url.absoluteString
        
        // Check if there's already a request in flight for this URL
        if let existingTask = inFlightRequests[key] {
            print("🔄 [RequestCoalescer] Coalescing request for: \(url)")
            let data = try await existingTask.value
            return try APIClient.decode(data: data, as: type)
        }
        
        // Create new request task
        let task = Task<Data, Error> {
            defer {
                Task { @MainActor in await self.removeRequest(key: key) }
            }

            let (data, _) = try await makeRequest()
            return data
        }
        
        inFlightRequests[key] = task
        
        do {
            let data = try await task.value
            return try APIClient.decode(data: data, as: type)
        } catch {
            await removeRequest(key: key)
            throw error
        }
    }
    
    private func removeRequest(key: String) {
        inFlightRequests.removeValue(forKey: key)
    }
}

// MARK: - Retry Logic

struct RetryConfiguration {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let multiplier: Double
    let jitter: Double
    
    static let `default` = RetryConfiguration(
        maxAttempts: 3,
        baseDelay: 1.0,
        maxDelay: 30.0,
        multiplier: 2.0,
        jitter: 0.1
    )
}

// MARK: - Enhanced API Client

final class APIClient {
    static let shared = APIClient()
    
    private let cache = HTTPCache()
    private let coalescer = RequestCoalescer()
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    private static let transportRestDateDecoder: JSONDecoder.DateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let str = try container.decode(String.self)
        // transport.rest uses ISO8601 with fractions and timezone, e.g., 2024-03-29T12:34:56+01:00 or with Z
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssXXXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        ]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for f in formats {
            formatter.dateFormat = f
            if let date = formatter.date(from: str) { return date }
        }
        if let date = ISO8601DateFormatter().date(from: str) { return date }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date format: \(str)")
    }

    // MARK: - Public API
    
    func get<T: Decodable>(
        _ url: URL, 
        as type: T.Type, 
        dateDecoding: JSONDecoder.DateDecodingStrategy = APIClient.transportRestDateDecoder,
        enableCoalescing: Bool = true
    ) async throws -> T {
        
        if enableCoalescing {
            return try await coalescer.coalesceRequest(url: url, as: type) {
                return try await self.performRequest(url: url)
            }
        } else {
            let (data, _) = try await performRequest(url: url)
            return try Self.decode(data: data, as: type, dateDecoding: dateDecoding)
        }
    }
    
    // MARK: - Private Implementation
    
    private func performRequest(url: URL) async throws -> (Data, URLResponse) {
        return try await performRequestWithRetry(url: url, configuration: .default)
    }
    
    private func performRequestWithRetry(
        url: URL, 
        configuration: RetryConfiguration,
        attempt: Int = 1
    ) async throws -> (Data, URLResponse) {
        
        do {
            return try await performSingleRequest(url: url)
        } catch {
            // Determine if we should retry
            let shouldRetry = attempt < configuration.maxAttempts && isRetryableError(error)
            
            if shouldRetry {
                let delay = calculateRetryDelay(
                    attempt: attempt,
                    configuration: configuration
                )
                
                print("🔄 [APIClient] Retrying request (attempt \(attempt + 1)/\(configuration.maxAttempts)) after \(delay)s: \(url)")
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await performRequestWithRetry(
                    url: url,
                    configuration: configuration,
                    attempt: attempt + 1
                )
            } else {
                if attempt >= configuration.maxAttempts {
                    throw APIError.tooManyRetries
                } else {
                    throw error
                }
            }
        }
    }
    
    private func performSingleRequest(url: URL) async throws -> (Data, URLResponse) {
        print("🌐 [APIClient] Making GET request to: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add descriptive User-Agent
        #if APP_EXTENSION
        let userAgent = "TrainViewer/1.0 (iOS; Extension) contact@trainviewer.app"
        #else
        let userAgent = "TrainViewer/1.0 (iOS; \(UIDevice.current.systemVersion)) contact@trainviewer.app"
        #endif
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        // Check cache and add conditional headers
        let urlString = url.absoluteString
        if let cachedResponse = cache.retrieve(url: urlString) {
            if !cachedResponse.isExpired {
                print("📦 [APIClient] Using cached response for: \(url)")
                return (cachedResponse.data, HTTPURLResponse())
            }
            
            if let etag = cachedResponse.etag {
                request.setValue(etag, forHTTPHeaderField: "If-None-Match")
                print("🏷️ [APIClient] Added If-None-Match header: \(etag)")
            }
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else { 
            throw APIError.noData 
        }
        
        print("🌐 [APIClient] Response status: \(http.statusCode)")
        
        // Handle 304 Not Modified
        if http.statusCode == 304 {
            if let cachedResponse = cache.retrieve(url: urlString) {
                print("✅ [APIClient] 304 Not Modified - using cached data")
                return (cachedResponse.data, response)
            } else {
                throw APIError.noData
            }
        }
        
        // Handle rate limiting
        if http.statusCode == 429 || http.statusCode == 503 {
            let retryAfter = parseRetryAfter(http.allHeaderFields["Retry-After"] as? String)
            throw APIError.rateLimited(retryAfter: retryAfter)
        }
        
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("❌ [APIClient] HTTP Error \(http.statusCode): \(body)")
            throw APIError.requestFailed(status: http.statusCode, body: body)
        }
        
        // Cache successful response
        let etag = http.allHeaderFields["ETag"] as? String
        let cacheControl = http.allHeaderFields["Cache-Control"] as? String
        cache.store(url: urlString, data: data, etag: etag, cacheControl: cacheControl)
        
        print("✅ [APIClient] Successfully received response")
        return (data, response)
    }
    
    // MARK: - Helper Methods
    
    static func decode<T: Decodable>(
        data: Data, 
        as type: T.Type, 
        dateDecoding: JSONDecoder.DateDecodingStrategy = APIClient.transportRestDateDecoder
    ) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecoding
        decoder.keyDecodingStrategy = .useDefaultKeys
        
        do {
            let result = try decoder.decode(T.self, from: data)
            print("✅ [APIClient] Successfully decoded response")
            return result
        } catch {
            print("❌ [APIClient] Decoding failed: \(error)")
            throw APIError.decodingFailed(error)
        }
    }
    
    private func isRetryableError(_ error: Error) -> Bool {
        if case APIError.requestFailed(let status, _) = error {
            // Retry on server errors and rate limiting
            return status >= 500 || status == 429
        }
        
        if case APIError.network = error {
            return true
        }
        
        if case APIError.rateLimited = error {
            return true
        }
        
        return false
    }
    
    private func calculateRetryDelay(attempt: Int, configuration: RetryConfiguration) -> TimeInterval {
        let exponentialDelay = configuration.baseDelay * pow(configuration.multiplier, Double(attempt - 1))
        let cappedDelay = min(exponentialDelay, configuration.maxDelay)
        
        // Add jitter to prevent thundering herd
        let jitterRange = cappedDelay * configuration.jitter
        let jitter = Double.random(in: -jitterRange...jitterRange)
        
        return max(0, cappedDelay + jitter)
    }
    
    private func parseRetryAfter(_ retryAfter: String?) -> TimeInterval? {
        guard let retryAfter = retryAfter else { return nil }
        
        // Try parsing as seconds
        if let seconds = TimeInterval(retryAfter) {
            return seconds
        }
        
        // Try parsing as HTTP date
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        if let date = formatter.date(from: retryAfter) {
            return date.timeIntervalSinceNow
        }
        
        return nil
    }
}