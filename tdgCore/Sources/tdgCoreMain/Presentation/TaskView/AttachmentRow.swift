import SwiftData
import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
    import UIKit
#endif

public struct AttachmentRow: View {
    let attachment: Attachment
    let onDelete: (() -> Void)?
    #if os(iOS)
        @State private var showingPreview = false
    #endif
    @State private var showingDeleteConfirmation = false

    public var body: some View {
        HStack(spacing: 12) {
            thumb.clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.filename).lineLimit(1)
                if let c = attachment.caption, !c.isEmpty { Text(c).font(.caption) }
                Text(byteCount).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if !attachment.isPurged {
                #if os(macOS)
                    // Try to create a temporary file for opening
                    let tempURL = createAttachmentTempFile(
                        data: attachment.blob ?? Data(),
                        filename: attachment.filename,
                        fileExtension: attachment.type?.preferredFilenameExtension,
                        uniqueIdentifier: String(describing: attachment.id)
                    )

                    if let url = tempURL {
                        ShareLink(item: url)
                        Button("Open") {
                            NSWorkspace.shared.open(url)
                        }
                    } else {
                        // Fallback: if we can't create a temp file, still show share button with data
                        ShareLink(item: attachment.blob ?? Data(), preview: SharePreview(attachment.filename))
                        Button("Open") {
                            // Try to create a simple temp file as fallback
                            if let data = attachment.blob, !data.isEmpty {
                                let fallbackURL = createSimpleTempFile(data: data, filename: attachment.filename)
                                if let url = fallbackURL {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        }
                        .disabled(attachment.blob?.isEmpty ?? true)
                        .onAppear {
                            // Debug logging moved to onAppear
                            print("⚠️ Failed to create temp file for attachment: \(attachment.filename)")
                            print("   - Blob size: \(attachment.blob?.count ?? 0)")
                            print("   - Type: \(attachment.type?.identifier ?? "nil")")
                            print("   - Preferred extension: \(attachment.type?.preferredFilenameExtension ?? "nil")")
                        }
                    }
                #else
                    ShareLink(item: attachment.blob ?? Data(), preview: SharePreview(attachment.filename))
                    Button("Open") {
                        showingPreview = true
                    }
                #endif
                if onDelete != nil {
                    Button("Delete") {
                        showingDeleteConfirmation = true
                    }
                    .foregroundStyle(.red)
                }
            } else if attachment.isPurged {
                Text("Purged").font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 6)
        #if os(iOS)
            .sheet(isPresented: $showingPreview) {
                AttachmentPreviewSheet(attachment: attachment)
            }
        #endif
        .confirmationDialog(
            "Delete Attachment",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete '\(attachment.filename)'? This action cannot be undone.")
        }

    }

    @ViewBuilder
    private var thumb: some View {
        if let data = attachment.thumbnail, let img = Image(data: data) {
            img.resizable().scaledToFill().frame(width: 44, height: 44)
        } else if let t = attachment.type, t.conforms(to: .image),
            let data = attachment.blob, let img = Image(data: data)
        {
            img.resizable().scaledToFill().frame(width: 44, height: 44)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(.quaternary)
                Image(systemName: symbolName()).imageScale(.large)
            }
            .frame(width: 44, height: 44)
        }
    }

    private func symbolName() -> String {
        guard let t = attachment.type else { return imgDoc }
        if t.conforms(to: .image) { return imgPhoto }
        if t == .pdf { return imgDocRichtext }
        if t.conforms(to: .audio) { return imgWaveform }
        if t.conforms(to: .video) { return imgFilm }
        return imgDoc
    }

    private var byteCount: String {
        ByteCountFormatter.string(fromByteCount: Int64(attachment.byteSize), countStyle: .file)
    }
}

#if os(iOS)
    struct AttachmentPreviewSheet: View {
        let attachment: Attachment
        @Environment(\.dismiss) private var dismiss
        @State private var showingSaveSuccess = false
        @State private var showingSaveError = false
        @State private var saveErrorMessage = ""

        public var body: some View {
            NavigationStack {
                VStack {
                    if let data = attachment.blob {
                        if attachment.type?.conforms(to: .image) == true,
                            let uiImage = UIImage(data: data)
                        {
                            // Show image preview
                            ScrollView([.horizontal, .vertical]) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                            }
                            .clipped()
                        } else if attachment.type?.conforms(to: .text) == true,
                            let text = String(data: data, encoding: .utf8)
                        {
                            // Show text preview
                            ScrollView {
                                Text(text)
                                    .font(.system(.body, design: .monospaced))
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            // Show file info for other types
                            VStack(spacing: 20) {
                                Image(systemName: imgDocFill)
                                    .font(.system(size: 64))
                                    .foregroundStyle(.secondary)

                                VStack(spacing: 8) {
                                    Text(attachment.filename)
                                        .font(.headline)
                                    Text(
                                        ByteCountFormatter.string(
                                            fromByteCount: Int64(attachment.byteSize), countStyle: .file)
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                    if let type = attachment.type {
                                        Text(type.localizedDescription ?? type.identifier)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Text("This file type cannot be previewed in the app.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)

                                Button("Save to Files") {
                                    saveFileToDocuments(data: data, filename: attachment.filename)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                        }
                    } else {
                        Text("No data available")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .navigationTitle(attachment.filename)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .alert("File Saved", isPresented: $showingSaveSuccess) {
                    Button("OK") {}
                } message: {
                    Text("The file has been saved to your Documents folder.")
                }
                .alert("Save Failed", isPresented: $showingSaveError) {
                    Button("OK") {}
                } message: {
                    Text(saveErrorMessage)
                }
            }
        }

        private func saveFileToDocuments(data: Data, filename: String) {
            do {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = documentsPath.appendingPathComponent(filename)

                // If file already exists, add a number suffix
                var finalURL = fileURL
                var counter = 1
                while FileManager.default.fileExists(atPath: finalURL.path) {
                    let nameWithoutExtension = fileURL.deletingPathExtension().lastPathComponent
                    let fileExtension = fileURL.pathExtension
                    let newName = "\(nameWithoutExtension) (\(counter)).\(fileExtension)"
                    finalURL = fileURL.deletingLastPathComponent().appendingPathComponent(newName)
                    counter += 1
                }

                try data.write(to: finalURL)
                showingSaveSuccess = true
            } catch {
                saveErrorMessage = "Failed to save file: \(error.localizedDescription)"
                showingSaveError = true
            }
        }
    }
#endif
