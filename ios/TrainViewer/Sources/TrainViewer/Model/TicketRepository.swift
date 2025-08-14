import Foundation
import CoreData

struct TicketRepository {
    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    func upsert(
        for user: UserEntity,
        type: String,
        zones: String?,
        expiry: Date?,
        imageRef: String?
    ) throws {
        let context = persistence.viewContext
        let ticket = user.ticket ?? TicketEntity(context: context)
        if user.ticket == nil { ticket.id = UUID().uuidString }
        ticket.type = type
        ticket.zones = zones
        ticket.expiry = expiry
        ticket.imageRef = imageRef
        ticket.user = user
        user.ticket = ticket
        try context.save()
    }

    func delete(for user: UserEntity) throws {
        guard let ticket = user.ticket else { return }
        let context = persistence.viewContext
        context.delete(ticket)
        user.ticket = nil
        try context.save()
    }
}


