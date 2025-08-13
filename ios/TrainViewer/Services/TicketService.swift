import Foundation
import Security

enum TicketServiceError: Error {
    case notFound
    case invalidResponse
}

final class TicketService {
    static let shared = TicketService()
    private init() {}

    private let keychainService = "com.trainviewer.ticket"
    private let ticketKey = "student_ticket"

    func loadCachedTicket() -> Ticket? {
        guard let data = readKeychain(account: ticketKey) else { return nil }
        return try? JSONDecoder().decode(Ticket.self, from: data)
    }

    func save(ticket: Ticket) {
        if let data = try? JSONEncoder().encode(ticket) {
            _ = writeKeychain(data: data, account: ticketKey)
        }
    }

    func clearTicket() {
        deleteKeychain(account: ticketKey)
    }

    func fetchTicket(from url: URL) async throws -> Ticket {
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw TicketServiceError.invalidResponse }
        let ticket = try JSONDecoder().decode(Ticket.self, from: data)
        save(ticket: ticket)
        return ticket
    }

    // MARK: - Keychain helpers
    private func writeKeychain(data: Data, account: String) -> Bool {
        deleteKeychain(account: account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    private func readKeychain(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return data
    }

    private func deleteKeychain(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}