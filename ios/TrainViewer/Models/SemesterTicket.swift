import Foundation
import SwiftUI
import CoreLocation

public struct SemesterTicket: Identifiable, Codable, Hashable {
    public let id: UUID
    public let photoData: Data?
    public let universityName: String
    public let universityId: String
    public let validityStart: Date
    public let validityEnd: Date
    public let createdAt: Date

    public var university: University? {
        return University.universityById(universityId)
    }

    public var isValid: Bool {
        let now = Date()
        return now >= validityStart && now <= validityEnd
    }

    public var validityStatus: ValidityStatus {
        let now = Date()
        if now < validityStart {
            return .upcoming
        } else if now <= validityEnd {
            return .valid
        } else {
            return .expired
        }
    }

    public var daysUntilExpiry: Int? {
        let calendar = Calendar.current
        let now = Date()
        if now > validityEnd {
            return nil // Already expired
        }
        let components = calendar.dateComponents([.day], from: now, to: validityEnd)
        return components.day
    }

    public var validityPeriodString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "de_DE")

        let startString = formatter.string(from: validityStart)
        let endString = formatter.string(from: validityEnd)

        return "\(startString) - \(endString)"
    }

    public init(id: UUID = UUID(),
                photoData: Data? = nil,
                universityName: String,
                universityId: String,
                validityStart: Date,
                validityEnd: Date,
                createdAt: Date = Date()) {
        self.id = id
        self.photoData = photoData
        self.universityName = universityName
        self.universityId = universityId
        self.validityStart = validityStart
        self.validityEnd = validityEnd
        self.createdAt = createdAt
    }

    // Create from Core Data entity
    internal init(from entity: SemesterTicketEntity) {
        self.id = entity.id
        self.photoData = entity.photoData
        self.universityName = entity.universityName
        self.universityId = entity.universityId
        self.validityStart = entity.validityStart
        self.validityEnd = entity.validityEnd
        self.createdAt = entity.createdAt
    }
}

public enum ValidityStatus {
    case upcoming
    case valid
    case expired

    public var displayText: String {
        switch self {
        case .upcoming: return "Bald gültig"
        case .valid: return "Gültig"
        case .expired: return "Abgelaufen"
        }
    }

    public var color: Color {
        switch self {
        case .upcoming: return .accentGreen
        case .valid: return .successColor
        case .expired: return .errorColor
        }
    }
}

// MARK: - Extensions for Image Handling
extension SemesterTicket {
    public var ticketImage: Image? {
        guard let photoData = photoData,
              let uiImage = UIImage(data: photoData) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }

    public var ticketUIImage: UIImage? {
        guard let photoData = photoData else { return nil }
        return UIImage(data: photoData)
    }
}

// MARK: - Convenience Initializers
extension SemesterTicket {
    public static func createWithUniversity(_ university: University,
                                          photoData: Data?,
                                          validityStart: Date,
                                          validityEnd: Date) -> SemesterTicket {
        return SemesterTicket(
            photoData: photoData,
            universityName: university.name,
            universityId: university.id,
            validityStart: validityStart,
            validityEnd: validityEnd
        )
    }
}
