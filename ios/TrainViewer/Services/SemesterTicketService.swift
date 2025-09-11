import Foundation
import CoreData
import UIKit
import SwiftUI

final class SemesterTicketService {
    static let shared = SemesterTicketService()

    private let context = CoreDataStack.shared.context
    private let notificationService = SemesterTicketNotificationService.shared

    // MARK: - CRUD Operations

    func createTicket(universityId: String,
                     universityName: String,
                     photoData: Data?,
                     validityStart: Date,
                     validityEnd: Date) -> Result<SemesterTicket, Error> {
        let ticket = SemesterTicketEntity(context: context)
        ticket.id = UUID()
        ticket.universityId = universityId
        ticket.universityName = universityName
        ticket.photoData = photoData
        ticket.validityStart = validityStart
        ticket.validityEnd = validityEnd
        ticket.createdAt = Date()

        do {
            try context.save()
            let semesterTicket = SemesterTicket(from: ticket)

            // Schedule renewal notifications
            Task {
                await notificationService.scheduleRenewalNotifications(for: semesterTicket)
            }

            return .success(semesterTicket)
        } catch {
            context.rollback()
            return .failure(error)
        }
    }

    func fetchAllTickets() -> Result<[SemesterTicket], Error> {
        let request = NSFetchRequest<SemesterTicketEntity>(entityName: "SemesterTicketEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            let entities = try context.fetch(request)
            let tickets = entities.map { SemesterTicket(from: $0) }
            return .success(tickets)
        } catch {
            return .failure(error)
        }
    }

    func fetchTicket(withId id: UUID) -> Result<SemesterTicket?, Error> {
        let request = NSFetchRequest<SemesterTicketEntity>(entityName: "SemesterTicketEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            let entities = try context.fetch(request)
            let ticket = entities.first.map { SemesterTicket(from: $0) }
            return .success(ticket)
        } catch {
            return .failure(error)
        }
    }

    func updateTicket(id: UUID,
                     photoData: Data? = nil,
                     validityStart: Date? = nil,
                     validityEnd: Date? = nil) -> Result<SemesterTicket, Error> {
        let request = NSFetchRequest<SemesterTicketEntity>(entityName: "SemesterTicketEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            let entities = try context.fetch(request)
            guard let entity = entities.first else {
                return .failure(NSError(domain: "SemesterTicketService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Ticket not found"]))
            }

            if let photoData = photoData {
                entity.photoData = photoData
            }
            if let validityStart = validityStart {
                entity.validityStart = validityStart
            }
            if let validityEnd = validityEnd {
                entity.validityEnd = validityEnd
            }

            try context.save()
            let updatedTicket = SemesterTicket(from: entity)

            // Reschedule notifications if validity dates changed
            if validityStart != nil || validityEnd != nil {
                Task {
                    await notificationService.scheduleRenewalNotifications(for: updatedTicket)
                }
            }

            return .success(updatedTicket)
        } catch {
            context.rollback()
            return .failure(error)
        }
    }

    func deleteTicket(withId id: UUID) -> Result<Void, Error> {
        let request = NSFetchRequest<SemesterTicketEntity>(entityName: "SemesterTicketEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            let entities = try context.fetch(request)
            guard let entity = entities.first else {
                return .failure(NSError(domain: "SemesterTicketService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Ticket not found"]))
            }

            context.delete(entity)
            try context.save()

            // Cancel renewal notifications for deleted ticket
            Task {
                await notificationService.cancelRenewalNotifications(for: id)
            }

            return .success(())
        } catch {
            context.rollback()
            return .failure(error)
        }
    }

    func deleteAllTickets() -> Result<Void, Error> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SemesterTicketEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(deleteRequest)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Photo Management

    func processImageForStorage(_ image: UIImage,
                               maxSize: CGSize = CGSize(width: 1200, height: 1600),
                               compressionQuality: CGFloat = 0.8) -> Data? {
        // Resize image if needed
        let resizedImage = resizeImage(image, to: maxSize)

        // Compress to JPEG
        return resizedImage.jpegData(compressionQuality: compressionQuality)
    }

    private func resizeImage(_ image: UIImage, to maxSize: CGSize) -> UIImage {
        let aspectRatio = image.size.width / image.size.height
        var newSize = maxSize

        if aspectRatio > 1 {
            // Landscape
            newSize.height = maxSize.width / aspectRatio
        } else {
            // Portrait
            newSize.width = maxSize.height * aspectRatio
        }

        let rect = CGRect(origin: .zero, size: newSize)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }

    // MARK: - Validation

    func validateTicketData(universityId: String,
                           validityStart: Date,
                           validityEnd: Date) -> Result<Void, ValidationError> {
        // Check if university exists
        guard University.universityById(universityId) != nil else {
            return .failure(.invalidUniversity)
        }

        // Check validity dates
        guard validityStart < validityEnd else {
            return .failure(.invalidValidityPeriod)
        }

        // Check if end date is not too far in the future (max 2 years)
        let maxEndDate = Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date()
        guard validityEnd <= maxEndDate else {
            return .failure(.validityPeriodTooLong)
        }

        // Check if start date is not in the past (allow some flexibility)
        let minStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        guard validityStart >= minStartDate else {
            return .failure(.startDateTooOld)
        }

        return .success(())
    }

    // MARK: - University Data Management

    func preloadUniversityDataIfNeeded() -> Result<Void, Error> {
        let request = NSFetchRequest<UniversityEntity>(entityName: "UniversityEntity")
        request.fetchLimit = 1

        do {
            let count = try context.count(for: request)
            if count == 0 {
                // Preload university data
                return preloadUniversityData()
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private func preloadUniversityData() -> Result<Void, Error> {
        for university in University.germanUniversities {
            let entity = UniversityEntity(context: context)
            entity.id = university.id
            entity.name = university.name
            entity.city = university.city
            entity.state = university.state
            entity.latitude = university.latitude as NSNumber?
            entity.longitude = university.longitude as NSNumber?
            entity.website = university.website
            entity.brandColor = university.brandColor
        }

        do {
            try context.save()
            return .success(())
        } catch {
            context.rollback()
            return .failure(error)
        }
    }

    // MARK: - Utility Methods

    func getTicketsByValidityStatus(_ status: ValidityStatus) -> Result<[SemesterTicket], Error> {
        let allTicketsResult = fetchAllTickets()

        switch allTicketsResult {
        case .success(let tickets):
            let filteredTickets = tickets.filter { $0.validityStatus == status }
            return .success(filteredTickets)
        case .failure(let error):
            return .failure(error)
        }
    }

    func getCurrentValidTicket() -> Result<SemesterTicket?, Error> {
        let allTicketsResult = fetchAllTickets()

        switch allTicketsResult {
        case .success(let tickets):
            let validTickets = tickets.filter { $0.validityStatus == .valid }
            // Return the most recently created valid ticket
            return .success(validTickets.sorted { $0.createdAt > $1.createdAt }.first)
        case .failure(let error):
            return .failure(error)
        }
    }
}

// MARK: - Validation Error
enum ValidationError: LocalizedError {
    case invalidUniversity
    case invalidValidityPeriod
    case validityPeriodTooLong
    case startDateTooOld

    var errorDescription: String? {
        switch self {
        case .invalidUniversity:
            return "Ungültige Universität ausgewählt"
        case .invalidValidityPeriod:
            return "Das Startdatum muss vor dem Enddatum liegen"
        case .validityPeriodTooLong:
            return "Der Gültigkeitszeitraum darf maximal 2 Jahre betragen"
        case .startDateTooOld:
            return "Das Startdatum darf nicht mehr als einen Monat in der Vergangenheit liegen"
        }
    }
}

// MARK: - Observable Service
class ObservableSemesterTicketService: ObservableObject {
    static let shared = ObservableSemesterTicketService()

    @Published var tickets: [SemesterTicket] = []
    @Published var currentTicket: SemesterTicket?

    private let service = SemesterTicketService.shared

    init() {
        loadTickets()
        preloadData()
    }

    func loadTickets() {
        switch service.fetchAllTickets() {
        case .success(let tickets):
            self.tickets = tickets
            self.currentTicket = tickets.first { $0.validityStatus == .valid }
        case .failure(let error):
            print("Error loading tickets: \(error)")
        }
    }

    func addTicket(_ ticket: SemesterTicket) {
        tickets.insert(ticket, at: 0)
        if ticket.validityStatus == .valid {
            currentTicket = ticket
        }
    }

    func updateTicket(_ updatedTicket: SemesterTicket) {
        if let index = tickets.firstIndex(where: { $0.id == updatedTicket.id }) {
            tickets[index] = updatedTicket
            if updatedTicket.validityStatus == .valid {
                currentTicket = updatedTicket
            } else if currentTicket?.id == updatedTicket.id {
                currentTicket = nil
            }
        }
    }

    func removeTicket(withId id: UUID) {
        tickets.removeAll { $0.id == id }
        if currentTicket?.id == id {
            currentTicket = tickets.first { $0.validityStatus == .valid }
        }
    }

    private func preloadData() {
        Task {
            _ = await service.preloadUniversityDataIfNeeded()
        }
    }
}
