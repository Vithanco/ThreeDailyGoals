//
//  PhotoPickerView.swift
//  tdgCoreMain
//
//  Photo and camera picker component for attaching images to tasks
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

#if os(iOS)
import UIKit

/// Wrapper for UIImagePickerController to capture photos from camera
public struct CameraPickerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onImageCaptured: (UIImage) -> Void

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView

        init(parent: CameraPickerView) {
            self.parent = parent
        }

        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.dismiss()
        }

        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

/// Photo attachment options menu for iOS
public struct PhotoAttachmentMenu: View {
    @Binding var showPhotosPicker: Bool
    @Binding var showCamera: Bool
    @Binding var showFileImporter: Bool

    public init(showPhotosPicker: Binding<Bool>, showCamera: Binding<Bool>, showFileImporter: Binding<Bool>) {
        self._showPhotosPicker = showPhotosPicker
        self._showCamera = showCamera
        self._showFileImporter = showFileImporter
    }

    public var body: some View {
        Menu {
            Button {
                showCamera = true
            } label: {
                Label("Take Photo", systemImage: imgCamera)
            }

            Button {
                showPhotosPicker = true
            } label: {
                Label("Choose from Library", systemImage: imgPhotoOnRectangle)
            }

            Button {
                showFileImporter = true
            } label: {
                Label("Attach File", systemImage: imgAttachment)
            }
        } label: {
            Label("Add Attachment", systemImage: imgAddAttachment)
        }
        .accessibilityIdentifier("addAttachmentMenu")
        .help("Add photo or file attachment to this task")
    }
}

#else
// macOS doesn't support camera, so provide simpler menu
public struct PhotoAttachmentMenu: View {
    @Binding var showPhotosPicker: Bool
    @Binding var showFileImporter: Bool

    public init(showPhotosPicker: Binding<Bool>, showFileImporter: Binding<Bool>) {
        self._showPhotosPicker = showPhotosPicker
        self._showFileImporter = showFileImporter
    }

    public var body: some View {
        Menu {
            Button {
                showPhotosPicker = true
            } label: {
                Label("Choose Photo", systemImage: imgPhotoOnRectangle)
            }

            Button {
                showFileImporter = true
            } label: {
                Label("Attach File", systemImage: imgAttachment)
            }
        } label: {
            Label("Add Attachment", systemImage: imgAddAttachment)
        }
        .accessibilityIdentifier("addAttachmentMenu")
        .help("Add photo or file attachment to this task")
    }
}
#endif

/// Helper to convert PhotosPickerItem to Data
extension PhotosPickerItem {
    public func loadImageData() async throws -> Data? {
        return try await self.loadTransferable(type: Data.self)
    }
}
