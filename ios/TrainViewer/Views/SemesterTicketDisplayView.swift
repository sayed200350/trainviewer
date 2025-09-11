import SwiftUI
#if !os(watchOS) && !targetEnvironment(macCatalyst)
import UIKit
#endif

struct SemesterTicketDisplayView: View {
    let ticket: SemesterTicket
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var imageBrightness: Double = 0.0
    @State private var showFullScreenImage = false
    @State private var showActions = false
    @State private var showEditView = false

    private var university: University? {
        ticket.university
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.trailing)
                }
                .padding(.top, 8)

                // Main ticket card
                ticketCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                // Notification status
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.brandBlue)
                        Text("Renewal Notifications")
                            .font(.headline)
                        Spacer()
                        if SemesterTicketNotificationService.shared.notificationsEnabled {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                        }
                    }

                    if SemesterTicketNotificationService.shared.notificationsEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notifications scheduled for:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            let daysBefore = SemesterTicketNotificationService.shared.notificationDaysBefore
                            if daysBefore.isEmpty {
                                Text("No notifications scheduled")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(daysBefore.sorted(), id: \.self) { days in
                                    HStack {
                                        Image(systemName: "calendar.badge.clock")
                                            .foregroundColor(.brandBlue)
                                            .font(.caption)
                                        if let notificationDate = Calendar.current.date(byAdding: .day, value: -days, to: ticket.validityEnd) {
                                            Text("\(days) days before expiry (\(dateFormatter.string(from: notificationDate)))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        Text("Renewal notifications are disabled. Enable them in Settings to get timely reminders.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let daysUntilExpiry = ticket.daysUntilExpiry {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(daysUntilExpiry <= 30 ? .warningColor : .successColor)
                            Text("\(daysUntilExpiry) days until expiry")
                                .font(.subheadline)
                                .foregroundColor(daysUntilExpiry <= 30 ? .warningColor : .successColor)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // Additional information
                additionalInfo
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .background(Color.brandDark.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showFullScreenImage) {
            FullScreenImageView(ticket: ticket, brightness: $imageBrightness)
        }
        .sheet(isPresented: $showActions) {
            TicketActionsView(ticket: ticket)
        }
        .sheet(isPresented: $showEditView) {
            SemesterTicketEditView(ticket: ticket, onSave: { updatedTicket in
                // Handle ticket update here
                print("Ticket updated: \(updatedTicket.id)")
                showEditView = false
                // You might want to refresh the display or notify parent view
            })
        }
        .navigationBarHidden(true)
    }

    // MARK: - Ticket Card
    private var ticketCard: some View {
        ZStack {
            // Background with university branding
            RoundedRectangle(cornerRadius: 20)
                .fill(ticketBackground)
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)

            VStack(spacing: 0) {
                // Ticket photo section
                ticketPhotoSection
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                // Ticket information overlay
                ticketInfoOverlay
            }
        }
        .frame(height: 400)
    }

    private var ticketPhotoSection: some View {
        ZStack {
            if let image = ticket.ticketImage {
                image
                    .resizable()
                    .scaledToFill()
                    .brightness(imageBrightness)
                    .onTapGesture {
                        showFullScreenImage = true
                    }
            } else {
                // Placeholder for when no image is available
                ZStack {
                    Color.cardBackground
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.image")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No photo available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Brightness adjustment overlay
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    brightnessControl
                        .padding(.bottom, 16)
                        .padding(.trailing, 16)
                }
            }
        }
    }

    private var ticketInfoOverlay: some View {
        VStack {
            Spacer()

            ZStack {
                // Semi-transparent background for text readability
                Color.black.opacity(0.7)
                    .blur(radius: 10)

                VStack(spacing: 12) {
                    // University name and location
                    if let university = university {
                        VStack(spacing: 4) {
                            Text(university.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)

                            Text("\(university.city), \(university.state)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal)
                    }

                    // Validity information
                    VStack(spacing: 4) {
                        Text("Valid until")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        Text(dateFormatter.string(from: ticket.validityEnd))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        // Validity status badge
                        validityStatusBadge
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .frame(height: 140)
        }
    }

    private var validityStatusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(ticket.validityStatus.color)
                .frame(width: 8, height: 8)

            Text(ticket.validityStatus.displayText)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.2))
        .cornerRadius(12)
    }

    private var brightnessControl: some View {
        HStack(spacing: 8) {
            Image(systemName: "sun.min")
                .foregroundColor(.white.opacity(0.7))

            Slider(value: $imageBrightness, in: -0.5...0.5, step: 0.1)
                .frame(width: 80)
                .accentColor(.white)

            Image(systemName: "sun.max")
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.6))
        .cornerRadius(20)
    }

    // MARK: - Additional Information
    private var additionalInfo: some View {
        VStack(spacing: 16) {
            // Action buttons
            HStack(spacing: 12) {
                actionButton(
                    title: "Edit",
                    icon: "pencil",
                    color: .brandBlue
                ) {
                    // Navigate to edit view
                    showEditView = true
                }

                actionButton(
                    title: "Actions",
                    icon: "ellipsis.circle",
                    color: .secondary
                ) {
                    showActions = true
                }
            }

            // Detailed information card
            VStack(spacing: 16) {
                infoRow(label: "University", value: ticket.universityName)

                infoRow(label: "Valid from", value: dateFormatter.string(from: ticket.validityStart))

                infoRow(label: "Valid until", value: dateFormatter.string(from: ticket.validityEnd))

                if let daysUntilExpiry = ticket.daysUntilExpiry {
                    infoRow(label: "Days until expiry", value: "\(daysUntilExpiry) days")
                }

                infoRow(label: "Added on", value: dateFormatter.string(from: ticket.createdAt))
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Background
    private var ticketBackground: LinearGradient {
        // Create gradient with university brand color if available
        var colors = [Color.brandDark, Color.cardBackground, Color.brandDark]

        if let university = university,
           let brandColorHex = university.brandColor {
            // Try to create color from hex, fallback to default if invalid
            let brandColor = Color(hex: brandColorHex)
            colors = [Color.brandDark, brandColor.opacity(0.1), Color.brandDark]
        }

        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Actions
    private func shareTicket() {
        // Create a simple shareable text representation
        let shareText = """
        My Semester Ticket:
        \(ticket.universityName)
        Valid until: \(dateFormatter.string(from: ticket.validityEnd))
        """

        // Use ShareLink for iOS 16+ or create a custom sharing approach
        #if !os(watchOS) && !targetEnvironment(macCatalyst)
        shareUsingUIKitSafe(shareText)
        #else
        shareUsingSwiftUI(shareText)
        #endif
    }

    #if !os(watchOS) && !targetEnvironment(macCatalyst)
    private func shareUsingUIKitSafe(_ shareText: String) {
        // Try to use UIApplication.shared safely
        guard let sharedApplication = (UIApplication.self as AnyObject) as? UIApplication.Type,
              let app = sharedApplication.value(forKey: "shared") as? UIApplication else {
            // Fallback for contexts where UIApplication.shared is not available
            shareUsingSwiftUI(shareText)
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        // Use reflection to safely access connectedScenes
        guard let scenes = app.value(forKey: "connectedScenes") as? NSSet else {
            shareUsingSwiftUI(shareText)
            return
        }

        let windowScene = scenes.allObjects.first(where: { $0 is UIWindowScene }) as? UIWindowScene
        let window = windowScene?.windows.first(where: { $0.isKeyWindow }) ?? windowScene?.windows.first

        if let presentingVC = window?.rootViewController {
            // Configure popover for iPad if needed
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = presentingVC.view
                popover.sourceRect = CGRect(x: presentingVC.view.bounds.midX,
                                          y: presentingVC.view.bounds.midY,
                                          width: 1, height: 1)
            }

            presentingVC.present(activityVC, animated: true)
        } else {
            // Fallback to SwiftUI sharing
            shareUsingSwiftUI(shareText)
        }
    }
    #endif

    private func shareUsingSwiftUI(_ shareText: String) {
        // For app extensions or limited contexts, we can use ShareLink or a custom approach
        // Since ShareLink requires iOS 16+, we'll create a simple alert for now
        // In a production app, you might want to use ShareLink or another approach
        print("Sharing not available in this context: \(shareText)")
        // You could also show an alert or copy to clipboard here
    }
}

// MARK: - Full Screen Image View
struct FullScreenImageView: View {
    let ticket: SemesterTicket
    @Binding var brightness: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            if let image = ticket.ticketImage {
                image
                    .resizable()
                    .scaledToFit()
                    .brightness(brightness)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { scale in
                                // Handle zoom if needed
                            }
                    )
            }

            // Controls overlay
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()

                // Brightness control at bottom
                HStack(spacing: 16) {
                    Image(systemName: "sun.min")
                        .foregroundColor(.white)

                    Slider(value: $brightness, in: -0.5...0.5, step: 0.1)
                        .frame(width: 200)
                        .accentColor(.white)

                    Image(systemName: "sun.max")
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.6))
                .cornerRadius(20)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Ticket Actions View
struct TicketActionsView: View {
    let ticket: SemesterTicket
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @StateObject private var ticketService = ObservableSemesterTicketService.shared

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Manage Ticket")) {
                    Button(action: {
                        // Update validity dates - show quick update
                        print("Update validity: \(ticket.id)")
                        dismiss()
                    }) {
                        Label("Update Validity", systemImage: "calendar.badge.plus")
                            .foregroundColor(.primary)
                    }
                }


                Section {
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Label("Delete Ticket", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Ticket Actions")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .alert("Delete Ticket?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteTicket()
                }
            } message: {
                Text("Do you really want to delete this semester ticket? This action cannot be undone.")
            }
        }
    }

    private func shareTicketPhoto() {
        guard let imageData = ticket.photoData,
              let image = UIImage(data: imageData) else { return }

        // Use safe sharing method
        #if !os(watchOS) && !targetEnvironment(macCatalyst)
        sharePhotoUsingUIKitSafe(image)
        #else
        sharePhotoUsingSwiftUI()
        #endif
    }

    #if !os(watchOS) && !targetEnvironment(macCatalyst)
    private func sharePhotoUsingUIKitSafe(_ image: UIImage) {
        // Try to use UIApplication.shared safely
        guard let sharedApplication = (UIApplication.self as AnyObject) as? UIApplication.Type,
              let app = sharedApplication.value(forKey: "shared") as? UIApplication else {
            // Fallback for contexts where UIApplication.shared is not available
            sharePhotoUsingSwiftUI()
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        // Use reflection to safely access connectedScenes
        guard let scenes = app.value(forKey: "connectedScenes") as? NSSet else {
            sharePhotoUsingSwiftUI()
            return
        }

        let windowScene = scenes.allObjects.first(where: { $0 is UIWindowScene }) as? UIWindowScene
        let window = windowScene?.windows.first(where: { $0.isKeyWindow }) ?? windowScene?.windows.first

        if let presentingVC = window?.rootViewController {
            // Configure popover for iPad if needed
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = presentingVC.view
                popover.sourceRect = CGRect(x: presentingVC.view.bounds.midX,
                                          y: presentingVC.view.bounds.midY,
                                          width: 1, height: 1)
            }

            presentingVC.present(activityVC, animated: true)
        } else {
            // Fallback to SwiftUI sharing
            sharePhotoUsingSwiftUI()
        }
    }
    #endif

    private func sharePhotoUsingSwiftUI() {
        // For app extensions or limited contexts, sharing photos might not be available
        print("Photo sharing not available in this context")
        // You could show an alert or provide alternative sharing options here
    }

    private func deleteTicket() {
        let result = SemesterTicketService.shared.deleteTicket(withId: ticket.id)

        switch result {
        case .success:
            ticketService.removeTicket(withId: ticket.id)
            dismiss()
        case .failure(let error):
            print("Error deleting ticket: \(error)")
            // Could show error alert here
        }
    }

}

// MARK: - Preview
struct SemesterTicketDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTicket = SemesterTicket(
            photoData: nil,
            universityName: "Technische Universität München",
            universityId: "tum-muenchen",
            validityStart: Date(),
            validityEnd: Date().addingTimeInterval(86400 * 180) // 180 days
        )

        SemesterTicketDisplayView(ticket: sampleTicket)
            .preferredColorScheme(.dark)
    }
}
