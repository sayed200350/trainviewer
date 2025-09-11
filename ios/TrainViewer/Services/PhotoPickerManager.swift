import SwiftUI
import PhotosUI
import UIKit

// MARK: - Photo Picker Manager
class PhotoPickerManager: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isPresented: Bool = false
    @Published var imageData: Data?

    var pickerConfig: PHPickerConfiguration {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        return config
    }

    func presentPicker() {
        isPresented = true
    }

    func reset() {
        selectedImage = nil
        imageData = nil
    }

    // Process selected image for ticket storage
    func processSelectedImage() {
        guard let image = selectedImage else { return }

        // Use the service to process the image
        let processedData = SemesterTicketService.shared.processImageForStorage(image)
        imageData = processedData
    }
}

// MARK: - Photo Picker View
struct PhotoPickerView: UIViewControllerRepresentable {
    @ObservedObject var manager: PhotoPickerManager

    func makeUIViewController(context: Context) -> PHPickerViewController {
        let picker = PHPickerViewController(configuration: manager.pickerConfig)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(manager: manager)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let manager: PhotoPickerManager

        init(manager: PhotoPickerManager) {
            self.manager = manager
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            manager.isPresented = false

            guard let result = results.first else {
                return
            }

            // Load the selected image
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                if let error = error {
                    print("Error loading image: \(error)")
                    return
                }

                guard let image = object as? UIImage else {
                    print("Failed to cast object to UIImage")
                    return
                }

                DispatchQueue.main.async {
                    self?.manager.selectedImage = image
                    self?.manager.processSelectedImage()
                }
            }
        }
    }
}

// MARK: - Image Preview with Crop/Edit
struct ImagePreviewView: View {
    @ObservedObject var photoManager: PhotoPickerManager
    @Binding var showCropView: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    showCropView = false
                }

            VStack(spacing: 20) {
                if let image = photoManager.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 400)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                HStack(spacing: 20) {
                    Button(action: {
                        showCropView = false
                    }) {
                        Text("Abbrechen")
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.8))
                            .cornerRadius(8)
                    }

                    Button(action: {
                        // For now, just accept the image as-is
                        // In a production app, you might want to implement cropping
                        showCropView = false
                    }) {
                        Text("Übernehmen")
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.brandBlue)
                            .cornerRadius(8)
                    }
                }
                .padding(.bottom, 40)
            }
            .padding()
        }
    }
}

// MARK: - Enhanced Photo Picker with Preview
struct EnhancedPhotoPicker: View {
    @StateObject private var photoManager = PhotoPickerManager()
    @Binding var selectedImageData: Data?
    @State private var showPreview = false

    var body: some View {
        VStack(spacing: 16) {
            if let image = photoManager.selectedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                        .onTapGesture {
                            showPreview = true
                        }

                    Button(action: {
                        photoManager.reset()
                        selectedImageData = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .padding(4)
                    }
                }
                .padding(.horizontal)
            } else {
                Button(action: {
                    photoManager.presentPicker()
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 40))
                            .foregroundColor(.brandBlue)

                        Text("Foto auswählen")
                            .font(.headline)
                            .foregroundColor(.brandBlue)

                        Text("Wählen Sie ein Foto Ihres Semestertickets aus der Galerie")
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
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $photoManager.isPresented) {
            PhotoPickerView(manager: photoManager)
        }
        .sheet(isPresented: $showPreview) {
            ImagePreviewView(photoManager: photoManager, showCropView: $showPreview)
        }
        .onChange(of: photoManager.imageData) { oldValue, newValue in
            selectedImageData = newValue
        }
    }
}

// MARK: - Camera Capture (Optional Enhancement)
struct CameraCaptureView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(capturedImage: $capturedImage, dismiss: dismiss)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        @Binding var capturedImage: UIImage?
        let dismiss: DismissAction

        init(capturedImage: Binding<UIImage?>, dismiss: DismissAction) {
            _capturedImage = capturedImage
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                capturedImage = image
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

// MARK: - Combined Photo Source Picker
struct PhotoSourcePicker: View {
    @Binding var selectedImageData: Data?
    @State private var showSourceOptions = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @StateObject private var photoManager = PhotoPickerManager()
    @State private var cameraImage: UIImage?

    var body: some View {
        VStack(spacing: 16) {
            if let image = photoManager.selectedImage ?? cameraImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)

                    Button(action: {
                        photoManager.reset()
                        cameraImage = nil
                        selectedImageData = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .padding(4)
                    }
                }
                .padding(.horizontal)
            } else {
                Button(action: {
                    showSourceOptions = true
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.on.rectangle")
                            .font(.system(size: 40))
                            .foregroundColor(.brandBlue)

                        Text("Foto hinzufügen")
                            .font(.headline)
                            .foregroundColor(.brandBlue)

                        Text("Wählen Sie ein Foto Ihres Semestertickets")
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
                .padding(.horizontal)
            }
        }
        .confirmationDialog("Fotoquelle auswählen", isPresented: $showSourceOptions, titleVisibility: .visible) {
            Button("Kamera") {
                showCamera = true
            }
            Button("Foto-Galerie") {
                photoManager.presentPicker()
            }
            Button("Abbrechen", role: .cancel) {}
        }
        .sheet(isPresented: $showCamera) {
            CameraCaptureView(capturedImage: $cameraImage)
        }
        .sheet(isPresented: $photoManager.isPresented) {
            PhotoPickerView(manager: photoManager)
        }
        .onChange(of: photoManager.imageData) { oldValue, newValue in
            selectedImageData = newValue
        }
        .onChange(of: cameraImage) { oldValue, newValue in
            if let image = newValue {
                let processedData = SemesterTicketService.shared.processImageForStorage(image)
                selectedImageData = processedData
            }
        }
    }
}
