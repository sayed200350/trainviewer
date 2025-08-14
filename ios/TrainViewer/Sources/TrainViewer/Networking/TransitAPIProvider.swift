import Foundation

final class TransitAPIProvider {
    static let shared = TransitAPIProvider()
    let api: TransitAPI

    init() {
        // Prefer live API; fallback to stub if needed
        api = LiveTransitAPI()
    }
}


