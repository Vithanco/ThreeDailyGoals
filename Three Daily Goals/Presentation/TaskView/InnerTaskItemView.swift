//
//  InnerTaskItemView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/08/2025.
//
import SwiftUI
import TagKit
import UniformTypeIdentifiers
import SwiftData

struct InnerTaskItemView: View {
    let accentColor: Color
    @Bindable var item: TaskItem
    let allTags: [String]
    @State var buildTag: String = ""
    @State var showAttachmentImporter: Bool = false
    let selectedTagStyle: TagCapsuleStyle
    let missingTagStyle: TagCapsuleStyle
    @Environment(\.modelContext) private var modelContext
    let showAttachmentImport: Bool

    private var attachmentButton: some View {
        Button {
            showAttachmentImporter = true
        } label: {
            Label("Add Attachment", systemImage: imgAttachment)
        }
        .help("Add file attachment to this task")
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                StateView(state: item.state, accentColor: accentColor)
                Text("Task").font(.title).foregroundStyle(accentColor)
                Spacer()
            }

            LabeledContent {
                TextField("titleField", text: $item.title).accessibilityIdentifier("titleField")
                .bold().frame(idealHeight: 13)
            } label: {
                Text("Title:").bold().foregroundColor(Color.secondaryColor)
            }

            //        Details
            LabeledContent {
                TextField("Details", text: $item.details, axis: .vertical)
                    #if os(macOS)
                        .textFieldStyle(.squareBorder)
                    #endif
                    .frame(minHeight: 30, idealHeight: 30)
            } label: {
                Text("Details:").bold().foregroundColor(Color.secondaryColor)
            }

            //        URL
            LabeledContent {
                HStack {
                    TextField("URL", text: $item.url, axis: .vertical)
                        #if os(macOS)
                            .textFieldStyle(.squareBorder)
                        #endif
                        .frame(idealHeight: 30).frame(minHeight: 30)
                    if let link = URL(string: item.url) {
                        Link("Open", destination: link)
                    }
                }
            } label: {
                Text("URL:").bold().foregroundColor(Color.secondaryColor)
            }

            LabeledContent {
                DatePickerNullable(selected: $item.due, defaultDate: getDate(inDays: 7))
            } label: {
                Text("Due Date:").bold().foregroundColor(Color.secondaryColor)
            }
            
            GroupBox {
                HStack {
                    Text("Attachments").font(.headline)
                    Spacer()
                    if showAttachmentImport {
                        attachmentButton
                    }
                }
                .padding(.bottom, 4)

                let atts = item.attachments ?? []
                let _ = print("📎 Task '\(item.title)' has \(atts.count) attachments")
                if atts.isEmpty {
                    Text("No attachments yet").foregroundStyle(.secondary)
                } else {
                    ForEach(atts) { att in
                        AttachmentRow(
                            attachment: att,
                            onDelete: showAttachmentImport ? {
                                deleteAttachment(att)
                            } : nil
                        )
                    }
                }
            }

            GroupBox {
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

            Spacer()

            HStack {
                LabeledContent {
                    Text(item.created, format: stdOnlyDateFormat)
                } label: {
                    Text("Created:").bold().foregroundColor(Color.secondaryColor)
                }
                LabeledContent {
                    Text(item.changed.timeAgoDisplay())
                } label: {
                    Text("Changed:").bold().foregroundColor(Color.secondaryColor)
                }
            }
        }
        .background(Color.background)
        .padding()

        .fileImporter(
            isPresented: $showAttachmentImporter,
            allowedContentTypes: [.item], // anything
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
                    let type = try url.resourceValues(forKeys: [.contentTypeKey]).contentType
                              ?? UTType(filenameExtension: url.pathExtension) ?? .data
                    _ = try addAttachment(
                        fileURL: url,
                        type: type,
                        to: item,
                        sortIndex: (item.attachments ?? []).count,
                        in: modelContext
                    )
                    // Touch the task to update the changed timestamp
                    item.touch()
                } catch {
                    // TODO: surface an error toast if you have one
                    print("Add attachment failed:", error)
                }
            }
        }
        .opacity(showAttachmentImport ? 1 : 0) // Hide fileImporter when not needed
    }
    
    private func deleteAttachment(_ attachment: Attachment) {
        // Remove the attachment from the task
        item.attachments?.removeAll { $0.id == attachment.id }
        
        // Delete the attachment from the model context
        modelContext.delete(attachment)
        
        // Touch the task to update the changed timestamp
        item.touch()
        
        // Save the changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete attachment: \(error)")
        }
    }
}
