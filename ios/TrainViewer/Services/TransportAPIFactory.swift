import Foundation

final class TransportAPIFactory {
    static let shared = TransportAPIFactory()
    private init() {}

    func make() -> TransportAPI {
        let preference = UserSettingsStore.shared.providerPreference
        switch preference {
        case .db:
            return DBTransportAPI(provider: ProviderPreference.db)
        case .vbb:
            return DBTransportAPI(provider: ProviderPreference.vbb)
        case .auto:
            return AutoTransportAPI(primary: DBTransportAPI(provider: ProviderPreference.db), fallback: DBTransportAPI(provider: ProviderPreference.vbb))
        }
    }
    
    static func createAPI() -> TransportAPI {
        return shared.make()
    }
}