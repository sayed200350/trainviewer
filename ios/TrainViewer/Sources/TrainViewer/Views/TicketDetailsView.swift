import SwiftUI
import CoreData

struct TicketDetailsView: View {
    @Environment(\.managedObjectContext) private var context
    private let userRepo = UserRepository()
    private let ticketRepo = TicketRepository()

    @State private var holderName: String = ""
    @State private var ticketType: String = "Semester"
    @State private var zones: String = "ABC"
    @State private var expiry: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var showingSaved = false

    var body: some View {
        Form {
            Section("Semester Ticket") {
                TextField("Ticket holder", text: $holderName)
                TextField("Type", text: $ticketType)
                TextField("Zones (e.g., ABC)", text: $zones)
                DatePicker("Valid until", selection: $expiry, displayedComponents: .date)
                Button("Save Ticket") { save() }
                if showingSaved { Text("Saved").foregroundColor(.green) }
            }
            Section("Notes") {
                Text("This is a placeholder. Connect to your real ticket provider later.")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Ticket")
        .task { load() }
    }

    private func load() {
        if let user = try? userRepo.getOrCreateLocalUser(), let t = user.ticket {
            ticketType = t.type
            zones = t.zones ?? ""
            expiry = t.expiry ?? expiry
        }
    }

    private func save() {
        guard let user = try? userRepo.getOrCreateLocalUser() else { return }
        do {
            try ticketRepo.upsert(
                for: user,
                type: ticketType,
                zones: zones.isEmpty ? nil : zones,
                expiry: expiry,
                imageRef: nil
            )
            showingSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showingSaved = false }
        } catch {
            // swallow for MVP
        }
    }
}


