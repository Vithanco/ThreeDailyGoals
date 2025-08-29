import SwiftData
//
//  InnerTaskItemView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/08/2025.
//
import SwiftUI
import TagKit
import UniformTypeIdentifiers

struct InnerTaskItemView: View {
    @Bindable var item: TaskItem
    let allTags: [String]
    @State var buildTag: String = ""
    @State var showAttachmentImporter: Bool = false
    let selectedTagStyle: TagCapsuleStyle
    let missingTagStyle: TagCapsuleStyle
    @Environment(\.modelContext) private var modelContext
    let showAttachmentImport: Bool
    @Environment(\.colorScheme) var colorScheme

    private var attachmentButton: some View {
        Button {
            showAttachmentImporter = true
        } label: {
            Label("Add Attachment", systemImage: imgAttachment)
        }
        .accessibilityIdentifier("addAttachmentButton")
        .help("Add file attachment to this task")
    }

    var body: some View {
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
                } label: {
                    Text("Title:").bold().foregroundColor(Color.secondaryColor)
                }

                // Details field
                LabeledContent {
                    TextField("Details", text: $item.details, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .frame(minHeight: 30, idealHeight: 30)
                } label: {
                    Text("Details:").bold().foregroundColor(Color.secondaryColor)
                }

                // URL field
                LabeledContent {
                    HStack {
                        TextField("URL", text: $item.url, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .frame(idealHeight: 30)
                            .frame(minHeight: 30)
                        if let link = URL(string: item.url) {
                            Link("Open", destination: link)
                                .foregroundColor(item.color)
                        }
                    }
                } label: {
                    Text("URL:").bold().foregroundColor(Color.secondaryColor)
                }

                // Due date field
                LabeledContent {
                    DatePickerNullable(selected: $item.due, defaultDate: getDate(inDays: 7))
                } label: {
                    Text("Due Date:").bold().foregroundColor(Color.secondaryColor)
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
                    let _ = print("📎 Task '\(item.title)' has \(atts.count) attachments")
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
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Add new Label:")
                        TagTextField(text: $buildTag, placeholder: "Tag Me").onSubmit({
                            item.addTag(buildTag)
                        })
                    }
                    TagEditList(
                        tags: Binding(
                            get: { item.tags },
                            set: { item.tags = $0 }
                        ),
                        additionalTags: allTags,
                        container: .vstack
                    ) { text, isTag in
                        TagCapsule(text)
                            .tagCapsuleStyle(isTag ? selectedTagStyle : missingTagStyle)
                    }.frame(maxHeight: 70)
                }
            }
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
                    item.addComment(text: "Added attachment: \(attachment.filename)")
                } catch {
                    // TODO: surface an error toast if you have one
                    print("Add attachment failed:", error)
                }
            }
        }
        .opacity(showAttachmentImport ? 1 : 0)  // Hide fileImporter when not needed
    }

    private func deleteAttachment(_ attachment: Attachment) {
        let filename = attachment.filename

        // Remove the attachment from the task
        item.attachments?.removeAll { $0.id == attachment.id }

        // Delete the attachment from the model context
        modelContext.delete(attachment)

        // Add a comment about the deletion
        item.addComment(text: "Removed attachment: \(filename)")

        // Save the changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete attachment: \(error)")
        }
    }
}
