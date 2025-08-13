import Foundation
import PassKit
import UIKit

final class PassKitService {
    static let shared = PassKitService()
    private init() {}

    func canAddPasses() -> Bool {
        PKPassLibrary.isPassLibraryAvailable()
    }

    func addPass(from data: Data, presenting viewController: UIViewController) throws {
        let pass = try PKPass(data: data)
        guard let addVC = PKAddPassesViewController(pass: pass) else { return }
        viewController.present(addVC, animated: true)
    }

    func addPass(from url: URL, presenting viewController: UIViewController) async throws {
        let (data, _) = try await URLSession.shared.data(from: url)
        try addPass(from: data, presenting: viewController)
    }

    func hasPass(withTypeId typeId: String) -> Bool {
        let library = PKPassLibrary()
        return library.passes().contains { $0.passTypeIdentifier == typeId }
    }
}