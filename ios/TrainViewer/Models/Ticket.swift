import Foundation

public enum StudentTicketStatus: String, Codable, Equatable {
    case active
    case suspended
    case expired
}

public enum TicketBarcodeFormat: String, Codable, Equatable {
    case qr
    case aztec
}

public struct Ticket: Codable, Equatable, Identifiable {
    public let id: UUID
    public let status: StudentTicketStatus
    public let validFrom: Date
    public let expiresAt: Date
    public let qrPayload: String
    public let format: TicketBarcodeFormat

    public init(id: UUID = UUID(), status: StudentTicketStatus, validFrom: Date, expiresAt: Date, qrPayload: String, format: TicketBarcodeFormat) {
        self.id = id
        self.status = status
        self.validFrom = validFrom
        self.expiresAt = expiresAt
        self.qrPayload = qrPayload
        self.format = format
    }

    public var isExpired: Bool { Date() >= expiresAt }
}