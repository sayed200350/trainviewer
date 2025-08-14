import Foundation

protocol AuthProvider {
    var isAuthenticated: Bool { get }
    func signInAnonymously() async throws
    func signOut() async throws
}

final class LocalAuthProvider: AuthProvider {
    private let key = "auth.local.signedIn"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    var isAuthenticated: Bool { defaults.bool(forKey: key) }

    func signInAnonymously() async throws {
        defaults.set(true, forKey: key)
    }

    func signOut() async throws {
        defaults.set(false, forKey: key)
    }
}


