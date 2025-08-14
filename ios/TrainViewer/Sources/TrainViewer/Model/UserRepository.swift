import Foundation
import CoreData

struct UserRepository {
    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    func getOrCreateLocalUser() throws -> UserEntity {
        let context = persistence.viewContext
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.fetchLimit = 1
        if let existing = try context.fetch(request).first { return existing }
        let user = UserEntity(context: context)
        user.id = UUID().uuidString
        try context.save()
        return user
    }
}


