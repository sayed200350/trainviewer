import Foundation

final class TransportAPIFactory {
    static let shared = TransportAPIFactory()
    private init() {}

    func make() -> TransportAPI {
        let preference = UserSettingsStore.shared.providerPreference
        switch preference {
        case .db:
            return DBTransportAPI(provider: .db)
        case .vbb:
            return DBTransportAPI(provider: .vbb)
        case .auto:
            return AutoTransportAPI(primary: DBTransportAPI(provider: .db), fallback: DBTransportAPI(provider: .vbb))
        }
    }
    
    static func createAPI() -> TransportAPI {
        return shared.make()
    }
}