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
    @State private var isEnhancing = false
    @State private var enhancer: WebPageEnhancer?
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
        _enhancer = State(initialValue: WebPageEnhancer())
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
                            print("❌ Failed to add attachment: \(error)")
                        }
                    }

                    model.insert(item)

                    do {
                        try model.save()
                    } catch {
                        print("❌ Failed to save: \(error)")
                    }
                    self.close()
                } label: {
                    Text("Add to Three Daily Goals")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if isEnhancing {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Extracting title and description...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }

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
            .task {
                // Auto-enhance when sharing a URL
                let urlString = item.url
                if !urlString.isEmpty,
                    let url = URL(string: urlString),
                    let enhancer = enhancer
                {
                    await enhanceURL(url, enhancer: enhancer)
                }
            }
        }
    }

    // so we can close the whole extension
    func close() {
        NotificationCenter.default.post(name: NSNotification.Name("close"), object: nil)
    }

    private func enhanceURL(_ url: URL, enhancer: WebPageEnhancer) async {
        isEnhancing = true

        let (formattedTitle, description) = await enhancer.enhance(
            url: url,
            currentTitle: item.title,
            useAI: false
        )

        item.title = formattedTitle

        if let desc = description {
            item.details = desc
        }

        isEnhancing = false
    }
}
