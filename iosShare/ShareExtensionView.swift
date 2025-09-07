//
//  ShareExtensionView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/08/2025.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ShareExtensionView: View {
    @State private var item: TaskItem = .init()
    @State private var isFileAttachment: Bool = false
    @State private var originalFileURL: URL?
    @State private var originalContentType: UTType?
    @Environment(CloudPreferences.self) private var pref: CloudPreferences
    @Environment(\.modelContext) var model

    @Query private var allItems: [TaskItem]

    init(text: String) {
        if text.count > 30 {
            self.item.details = text
            self.item.title = "Review"
        } else {
            self.item.title = text
        }
    }
    init(details: String) {
        self.item.details = details
    }
    init(url: String) {
        self.item.title = "Read"
        self.item.url = url
    }

    init(fileURL: URL, contentType: UTType) {
        // Create a task item for the shared file
        self.item.title = "Review File"
        self.item.details = "Shared file: \(fileURL.lastPathComponent)"

        // Store file info for later attachment
        self.originalFileURL = fileURL
        self.originalContentType = contentType
        self.isFileAttachment = true
    }

    init() {
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Button {
                    debugPrint("Number: \(allItems.count)")

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
