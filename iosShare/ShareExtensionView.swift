//
//  ShareExtensionView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/08/2025.
//

import SwiftData
import SwiftUI
import TagKit
import UniformTypeIdentifiers

struct ShareExtensionView: View {
    @State private var item: TaskItem = .init()
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

        // Store the file URL and content type for later attachment
        self.item.url = fileURL.absoluteString
        self.item.details = "Shared file: \(fileURL.lastPathComponent)"

        // Note: The actual attachment will be handled when the user clicks "Add to Three Daily Goals"
        // because we need access to the ModelContext which is provided by the .modelContainer modifier
    }

    init() {
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Button {
                    debugPrint("Number: \(allItems.count)")

                    // If this is a file attachment, add it to the task
                    if let fileURL = URL(string: item.url), !item.url.isEmpty && item.details.hasPrefix("Shared file:")
                    {
                        do {
                            let type = try fileURL.resourceValues(forKeys: [.contentTypeKey]).contentType ?? .data
                            _ = try addAttachment(
                                fileURL: fileURL,
                                type: type,
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
                        debugPrint(item)
                        try model.save()
                        debugPrint("Number: \(allItems.count)")
                    } catch {
                        debugPrint(error)
                    }
                    self.close()
                } label: {
                    Text("Add to Three Daily Goals")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                InnerTaskItemView(
                    item: item,
                    allTags: [],
                    selectedTagStyle: selectedTagStyle(accentColor: item.color),
                    missingTagStyle: missingTagStyle,
                    showAttachmentImport: false
                )

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
