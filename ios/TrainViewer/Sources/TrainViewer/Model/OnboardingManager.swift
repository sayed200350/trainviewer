import Foundation

final class OnboardingManager {
    static let shared = OnboardingManager()
    private let defaults: UserDefaults
    private let doneKey = "onboarding.completed"
    private init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    var isCompleted: Bool { defaults.bool(forKey: doneKey) }
    func markCompleted() { defaults.set(true, forKey: doneKey) }
}


