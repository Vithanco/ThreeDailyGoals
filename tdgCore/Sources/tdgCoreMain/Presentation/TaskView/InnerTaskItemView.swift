import SwiftData
//
//  InnerTaskItemView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/08/2025.
//
import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

extension Array {
    public func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

public struct InnerTaskItemView: View {
    @Bindable var item: TaskItem
    let allTags: [String]
    @State var buildTag: String
    @State var showAttachmentImporter: Bool
    @Environment(\.modelContext) private var modelContext
    @Environment(TimeProviderWrapper.self) private var timeProviderWrapper
    let showAttachmentImport: Bool
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isTitleFocused: Bool
    @State private var isEnhancing = false
    @State private var enhancer: WebPageEnhancer?

    // Photo picker state
    @State private var showPhotosPicker = false
    @State private var selectedPhotosItems: [PhotosPickerItem] = []
    #if os(iOS)
    @State private var showCamera = false
    #endif

    public init(
        item: TaskItem, allTags: [String], buildTag: String = "", showAttachmentImporter: Bool = false,
        showAttachmentImport: Bool
    ) {
        self.item = item
        self.allTags = allTags
        self.buildTag = buildTag
        self.showAttachmentImporter = showAttachmentImporter
        self.showAttachmentImport = showAttachmentImport
        _enhancer = State(initialValue: WebPageEnhancer())
    }

    private var attachmentButton: some View {
        #if os(iOS)
        PhotoAttachmentMenu(
            showPhotosPicker: $showPhotosPicker,
            showCamera: $showCamera,
            showFileImporter: $showAttachmentImporter
        )
        #else
        PhotoAttachmentMenu(
            showPhotosPicker: $showPhotosPicker,
            showFileImporter: $showAttachmentImporter
        )
        #endif
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header section
            HStack {
                StateView(state: item.state)
                Text("Task").font(.title).foregroundStyle(item.color)
                Spacer()
            }
            .padding(.bottom, 8)

            // Main content section with proper spacing
            VStack(alignment: .leading, spacing: 12) {
                // Title field
                LabeledContent {
                    TextField("titleField", text: $item.title)
                        .accessibilityIdentifier("titleField")
                        .bold()
                        .frame(idealHeight: 13)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTitleFocused)
                } label: {
                    Text("Title:").bold().foregroundStyle(Color.secondary)
                }

                // Details field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Details:").bold().foregroundStyle(Color.secondary)
                    TextEditor(text: $item.details)
                        .frame(minHeight: 90, maxHeight: 450)  // 3x to 15x height (30 * 3 = 90, 30 * 15 = 450)
                        .padding(8)
                        .background(Color(.secondarySystemFill))
                        .cornerRadius(8)
                        .allowsHitTesting(true)
                }

                // URL field
                LabeledContent {
                    HStack {
                        TextField("URL", text: $item.url, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .frame(idealHeight: 30)
                            .frame(minHeight: 30)

                        if let link = URL(string: item.url), !item.url.isEmpty {
                            // Enhance button
                            Button(action: {
                                Task {
                                    await enhanceURL(link)
                                }
                            }) {
                                if isEnhancing {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: imgSparkles)
                                        .imageScale(.medium)
                                        .foregroundStyle(.yellow)
                                }
                            }
                            .help("Extract title and description from webpage")
                            .disabled(isEnhancing)

                            Link("Open", destination: link)
                                .foregroundStyle(item.color)
                        }
                    }
                } label: {
                    Text("URL:").bold().foregroundStyle(Color.secondary)
                }

                // Due date field
                LabeledContent {
                    DatePickerNullable(
                        selected: $item.due, defaultDate: timeProviderWrapper.timeProvider.getDate(inDays: 7))
                } label: {
                    Text("Due Date:").bold().foregroundStyle(Color.secondary)
                }
            }

            // Attachments section
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Attachments").font(.headline)
                        Spacer()
                        if showAttachmentImport {
                            attachmentButton
                        }
                    }

                    let atts = item.attachments ?? []
                    if atts.isEmpty {
                        Text("No attachments yet").foregroundStyle(.secondary)
                            .accessibilityIdentifier("noAttachmentsMessage")
                    } else {
                        ForEach(atts) { att in
                            AttachmentRow(
                                attachment: att,
                                onDelete: showAttachmentImport
                                    ? {
                                        deleteAttachment(att)
                                    } : nil
                            )
                        }
                    }
                }
            }
            .accessibilityIdentifier("attachmentsGroupBox")

            // Labels section
            GroupBox {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("Add new Label:")
                        TextField("Tag Me", text: $buildTag)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit({
                                item.addTag(buildTag)
                            })
                    }
                    ScrollView {
                        FlowLayout(spacing: 8, runSpacing: 8) {
                            ForEach(allTags.sorted(), id: \.self) { text in
                                let isTag = item.tags.contains(text)
                                TagView(
                                    text: text,
                                    isSelected: isTag,
                                    accentColor: item.color,
                                    onTap: {
                                        if isTag {
                                            item.tags.removeAll { $0 == text }
                                        } else {
                                            item.tags.append(text)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                }
            }
        }
        .onAppear {
            isTitleFocused = true
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.neutral800 : Color.neutral50)
                .shadow(
                    color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.08),
                    radius: colorScheme == .dark ? 8 : 6,
                    x: 0,
                    y: colorScheme == .dark ? 4 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    colorScheme == .dark ? Color.neutral700 : Color.neutral200,
                    lineWidth: 1
                )
        )

        .fileImporter(
            isPresented: $showAttachmentImporter,
            allowedContentTypes: [.item],  // anything
            allowsMultipleSelection: true
        ) { result in
            guard case .success(let urls) = result else { return }

            for url in urls {
                // Start accessing the security-scoped resource
                let accessing = url.startAccessingSecurityScopedResource()
                defer {
                    if accessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                do {
                    let type =
                        try url.resourceValues(forKeys: [.contentTypeKey]).contentType
                        ?? UTType(filenameExtension: url.pathExtension) ?? .data
                    let attachment = try addAttachment(
                        fileURL: url,
                        type: type,
                        to: item,
                        sortIndex: (item.attachments ?? []).count,
                        in: modelContext
                    )
                    // Add a comment about the attachment
                    item.addComment(text: "Added attachment: \(attachment.filename)", icon: imgAttachment)
                } catch {
                    // TODO: surface an error toast if you have one
                    print("Add attachment failed:", error)
                }
            }
        }
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $selectedPhotosItems,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotosItems) { oldValue, newValue in
            Task {
                await handlePhotosSelection(newValue)
                selectedPhotosItems = []  // Reset after processing
            }
        }
        #if os(iOS)
        .sheet(isPresented: $showCamera) {
            CameraPickerView { image in
                handleCapturedImage(image)
            }
            .ignoresSafeArea()
        }
        #endif
    }

    private func deleteAttachment(_ attachment: Attachment) {
        let filename = attachment.filename

        // Remove the attachment from the task
        item.attachments?.removeAll { $0.id == attachment.id }

        // Purge attachment data to free storage before deleting
        try? attachment.purge(in: modelContext)

        // Delete the attachment from the model context
        modelContext.delete(attachment)

        // Add a comment about the deletion
        item.addComment(text: "Removed attachment: \(filename)", icon: imgAttachment)

        // Save the changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete attachment: \(error)")
        }
    }

    private func enhanceURL(_ url: URL) async {
        guard let enhancer = enhancer else { return }

        isEnhancing = true

        // Use AI if available, otherwise just basic metadata
        let useAI = enhancer.hasAI
        let (formattedTitle, description) = await enhancer.enhance(
            url: url,
            currentTitle: item.title,
            useAI: useAI
        )

        // Update title if empty or default
        if item.isTitleEmpty || item.title.lowercased() == "read" {
            item.title = formattedTitle
        }

        // Add description to details
        if let desc = description {
            if item.isDetailsEmpty {
                item.details = desc
            } else {
                // Append below existing text
                item.details += "\n\n" + desc
            }
        }

        isEnhancing = false
    }

    // MARK: - Photo Handling

    private func handlePhotosSelection(_ items: [PhotosPickerItem]) async {
        for (index, item) in items.enumerated() {
            do {
                guard let data = try await item.loadImageData() else { continue }

                // Create a temporary file to save the image
                let tempDir = FileManager.default.temporaryDirectory
                let filename = "photo_\(Date().timeIntervalSince1970)_\(index).jpg"
                let tempURL = tempDir.appendingPathComponent(filename)

                try data.write(to: tempURL)

                // Add as attachment
                let attachment = try addAttachment(
                    fileURL: tempURL,
                    type: .jpeg,
                    to: self.item,
                    sortIndex: (self.item.attachments ?? []).count,
                    in: modelContext
                )

                // Add a comment about the attachment
                self.item.addComment(text: "Added photo: \(attachment.filename)", icon: imgAttachment)

                // Clean up temp file
                try? FileManager.default.removeItem(at: tempURL)
            } catch {
                print("Failed to add photo: \(error)")
            }
        }
    }

    #if os(iOS)
    private func handleCapturedImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert captured image to JPEG")
            return
        }

        // Create a temporary file to save the image
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "camera_\(Date().timeIntervalSince1970).jpg"
        let tempURL = tempDir.appendingPathComponent(filename)

        do {
            try data.write(to: tempURL)

            // Add as attachment
            let attachment = try addAttachment(
                fileURL: tempURL,
                type: .jpeg,
                to: item,
                sortIndex: (item.attachments ?? []).count,
                in: modelContext
            )

            // Add a comment about the attachment
            item.addComment(text: "Added photo from camera: \(attachment.filename)", icon: imgAttachment)

            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)
        } catch {
            print("Failed to add captured photo: \(error)")
        }
    }
    #endif
}
