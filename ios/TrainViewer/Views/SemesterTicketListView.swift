import SwiftUI

struct SemesterTicketListView: View {
    @StateObject private var ticketService = ObservableSemesterTicketService.shared
    @State private var selectedTicket: SemesterTicket?
    @State private var showSetupView = false

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }

    var body: some View {
        NavigationView {
            Group {
                if ticketService.tickets.isEmpty {
                    emptyStateView
                } else {
                    ticketListView
                }
            }
            .navigationTitle("Semester Tickets")
            .navigationBarItems(trailing: addButton)
            .sheet(isPresented: $showSetupView) {
                SemesterTicketSetupView()
            }
            #if !os(watchOS) && !targetEnvironment(macCatalyst)
            .sheet(item: $selectedTicket) { ticket in
                SemesterTicketDisplayView(ticket: ticket)
            }
            #endif
        }
    }

    private var addButton: some View {
        Button(action: {
            showSetupView = true
        }) {
            Image(systemName: "plus")
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "ticket")
                    .font(.system(size: 80))
                    .foregroundColor(.secondary.opacity(0.5))

                Text("No Semester Tickets")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text("Add your semester ticket to always have it with you.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: {
                showSetupView = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Add Semester Ticket")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.brandBlue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .background(Color.brandDark.edgesIgnoringSafeArea(.all))
    }

    private var ticketListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Current valid ticket (if any)
                if let currentTicket = ticketService.currentTicket {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Ticket")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)

                        TicketCard(ticket: currentTicket)
                            .onTapGesture {
                                selectedTicket = currentTicket
                            }
                    }
                }

                // All tickets
                VStack(alignment: .leading, spacing: 8) {
                    Text("All Tickets")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)

                    ForEach(ticketService.tickets.sorted(by: { $0.createdAt > $1.createdAt })) { ticket in
                        TicketCard(ticket: ticket)
                            .onTapGesture {
                                selectedTicket = ticket
                            }
                    }
                }
            }
            .padding(.vertical, 20)
        }
        .background(Color.brandDark.edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Ticket Card Component
struct TicketCard: View {
    let ticket: SemesterTicket

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Ticket preview
            ZStack(alignment: .bottomLeading) {
                if let image = ticket.ticketImage {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                } else {
                    Color.cardBackground
                        .frame(height: 120)
                        .overlay(
                            Image(systemName: "doc.text.image")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                        )
                }

                // Validity status overlay
                VStack(alignment: .leading, spacing: 4) {
                    Text(ticket.universityName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(ticket.validityStatus.color)
                            .frame(width: 6, height: 6)

                        Text(ticket.validityStatus.displayText)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0.3)]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(8)
                .padding(12)
            }

            // Ticket details
            VStack(alignment: .leading, spacing: 8) {
                Text("Valid until: \(dateFormatter.string(from: ticket.validityEnd))")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                if let daysUntilExpiry = ticket.daysUntilExpiry {
                    Text("\(daysUntilExpiry) days remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("Added: \(dateFormatter.string(from: ticket.createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
        }
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview
struct SemesterTicketListView_Previews: PreviewProvider {
    static var previews: some View {
        SemesterTicketListView()
            .preferredColorScheme(.dark)
    }
}
