//
//  ShareExtensionView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/08/2025.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

public struct ShareExtensionView: View {
    @State public var item: TaskItem = .init()
    @State public var isFileAttachment: Bool = false
    @State public var originalFileURL: URL?
    @State public var originalContentType: UTType?
    @Environment(CloudPreferences.self) var pref: CloudPreferences
    @Environment(\.modelContext) var model

    @Query private var allItems: [TaskItem]

    public init(text: String) {
        var newItem = TaskItem()
        if text.count > 30 {
            newItem.details = text
            newItem.title = "Review"
        } else {
            newItem.title = text
            newItem.details = ""  // Explicitly set details to empty for short text
        }
        _item = State(initialValue: newItem)
    }

    public init(details: String) {
        var newItem = TaskItem()
        newItem.details = details
        _item = State(initialValue: newItem)
    }

    public init(url: String) {
        var newItem = TaskItem()
        newItem.title = "Read"
        newItem.url = url
        _item = State(initialValue: newItem)
    }

    public init(fileURL: URL, contentType: UTType) {
        // Create a task item for the shared file
        var newItem = TaskItem()
        newItem.title = "Review File"
        newItem.details = "Shared file: \(fileURL.lastPathComponent)"

        _item = State(initialValue: newItem)
        _isFileAttachment = State(initialValue: true)
        _originalFileURL = State(initialValue: fileURL)
        _originalContentType = State(initialValue: contentType)
    }

    public init() {
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Button {
                    print("🔘 Add button tapped")
                    // If this is a file attachment, add it to the task
                    if isFileAttachment, let fileURL = originalFileURL, let contentType = originalContentType {
                        print("📎 Adding file attachment: \(fileURL.lastPathComponent)")
                        do {
                            _ = try addAttachment(
                                fileURL: fileURL,
                                type: contentType,
                                to: item,
                                sortIndex: 0,
                                in: model
                            )
                            print("✅ Attachment added successfully")
                        } catch {
                            print("❌ Failed to add attachment: \(error)")
                            debugPrint("Failed to add attachment: \(error)")
                        }
                    }

                    model.insert(item)

                    do {
                        try model.save()
                        print("✅ Item saved successfully")
                    } catch {
                        print("❌ Failed to save: \(error)")
                        debugPrint(error)
                    }
                    self.close()
                } label: {
                    Text("Add to Three Daily Goals")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                ScrollView {
                    InnerTaskItemView(
                        item: item,
                        allTags: [],
                        showAttachmentImport: false
                    )
                }
                .frame(minWidth: 300, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)

            }
            .padding()
            .navigationTitle("Share Extension")
            .toolbar {
                Button("Cancel") {
                    self.close()
                }
            }
            .onAppear {
                print("📱 ShareExtensionView appeared")
                print("  - title: '\(item.title)'")
                print("  - url: '\(item.url ?? "nil")'")
                print("  - details: '\(item.details)'")
                print("  - isFileAttachment: \(isFileAttachment)")
            }
        }
    }

    // so we can close the whole extension
    func close() {
        NotificationCenter.default.post(name: NSNotification.Name("close"), object: nil)
    }
}
