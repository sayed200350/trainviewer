import SwiftUI

struct SemesterTicketEditView: View {
    let ticket: SemesterTicket
    let onSave: (SemesterTicket) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var photoManager = PhotoPickerManager()
    @State private var selectedUniversity: University?
    @State private var validityStart: Date
    @State private var validityEnd: Date
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false

    // Initialize with current ticket data
    init(ticket: SemesterTicket, onSave: @escaping (SemesterTicket) -> Void) {
        self.ticket = ticket
        self.onSave = onSave
        _selectedUniversity = State(initialValue: ticket.university)
        _validityStart = State(initialValue: ticket.validityStart)
        _validityEnd = State(initialValue: ticket.validityEnd)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Photo")) {
                    VStack(spacing: 16) {
                        if let image = photoManager.selectedImage ?? ticket.ticketUIImage {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .cornerRadius(12)

                                Button(action: {
                                    photoManager.reset()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                        .padding(4)
                                }
                            }
                        } else {
                            Button(action: {
                                photoManager.presentPicker()
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 40))
                                        .foregroundColor(.brandBlue)

                                    Text("Change Photo")
                                        .font(.headline)
                                        .foregroundColor(.brandBlue)

                                    Text("Select new photo")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.brandBlue.opacity(0.3), lineWidth: 2)
                                        .background(Color.brandBlue.opacity(0.05))
                                )
                            }
                        }
                    }
                    .padding(.vertical)
                }

                Section(header: Text("University")) {
                    if let university = selectedUniversity {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(university.name)
                                .font(.headline)
                                .foregroundColor(.brandBlue)

                            Text("\(university.city), \(university.state)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Button("Change University") {
                                // Navigate to university selection
                                // For now, just show available universities
                            }
                            .foregroundColor(.brandBlue)
                        }
                    } else {
                        Text("No university selected")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Validity Period")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("From:")
                            .font(.headline)
                        DatePicker("", selection: $validityStart, displayedComponents: .date)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .tint(.brandBlue)
                            .frame(height: 120)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("To:")
                            .font(.headline)
                        DatePicker("", selection: $validityEnd, displayedComponents: .date)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .tint(.brandBlue)
                            .frame(height: 120)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Valid from \(dateFormatter.string(from: validityStart)) to \(dateFormatter.string(from: validityEnd))")
                            .font(.subheadline)
                    }
                }

                Section {
                    Button(action: saveChanges) {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Saving...")
                                Spacer()
                            }
                        } else {
                            Text("Save Changes")
                        }
                    }
                    .disabled(isLoading || !canSave)
                    .foregroundColor(canSave ? .brandBlue : .gray)
                }
            }
            .navigationTitle("Edit Ticket")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Done") { dismiss() }
            )
            .sheet(isPresented: $photoManager.isPresented) {
                PhotoPickerView(manager: photoManager)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var canSave: Bool {
        return validityStart < validityEnd
    }

    private func saveChanges() {
        guard canSave else {
            showError(message: "Please check the validity dates.")
            return
        }

        isLoading = true

        // Create updated ticket
        let updatedPhotoData = photoManager.imageData ?? ticket.photoData

        let updatedTicket = SemesterTicket(
            id: ticket.id,
            photoData: updatedPhotoData,
            universityName: selectedUniversity?.name ?? ticket.universityName,
            universityId: selectedUniversity?.id ?? ticket.universityId,
            validityStart: validityStart,
            validityEnd: validityEnd,
            createdAt: ticket.createdAt
        )

        // Validate the updated data
        let validationResult = SemesterTicketService.shared.validateTicketData(
            universityId: updatedTicket.universityId,
            validityStart: updatedTicket.validityStart,
            validityEnd: updatedTicket.validityEnd
        )

        switch validationResult {
        case .success:
            // Update the ticket in the service
            let updateResult = SemesterTicketService.shared.updateTicket(
                id: updatedTicket.id,
                photoData: updatedPhotoData,
                validityStart: updatedTicket.validityStart,
                validityEnd: updatedTicket.validityEnd
            )

            switch updateResult {
            case .success(let savedTicket):
                print("Ticket updated successfully: \(savedTicket.id)")
                onSave(savedTicket)
                isLoading = false
            case .failure(let error):
                isLoading = false
                showError(message: "Error saving: \(error.localizedDescription)")
            }

        case .failure(let error):
            isLoading = false
            showError(message: error.localizedDescription)
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Preview
struct SemesterTicketEditView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTicket = SemesterTicket(
            photoData: nil,
            universityName: "Technische Universität München",
            universityId: "tum-muenchen",
            validityStart: Date(),
            validityEnd: Date().addingTimeInterval(86400 * 180)
        )

        SemesterTicketEditView(ticket: sampleTicket) { _ in }
    }
}
