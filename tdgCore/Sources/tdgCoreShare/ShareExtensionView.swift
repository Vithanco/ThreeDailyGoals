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
    @State public var suggestedFilename: String?
    @State private var isEnhancing = false
    @State private var enhancer: WebPageEnhancer?
    @State private var fileEnhancer: FileEnhancer?
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

    public init(fileURL: URL, contentType: UTType, suggestedFilename: String?) {
        // Create a task item for the shared file
        var newItem = TaskItem()
        newItem.title = "Review File"
        let displayName = suggestedFilename ?? fileURL.lastPathComponent
        newItem.details = "Shared file: \(displayName)"

        _item = State(initialValue: newItem)
        _isFileAttachment = State(initialValue: true)
        _originalFileURL = State(initialValue: fileURL)
        _originalContentType = State(initialValue: contentType)
        _suggestedFilename = State(initialValue: suggestedFilename)
        _fileEnhancer = State(initialValue: FileEnhancer())
    }

    public init() {
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Main content area
                ScrollView {
                    VStack(spacing: 16) {
                        if isEnhancing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Analyzing file...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }

                        InnerTaskItemView(
                            item: item,
                            allTags: [],
                            showAttachmentImport: false
                        )
                    }
                    .padding()
                }
                .frame(minWidth: 300, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)

                Divider()

                // Bottom action buttons
                HStack(spacing: 12) {
                    Button {
                        self.close()
                    } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)

                    Button {
                        addTask()
                    } label: {
                        Text("Add Task")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(item.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
            }
            #if os(macOS)
                .frame(minWidth: 360, maxWidth: 600, minHeight: 300, maxHeight: 700, alignment: .topLeading)
            #endif
            .navigationTitle("Add to Goals")
            #if os(macOS)
                .navigationSubtitle("Three Daily Goals")
            #endif
            .onAppear {
                // Auto-add file attachment when view appears
                if isFileAttachment, let fileURL = originalFileURL, let contentType = originalContentType {
                    // If we have a suggested filename, rename the temp file to use it
                    let finalFileURL: URL
                    if let suggestedName = suggestedFilename, suggestedName != fileURL.lastPathComponent {
                        // Rename temp file to use the original filename
                        let tempDir = FileManager.default.temporaryDirectory
                        let renamedURL = tempDir.appendingPathComponent(suggestedName)
                        do {
                            // Remove existing file if present
                            if FileManager.default.fileExists(atPath: renamedURL.path) {
                                try FileManager.default.removeItem(at: renamedURL)
                            }
                            try FileManager.default.copyItem(at: fileURL, to: renamedURL)
                            finalFileURL = renamedURL
                        } catch {
                            finalFileURL = fileURL
                        }
                    } else {
                        finalFileURL = fileURL
                    }

                    do {
                        _ = try addAttachment(
                            fileURL: finalFileURL,
                            type: contentType,
                            to: item,
                            sortIndex: 0,
                            in: model
                        )

                        // Auto-enhance file description
                        if let fileEnhancer = fileEnhancer {
                            Task {
                                await enhanceFileDescription(
                                    fileURL: finalFileURL, contentType: contentType, enhancer: fileEnhancer)
                            }
                        }
                    } catch {
                        print("❌ Failed to auto-add attachment: \(error)")
                    }
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

    private func addTask() {
        model.insert(item)

        do {
            try model.save()
        } catch {
            print("❌ Failed to save: \(error)")
        }
        self.close()
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

    private func enhanceFileDescription(fileURL: URL, contentType: UTType, enhancer: FileEnhancer) async {
        isEnhancing = true

        // Use AI if available, otherwise just basic description
        let useAI = enhancer.hasAI
        if let description = await enhancer.enhance(fileURL: fileURL, contentType: contentType, useAI: useAI) {
            // Only update if details are still the default "Shared file:" message
            if item.details.hasPrefix("Shared file:") {
                item.details = description
            }
        }

        isEnhancing = false
    }
}
