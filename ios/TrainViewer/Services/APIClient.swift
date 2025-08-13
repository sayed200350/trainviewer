import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(status: Int, body: String)
    case decodingFailed(Error)
    case network(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .requestFailed(let status, let body): return "HTTP \(status): \(body)"
        case .decodingFailed(let err): return "Decoding failed: \(err.localizedDescription)"
        case .network(let err): return "Network error: \(err.localizedDescription)"
        case .noData: return "No data in response"
        }
    }
}

final class APIClient {
    static let shared = APIClient()
    private init() {}

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

    func get<T: Decodable>(_ url: URL, as type: T.Type, dateDecoding: JSONDecoder.DateDecodingStrategy = APIClient.transportRestDateDecoder) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.noData }
            guard (200..<300).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? ""
                throw APIError.requestFailed(status: http.statusCode, body: body)
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = dateDecoding
            decoder.keyDecodingStrategy = .useDefaultKeys
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingFailed(error)
            }
        } catch {
            throw APIError.network(error)
        }
    }
}