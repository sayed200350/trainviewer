import SwiftUI
import PhotosUI

struct SemesterTicketSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var ticketService = ObservableSemesterTicketService.shared
    @StateObject private var photoManager = PhotoPickerManager()

    // Form state
    @State private var selectedUniversity: University?
    @State private var universitySearchText = ""
    @State private var validityStart = Date()
    @State private var validityEnd = Date()
    @State private var currentStep = 0
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false

    // Manual university entry
    @State private var showManualEntry = false
    @State private var manualUniversityName = ""
    @State private var manualUniversityCity = ""
    @State private var manualUniversityState = ""

    // Filtered universities for search
    private var filteredUniversities: [University] {
        if universitySearchText.isEmpty {
            return University.germanUniversities
        }
        return University.searchUniversities(query: universitySearchText)
    }

    // Create manual university
    private func createManualUniversity() -> University? {
        guard !manualUniversityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !manualUniversityCity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError(message: "Please fill in university name and city")
            return nil
        }

        let state = manualUniversityState.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Unknown"
            : manualUniversityState

        // Create a unique ID for the manual university
        let id = "manual_\(UUID().uuidString.prefix(8))"

        return University(
            id: id,
            name: manualUniversityName.trimmingCharacters(in: .whitespacesAndNewlines),
            city: manualUniversityCity.trimmingCharacters(in: .whitespacesAndNewlines),
            state: state,
            latitude: nil,
            longitude: nil
        )
    }

    // Reset manual entry form
    private func resetManualEntry() {
        manualUniversityName = ""
        manualUniversityCity = ""
        manualUniversityState = ""
        showManualEntry = false
    }

    private let totalSteps = 3
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    var body: some View {
        NavigationView {
            VStack {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Step indicator
                HStack {
                    ForEach(0..<totalSteps, id: \.self) { step in
                        Circle()
                            .fill(step <= currentStep ? Color.brandBlue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.vertical, 8)

                // Step content
                TabView(selection: $currentStep) {
                    // Step 1: Photo Upload
                    photoStepView.tag(0)

                    // Step 2: University Selection
                    universityStepView.tag(1)

                    // Step 3: Validity Period
                    validityStepView.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)

                // Navigation buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button(action: previousStep) {
                            Text("Back")
                                .foregroundColor(.brandBlue)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.brandBlue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }

                    Spacer()

                    if currentStep < totalSteps - 1 {
                        Button(action: nextStep) {
                            Text("Next")
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(canProceedToNextStep ? Color.brandBlue : Color.gray.opacity(0.5))
                                .cornerRadius(8)
                        }
                        .disabled(!canProceedToNextStep)
                    } else {
                        Button(action: saveTicket) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(width: 20, height: 20)
                            } else {
                                Text("Save")
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(canSaveTicket ? Color.brandBlue : Color.gray.opacity(0.5))
                        .cornerRadius(8)
                        .disabled(!canSaveTicket || isLoading)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Add Semester Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Step Views

    private var photoStepView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 60))
                    .foregroundColor(.brandBlue)

                Text("Photo of Semester Ticket")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Take a photo of your semester ticket or select an image from your gallery.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 16) {
                if let image = photoManager.selectedImage {
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

                            Text("Select Photo")
                                .font(.headline)
                                .foregroundColor(.brandBlue)

                            Text("Select a photo of your semester ticket")
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
            .sheet(isPresented: $photoManager.isPresented) {
                PhotoPickerView(manager: photoManager)
            }
            .sheet(isPresented: $showManualEntry) {
                manualUniversityEntryView
            }
                .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 40)
    }

    private var universityStepView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "building.columns")
                    .font(.system(size: 60))
                    .foregroundColor(.brandBlue)

                Text("Select University")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Search for your university from the list of German universities.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search university...", text: $universitySearchText)
                        .autocorrectionDisabled()
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(filteredUniversities.prefix(20), id: \.self) { university in
                            UniversityRow(university: university, isSelected: selectedUniversity?.id == university.id)
                                .onTapGesture {
                                    selectedUniversity = university
                                }
                        }

                        // Manual entry button
                        Button(action: {
                            showManualEntry = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.brandBlue)
                                Text("Add University Manually")
                                    .foregroundColor(.brandBlue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brandBlue.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.brandBlue.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)
                }
            }

            if let selected = selectedUniversity {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Selected University:")
                            .font(.headline)
                        if selected.id.hasPrefix("manual_") {
                            Image(systemName: "person.fill")
                                .foregroundColor(.brandBlue)
                                .font(.caption)
                        }
                    }
                    Text(selected.name)
                        .font(.subheadline)
                        .foregroundColor(.brandBlue)
                    HStack {
                        Text("\(selected.city), \(selected.state)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if selected.id.hasPrefix("manual_") {
                            Text("(Added manually)")
                                .font(.caption2)
                                .foregroundColor(.brandBlue.opacity(0.7))
                                .italic()
                        }
                    }
                }
                .padding()
                .background(Color.brandBlue.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top, 40)
    }

    private var validityStepView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "calendar")
                    .font(.system(size: 60))
                    .foregroundColor(.brandBlue)

                Text("Validity Period")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Select the period during which your semester ticket is valid.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 24) {
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
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("Summary:")
                    .font(.headline)
                Text("Valid from \(dateFormatter.string(from: validityStart)) to \(dateFormatter.string(from: validityEnd))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 40)
    }

    // Manual university entry view
    private var manualUniversityEntryView: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.brandBlue)

                    Text("Add University")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Enter the details of your university manually.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("University Name *")
                            .font(.headline)
                        TextField("e.g., Technical University of Munich", text: $manualUniversityName)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                            .autocorrectionDisabled()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("City *")
                            .font(.headline)
                        TextField("e.g., Munich", text: $manualUniversityCity)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                            .autocorrectionDisabled()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("State/Region")
                            .font(.headline)
                        TextField("e.g., Bavaria", text: $manualUniversityState)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                            .autocorrectionDisabled()
                    }
                }
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 16) {
                    Button(action: {
                        if let university = createManualUniversity() {
                            selectedUniversity = university
                            resetManualEntry()
                        }
                    }) {
                        Text("Add University")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canAddManualUniversity ? Color.brandBlue : Color.gray.opacity(0.5))
                            .cornerRadius(12)
                    }
                    .disabled(!canAddManualUniversity)

                    Button(action: {
                        resetManualEntry()
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.brandBlue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brandBlue.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        resetManualEntry()
                    }
                }
            }
        }
    }

    // MARK: - Helper Views

    struct UniversityRow: View {
        let university: University
        let isSelected: Bool

        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(university.name)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)
                        if university.id.hasPrefix("manual_") {
                            Image(systemName: "person.fill")
                                .foregroundColor(.brandBlue)
                                .font(.caption2)
                        }
                    }
                    HStack {
                        Text("\(university.city), \(university.state)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if university.id.hasPrefix("manual_") {
                            Text("(Manual)")
                                .font(.caption2)
                                .foregroundColor(.brandBlue.opacity(0.6))
                        }
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.brandBlue)
                }
            }
            .padding()
            .background(isSelected ? Color.brandBlue.opacity(0.1) : Color.secondary.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.brandBlue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
    }

    // MARK: - Navigation Logic

    private var canProceedToNextStep: Bool {
        switch currentStep {
        case 0:
            return photoManager.selectedImage != nil
        case 1:
            return selectedUniversity != nil
        case 2:
            return validityStart < validityEnd
        default:
            return false
        }
    }

    private var canSaveTicket: Bool {
        return photoManager.selectedImage != nil &&
               selectedUniversity != nil &&
               validityStart < validityEnd
    }

    private var canAddManualUniversity: Bool {
        return !manualUniversityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !manualUniversityCity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func nextStep() {
        if currentStep < totalSteps - 1 && canProceedToNextStep {
            withAnimation {
                currentStep += 1
            }
        }
    }

    private func previousStep() {
        if currentStep > 0 {
            withAnimation {
                currentStep -= 1
            }
        }
    }

    private func saveTicket() {
        print("DEBUG: Save button pressed")
        print("DEBUG: Has photo: \(photoManager.selectedImage != nil)")
        print("DEBUG: Has processed data: \(photoManager.imageData != nil)")
        print("DEBUG: Selected university: \(selectedUniversity?.name ?? "none")")
        print("DEBUG: Validity dates: \(validityStart) to \(validityEnd)")

        guard canSaveTicket,
              let university = selectedUniversity,
              let photoData = photoManager.imageData else {
            let missingItems = [
                photoManager.selectedImage == nil ? "Photo" : nil,
                selectedUniversity == nil ? "University" : nil,
                validityStart >= validityEnd ? "Valid dates" : nil
            ].compactMap { $0 }

            showError(message: "Missing information: \(missingItems.joined(separator: ", "))")
            return
        }

        print("DEBUG: All requirements met, saving...")
        isLoading = true

        // Create the ticket
        let createResult = SemesterTicketService.shared.createTicket(
            universityId: university.id,
            universityName: university.name,
            photoData: photoData,
            validityStart: validityStart,
            validityEnd: validityEnd
        )

        switch createResult {
        case .success(let ticket):
            print("DEBUG: Ticket saved successfully")
            ticketService.addTicket(ticket)
            isLoading = false
            dismiss()
            case .failure(let error):
                print("DEBUG: Save failed: \(error)")
                isLoading = false
                showError(message: "Error saving: \(error.localizedDescription)")
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Preview
struct SemesterTicketSetupView_Previews: PreviewProvider {
    static var previews: some View {
        SemesterTicketSetupView()
    }
}
