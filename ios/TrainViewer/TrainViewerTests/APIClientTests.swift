import Testing
import Foundation
@testable import TrainViewer

struct APIClientTests {
    
    // MARK: - HTTPCache Tests
    
    @Test("HTTPCache stores and retrieves responses correctly")
    func testHTTPCacheStoreAndRetrieve() async throws {
        let cache = HTTPCache()
        let url = "https://example.com/api/test"
        let testData = "test response".data(using: .utf8)!
        let etag = "\"test-etag\""
        let cacheControl = "max-age=300"
        
        // Store response
        cache.store(url: url, data: testData, etag: etag, cacheControl: cacheControl)
        
        // Retrieve response
        let cachedResponse = cache.retrieve(url: url)
        
        #expect(cachedResponse != nil)
        #expect(cachedResponse?.data == testData)
        #expect(cachedResponse?.etag == etag)
        #expect(cachedResponse?.maxAge == 300.0)
        #expect(cachedResponse?.isExpired == false)
    }
    
    @Test("HTTPCache correctly identifies expired responses")
    func testHTTPCacheExpiration() async throws {
        let cache = HTTPCache()
        let url = "https://example.com/api/expired"
        let testData = "expired response".data(using: .utf8)!
        let cacheControl = "max-age=1" // 1 second
        
        // Store response
        cache.store(url: url, data: testData, etag: nil, cacheControl: cacheControl)
        
        // Wait for expiration
        try await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds
        
        let cachedResponse = cache.retrieve(url: url)
        #expect(cachedResponse?.isExpired == true)
    }
    
    @Test("HTTPCache parses cache control headers correctly")
    func testHTTPCacheParseCacheControl() async throws {
        let cache = HTTPCache()
        let url = "https://example.com/api/cache-control"
        let testData = "cache control test".data(using: .utf8)!
        
        // Test max-age
        cache.store(url: url + "1", data: testData, etag: nil, cacheControl: "max-age=600")
        let response1 = cache.retrieve(url: url + "1")
        #expect(response1?.maxAge == 600.0)
        
        // Test s-maxage (should take precedence)
        cache.store(url: url + "2", data: testData, etag: nil, cacheControl: "max-age=300, s-maxage=900")
        let response2 = cache.retrieve(url: url + "2")
        #expect(response2?.maxAge == 900.0)
        
        // Test no cache control
        cache.store(url: url + "3", data: testData, etag: nil, cacheControl: nil)
        let response3 = cache.retrieve(url: url + "3")
        #expect(response3?.maxAge == nil)
    }
    
    // MARK: - APIError Tests
    
    @Test("APIError provides correct error descriptions")
    func testAPIErrorDescriptions() async throws {
        #expect(APIError.invalidURL.errorDescription == "Invalid URL")
        #expect(APIError.noData.errorDescription == "No data in response")
        #expect(APIError.tooManyRetries.errorDescription == "Too many retry attempts")
        #expect(APIError.requestCoalesced.errorDescription == "Request was coalesced with existing request")
        
        let networkError = NSError(domain: "TestDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Network timeout"])
        #expect(APIError.network(networkError).errorDescription == "Network error: Network timeout")
        
        let decodingError = NSError(domain: "DecodingDomain", code: 2001, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
        #expect(APIError.decodingFailed(decodingError).errorDescription == "Decoding failed: Invalid JSON")
        
        #expect(APIError.requestFailed(status: 404, body: "Not Found").errorDescription == "HTTP 404: Not Found")
        
        #expect(APIError.rateLimited(retryAfter: 30.5).errorDescription == "Rate limited, retry after: 30.5s")
        #expect(APIError.rateLimited(retryAfter: nil).errorDescription == "Rate limited, retry after: unknowns")
    }
    
    // MARK: - RetryConfiguration Tests
    
    @Test("RetryConfiguration has correct default values")
    func testRetryConfigurationDefaults() async throws {
        let config = RetryConfiguration.default
        
        #expect(config.maxAttempts == 3)
        #expect(config.baseDelay == 1.0)
        #expect(config.maxDelay == 30.0)
        #expect(config.multiplier == 2.0)
        #expect(config.jitter == 0.1)
    }
    
    // MARK: - JSON Decoding Tests
    
    @Test("APIClient decodes JSON correctly")
    func testJSONDecoding() async throws {
        struct TestModel: Codable {
            let id: Int
            let name: String
        }
        
        let testJSON = """
        {
            "id": 123,
            "name": "Test Model"
        }
        """.data(using: .utf8)!
        
        let decoded = try APIClient.decode(data: testJSON, as: TestModel.self)
        
        #expect(decoded.id == 123)
        #expect(decoded.name == "Test Model")
    }
    
    @Test("APIClient handles decoding errors correctly")
    func testJSONDecodingError() async throws {
        struct TestModel: Codable {
            let id: Int
            let name: String
        }
        
        let invalidJSON = "invalid json".data(using: .utf8)!
        
        do {
            _ = try APIClient.decode(data: invalidJSON, as: TestModel.self)
            #expect(Bool(false), "Should have thrown decoding error")
        } catch APIError.decodingFailed {
            // Expected error
        } catch {
            #expect(Bool(false), "Should have thrown APIError.decodingFailed, got \(error)")
        }
    }
    
    @Test("APIClient handles transport.rest date formats correctly")
    func testTransportRestDateDecoding() async throws {
        struct TestDateModel: Codable {
            let timestamp: Date
        }
        
        let testCases = [
            ("2024-03-29T12:34:56+01:00", "ISO8601 with timezone"),
            ("2024-03-29T12:34:56.123+01:00", "ISO8601 with milliseconds and timezone"),
            ("2024-03-29T12:34:56Z", "ISO8601 with Z timezone"),
            ("2024-03-29T12:34:56.123Z", "ISO8601 with milliseconds and Z timezone")
        ]
        
        for (dateString, description) in testCases {
            let json = """
            {
                "timestamp": "\(dateString)"
            }
            """.data(using: .utf8)!
            
            do {
                let decoded = try APIClient.decode(data: json, as: TestDateModel.self)
                #expect(decoded.timestamp != Date.distantPast, "Failed to decode \(description)")
            } catch {
                #expect(Bool(false), "Failed to decode \(description): \(error)")
            }
        }
    }
    
    // MARK: - Mock URLSession Tests
    
    @Test("APIClient handles successful responses")
    func testSuccessfulResponse() async throws {
        // This test would require dependency injection for URLSession
        // For now, we'll test the decode functionality which is static
        
        struct TestResponse: Codable {
            let success: Bool
            let message: String
        }
        
        let responseJSON = """
        {
            "success": true,
            "message": "Operation completed successfully"
        }
        """.data(using: .utf8)!
        
        let decoded = try APIClient.decode(data: responseJSON, as: TestResponse.self)
        
        #expect(decoded.success == true)
        #expect(decoded.message == "Operation completed successfully")
    }
    
    // MARK: - Helper Methods Tests
    
    @Test("CachedResponse correctly identifies expiration")
    func testCachedResponseExpiration() async throws {
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now
        
        // Expired response
        let expiredResponse = CachedResponse(
            data: Data(),
            etag: nil,
            maxAge: 1800, // 30 minutes
            cachedAt: pastDate
        )
        #expect(expiredResponse.isExpired == true)
        
        // Fresh response
        let freshResponse = CachedResponse(
            data: Data(),
            etag: nil,
            maxAge: 7200, // 2 hours
            cachedAt: Date()
        )
        #expect(freshResponse.isExpired == false)
        
        // Response without maxAge (never expires)
        let noMaxAgeResponse = CachedResponse(
            data: Data(),
            etag: nil,
            maxAge: nil,
            cachedAt: pastDate
        )
        #expect(noMaxAgeResponse.isExpired == false)
    }
}