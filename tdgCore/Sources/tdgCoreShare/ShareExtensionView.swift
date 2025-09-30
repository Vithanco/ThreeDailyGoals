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
        if text.count > 30 {
            self.item.details = text
            self.item.title = "Review"
        } else {
            self.item.title = text
            self.item.details = ""  // Explicitly set details to empty for short text
        }
    }
    public init(details: String) {
        self.item.details = details
    }
    public init(url: String) {
        self.item.title = "Read"
        self.item.url = url
    }

    public init(fileURL: URL, contentType: UTType) {
        // Create a task item for the shared file
        self.item.title = "Review File"
        self.item.details = "Shared file: \(fileURL.lastPathComponent)"

        // Store file info for later attachment
        self.originalFileURL = fileURL
        self.originalContentType = contentType
        self.isFileAttachment = true
    }

    public init() {
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Button {

                    // If this is a file attachment, add it to the task
                    if isFileAttachment, let fileURL = originalFileURL, let contentType = originalContentType {
                        do {
                            _ = try addAttachment(
                                fileURL: fileURL,
                                type: contentType,
                                to: item,
                                sortIndex: 0,
                                in: model
                            )
                        } catch {
                            debugPrint("Failed to add attachment: \(error)")
                        }
                    }

                    model.insert(item)

                    do {
                        try model.save()
                    } catch {
                        debugPrint(error)
                    }
                    self.close()
                } label: {
                    Text("Add to Three Daily Goals")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                InnerTaskItemView(
                    item: item,
                    allTags: [],
                    showAttachmentImport: false
                ).frame(minWidth: 300, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)

            }
            .padding()
            .navigationTitle("Share Extension")
            .toolbar {
                Button("Cancel") {
                    self.close()
                }
            }
        }
    }

    // so we can close the whole extension
    func close() {
        NotificationCenter.default.post(name: NSNotification.Name("close"), object: nil)
    }
}
