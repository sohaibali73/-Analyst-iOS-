import SwiftUI

#if os(iOS) || os(visionOS)
import PhotosUI
import UniformTypeIdentifiers

// MARK: - File Attachment Picker (iOS / visionOS only)

struct FileAttachmentPicker: View {
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var attachments: [AttachmentItem] = []
    @State private var showDocumentPicker = false
    @State private var showCamera = false
    @State private var uploadProgress: Double = 0
    @State private var isUploading = false

    let onAttach: ([AttachmentItem]) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("ATTACH FILES")
                        .font(.custom("Rajdhani-Bold", size: 16))
                        .foregroundColor(.white)
                        .tracking(3)
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 16)

                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 0.5)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Source buttons
                        sourceButtonsSection
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        // Selected files
                        if !attachments.isEmpty {
                            selectedFilesSection
                                .padding(.horizontal, 20)
                        }

                        // Upload progress
                        if isUploading {
                            uploadProgressSection
                                .padding(.horizontal, 20)
                        }

                        Spacer().frame(height: 20)
                    }
                }

                // Send button
                if !attachments.isEmpty {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 0.5)

                        Button {
                            onAttach(attachments)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 14))
                                Text("ATTACH \(attachments.count) FILE\(attachments.count > 1 ? "S" : "")")
                                    .font(.custom("Rajdhani-Bold", size: 16))
                                    .tracking(2)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(Color.potomacYellow)
                            .cornerRadius(12)
                        }
                        .disabled(isUploading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .background(Color(hex: "0D0D0D"))
                }
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView { urls in
                for url in urls {
                    addDocumentAttachment(url: url)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView { image in
                if let image = image {
                    addImageAttachment(image: image, name: "Camera Photo")
                }
            }
        }
        .onChange(of: selectedPhotos) { _, newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        let image = UIImage(data: data)
                        let name = item.itemIdentifier ?? "Photo"
                        await MainActor.run {
                            let attachment = AttachmentItem(
                                id: UUID().uuidString,
                                name: name,
                                type: .photo,
                                data: data,
                                thumbnail: image,
                                fileSize: data.count
                            )
                            attachments.append(attachment)
                        }
                    }
                }
                await MainActor.run { selectedPhotos = [] }
            }
        }
    }

    // MARK: - Source Buttons

    @ViewBuilder
    private var sourceButtonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SELECT SOURCE")
                .font(.custom("Quicksand-SemiBold", size: 10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)

            HStack(spacing: 12) {
                // Photos
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    sourceButton(
                        icon: "photo.on.rectangle",
                        title: "Photos",
                        color: Color.chartPurple
                    )
                }

                // Documents
                Button {
                    showDocumentPicker = true
                } label: {
                    sourceButton(
                        icon: "doc.fill",
                        title: "Documents",
                        color: Color.chartBlue
                    )
                }

                // Camera
                Button {
                    showCamera = true
                } label: {
                    sourceButton(
                        icon: "camera.fill",
                        title: "Camera",
                        color: Color.potomacTurquoise
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func sourceButton(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.12))
                    .frame(height: 72)

                Image(systemName: icon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(color)
            }
            Text(title)
                .font(.custom("Quicksand-SemiBold", size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Selected Files

    @ViewBuilder
    private var selectedFilesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SELECTED FILES")
                    .font(.custom("Quicksand-SemiBold", size: 10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)
                Spacer()
                Text("\(attachments.count) file\(attachments.count > 1 ? "s" : "")")
                    .font(.custom("Quicksand-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.3))
            }

            ForEach(attachments) { attachment in
                AttachmentRow(attachment: attachment) {
                    attachments.removeAll { $0.id == attachment.id }
                }
            }
        }
    }

    // MARK: - Upload Progress

    @ViewBuilder
    private var uploadProgressSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Uploading...")
                    .font(.custom("Quicksand-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("\(Int(uploadProgress * 100))%")
                    .font(.custom("Quicksand-SemiBold", size: 13))
                    .foregroundColor(Color.potomacYellow)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.potomacYellow)
                        .frame(width: geo.size.width * uploadProgress, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: uploadProgress)
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func addDocumentAttachment(url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: url)
            let attachment = AttachmentItem(
                id: UUID().uuidString,
                name: url.lastPathComponent,
                type: .document,
                data: data,
                thumbnail: nil,
                fileSize: data.count
            )
            attachments.append(attachment)
        } catch {
            print("❌ Failed to read document: \(error)")
        }
    }

    private func addImageAttachment(image: UIImage, name: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let attachment = AttachmentItem(
            id: UUID().uuidString,
            name: name + ".jpg",
            type: .photo,
            data: data,
            thumbnail: image,
            fileSize: data.count
        )
        attachments.append(attachment)
    }
}

// MARK: - Attachment Item

struct AttachmentItem: Identifiable {
    let id: String
    let name: String
    let type: AttachmentType
    let data: Data
    let thumbnail: UIImage?
    let fileSize: Int

    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }

    var iconName: String {
        switch type {
        case .photo: return "photo"
        case .document: return "doc.fill"
        case .camera: return "camera.fill"
        }
    }

    var iconColor: Color {
        switch type {
        case .photo: return .chartPurple
        case .document: return .chartBlue
        case .camera: return .potomacTurquoise
        }
    }

    enum AttachmentType {
        case photo, document, camera
    }
}

// MARK: - Attachment Row

struct AttachmentRow: View {
    let attachment: AttachmentItem
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            ZStack {
                if let thumbnail = attachment.thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(attachment.iconColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: attachment.iconName)
                                .font(.system(size: 18))
                                .foregroundColor(attachment.iconColor)
                        )
                }
            }

            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.name)
                    .font(.custom("Quicksand-SemiBold", size: 13))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(attachment.fileSizeFormatted)
                    .font(.custom("Quicksand-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.3))
            }

            Spacer()

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.25))
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Document Picker

struct DocumentPickerView: UIViewControllerRepresentable {
    let onPick: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [
            .pdf, .plainText, .commaSeparatedText,
            .spreadsheet, .presentation,
            .png, .jpeg, .heic,
            .json, .xml
        ]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([URL]) -> Void

        init(onPick: @escaping ([URL]) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls)
        }
    }
}

// MARK: - Camera Picker

struct CameraPickerView: UIViewControllerRepresentable {
    let onCapture: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage?) -> Void

        init(onCapture: @escaping (UIImage?) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            onCapture(image)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCapture(nil)
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Preview

#Preview {
    FileAttachmentPicker(
        onAttach: { items in print("Attached \(items.count) files") },
        onDismiss: { print("Dismiss") }
    )
    .preferredColorScheme(.dark)
}

#else

// MARK: - Stubs for macOS / watchOS / non-iOS platforms

struct AttachmentItem: Identifiable {
    let id: String
    let name: String
    let data: Data
    let fileSize: Int

    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }

    var iconName: String { "doc.fill" }
    var iconColor: Color { .chartBlue }
}

#endif
