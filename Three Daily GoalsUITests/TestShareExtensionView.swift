//
//  TestShareExtensionView.swift
//  Three Daily GoalsUITests
//
//  Created by AI Assistant on 2025-01-15.
//

import SwiftData
import UniformTypeIdentifiers
import XCTest
import tdgCoreMain
import tdgCoreShare
import tdgCoreTest

@testable import Three_Daily_Goals

@MainActor
class TestShareExtensionView: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var preferences: CloudPreferences!

    override func setUpWithError() throws {
        // Create in-memory container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: TaskItem.self, Attachment.self, Comment.self, configurations: config)
        context = ModelContext(container)

        // Create test preferences
        let testPreferences = TestPreferences()
        preferences = CloudPreferences(store: testPreferences, timeProvider: RealTimeProvider())
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
        preferences = nil
    }

    // MARK: - Test ShareExtensionView Initialization

    func testInitWithShortText() throws {
        // Given: Short text (under 30 characters)
        let shortText = "Short task"

        // When: Creating ShareExtensionView with short text
        let shareView = ShareExtensionView(text: shortText)

        // Then: Should set title to the text
        XCTAssertEqual(shareView.item.title, shortText, "Should set title to short text")
        XCTAssertTrue(shareView.item.details.isEmpty, "Details should be empty for short text")
    }

    func testInitWithLongText() throws {
        // Given: Long text (over 30 characters)
        let longText = "This is a very long text that exceeds thirty characters and should be treated as details"

        // When: Creating ShareExtensionView with long text
        let shareView = ShareExtensionView(text: longText)

        // Then: Should set title to "Review" and details to the text
        XCTAssertEqual(shareView.item.title, "Review", "Should set title to 'Review' for long text")
        XCTAssertEqual(shareView.item.details, longText, "Should set details to long text")
    }

    func testInitWithDetails() throws {
        // Given: Details text
        let detailsText = "These are the details for the task"

        // When: Creating ShareExtensionView with details
        let shareView = ShareExtensionView(details: detailsText)

        // Then: Should set details only
        XCTAssertEqual(shareView.item.details, detailsText, "Should set details correctly")
        XCTAssertEqual(
            shareView.item.title, "I need to ...", "Title should have default value when only details provided")
    }

    func testInitWithURL() throws {
        // Given: A URL string
        let urlString = "https://example.com/article"

        // When: Creating ShareExtensionView with URL
        let shareView = ShareExtensionView(url: urlString)

        // Then: Should set title to "Read" and URL
        XCTAssertEqual(shareView.item.title, "Read", "Should set title to 'Read' for URL")
        XCTAssertEqual(shareView.item.url, urlString, "Should set URL correctly")
    }

    func testInitWithFileAttachment() throws {
        // Given: A file URL and content type
        let tempURL = createTempFile(content: "Test file content", fileExtension: "txt")
        let contentType = UTType.plainText
        let suggestedFilename = "test.txt"

        // When: Creating ShareExtensionView with file attachment
        let shareView = ShareExtensionView(fileURL: tempURL, contentType: contentType, suggestedFilename: suggestedFilename)

        // Then: Should set up file attachment properties
        XCTAssertEqual(shareView.item.title, "Review File", "Should set title to 'Review File'")
        XCTAssertTrue(shareView.item.details.contains("Shared file:"), "Should include file info in details")
        // Check for the suggested filename, not the temp URL's lastPathComponent
        XCTAssertTrue(shareView.item.details.contains(suggestedFilename), "Should include suggested filename in details")

        // Note: Testing internal state properties may not be reliable in SwiftUI views
        // The important thing is that the item is created correctly with file info
        // The internal state properties are implementation details

        // Cleanup
        try FileManager.default.removeItem(at: tempURL)
    }

    func testInitEmpty() throws {
        // When: Creating ShareExtensionView with no parameters
        let shareView = ShareExtensionView()

        // Then: Should have default values
        XCTAssertEqual(shareView.item.title, "I need to ...", "Should have default title")
        XCTAssertEqual(shareView.item.details, "(no details yet)", "Should have default details")

        // Note: Testing internal state properties may not be reliable in SwiftUI views
        // The important thing is that the item is created correctly
    }

    // MARK: - Test Task Creation and Saving

    func testCreateTaskFromText() async throws {
        // Given: ShareExtensionView with text
        let shareView = ShareExtensionView(text: "Test task from share")

        // When: Creating and saving the task
        let task = try await createAndSaveTask(from: shareView)

        // Then: Should create task with correct properties
        XCTAssertEqual(task.title, "Test task from share", "Should set correct title")
        XCTAssertTrue(task.details.isEmpty, "Should have empty details for short text")
        XCTAssertTrue(task.attachments?.isEmpty == true, "Should have no attachments")
    }

    func testCreateTaskFromLongText() async throws {
        // Given: ShareExtensionView with long text
        let longText = "This is a very long text that should be treated as details for the task"
        let shareView = ShareExtensionView(text: longText)

        // When: Creating and saving the task
        let task = try await createAndSaveTask(from: shareView)

        // Then: Should create task with correct properties
        XCTAssertEqual(task.title, "Review", "Should set title to 'Review'")
        XCTAssertEqual(task.details, longText, "Should set details to long text")
        XCTAssertTrue(task.attachments?.isEmpty == true, "Should have no attachments")
    }

    func testCreateTaskFromURL() async throws {
        // Given: ShareExtensionView with URL
        let urlString = "https://example.com/read-this"
        let shareView = ShareExtensionView(url: urlString)

        // When: Creating and saving the task
        let task = try await createAndSaveTask(from: shareView)

        // Then: Should create task with correct properties
        XCTAssertEqual(task.title, "Read", "Should set title to 'Read'")
        XCTAssertEqual(task.url, urlString, "Should set URL correctly")
        XCTAssertTrue(task.attachments?.isEmpty == true, "Should have no attachments")
    }

    func testCreateTaskWithFileAttachment() async throws {
        // Given: ShareExtensionView with file attachment
        let tempURL = createTempFile(content: "Test file content for attachment", fileExtension: "txt")
        let contentType = UTType.plainText
        let shareView = ShareExtensionView(
            fileURL: tempURL, contentType: contentType, suggestedFilename: "attachment.txt")

        // When: Creating and saving the task with attachment
        let task = try await createAndSaveTaskWithAttachment(from: shareView)

        // Then: Should create task with attachment
        XCTAssertEqual(task.title, "Review File", "Should set title to 'Review File'")
        XCTAssertTrue(task.details.contains("Shared file:"), "Should include file info in details")
        XCTAssertEqual(task.attachments?.count, 1, "Should have one attachment")

        if let attachment = task.attachments?.first {
            XCTAssertEqual(attachment.filename, tempURL.lastPathComponent, "Should have correct filename")
            XCTAssertEqual(attachment.utiIdentifier, contentType.identifier, "Should have correct UTI")
            XCTAssertNotNil(attachment.blob, "Should have blob data")
        }

        // Cleanup
        try FileManager.default.removeItem(at: tempURL)
    }

    func testCreateMultipleTasksFromShare() async throws {
        // Given: Multiple share operations
        let shareViews = [
            ShareExtensionView(text: "First task"),
            ShareExtensionView(url: "https://example.com/1"),
            ShareExtensionView(details: "Third task details"),
        ]

        // When: Creating tasks from all share views
        var tasks: [TaskItem] = []
        for shareView in shareViews {
            let task = try await createAndSaveTask(from: shareView)
            tasks.append(task)
        }

        // Then: Should create separate tasks
        XCTAssertEqual(tasks.count, 3, "Should create three separate tasks")
        XCTAssertEqual(tasks[0].title, "First task", "First task should have correct title")
        XCTAssertEqual(tasks[1].title, "Read", "Second task should have 'Read' title")
        XCTAssertEqual(tasks[1].url, "https://example.com/1", "Second task should have correct URL")
        XCTAssertEqual(tasks[2].details, "Third task details", "Third task should have correct details")
    }

    // MARK: - Test Edge Cases

    func testEmptyTextHandling() async throws {
        // Given: ShareExtensionView with empty text
        let shareView = ShareExtensionView(text: "")

        // When: Creating and saving the task
        let task = try await createAndSaveTask(from: shareView)

        // Then: Should handle empty text gracefully
        XCTAssertTrue(task.title.isEmpty, "Should have empty title for empty text")
        XCTAssertTrue(task.details.isEmpty, "Should have empty details")
    }

    func testVeryLongTextHandling() async throws {
        // Given: Extremely long text
        let veryLongText = String(repeating: "This is a very long text. ", count: 100)
        let shareView = ShareExtensionView(text: veryLongText)

        // When: Creating and saving the task
        let task = try await createAndSaveTask(from: shareView)

        // Then: Should handle very long text
        XCTAssertEqual(task.title, "Review", "Should set title to 'Review' for very long text")
        XCTAssertEqual(task.details, veryLongText, "Should preserve very long text in details")
    }

    func testSpecialCharactersInText() async throws {
        // Given: Text with special characters
        let specialText = "Task with émojis 🎉 and spëcial chars & symbols!"
        let shareView = ShareExtensionView(text: specialText)

        // When: Creating and saving the task
        let task = try await createAndSaveTask(from: shareView)

        // Then: Should preserve special characters in details (since text is longer than 30 chars)
        XCTAssertEqual(task.title, "Review", "Should set title to 'Review' for long text")
        XCTAssertEqual(task.details, specialText, "Should preserve special characters in details")
    }

    // MARK: - Helper Methods

    private func createAndSaveTask(from shareView: ShareExtensionView) async throws -> TaskItem {
        // Simulate the task creation process from ShareExtensionView
        let task = shareView.item
        context.insert(task)
        try context.save()
        return task
    }

    private func createAndSaveTaskWithAttachment(from shareView: ShareExtensionView) async throws -> TaskItem {
        // Simulate the task creation process with attachment
        let task = shareView.item

        // Debug: Print the properties
        print("DEBUG: isFileAttachment: \(shareView.isFileAttachment)")
        print("DEBUG: originalFileURL: \(shareView.originalFileURL?.absoluteString ?? "nil")")
        print("DEBUG: originalContentType: \(shareView.originalContentType?.identifier ?? "nil")")

        // Add attachment if it's a file attachment
        if shareView.isFileAttachment,
            let fileURL = shareView.originalFileURL,
            let contentType = shareView.originalContentType
        {
            print("DEBUG: Adding attachment with fileURL: \(fileURL), contentType: \(contentType.identifier)")
            _ = try addAttachment(
                fileURL: fileURL,
                type: contentType,
                to: task,
                sortIndex: 0,
                in: context
            )
        } else {
            print("DEBUG: Not adding attachment - conditions not met")
        }

        context.insert(task)
        try context.save()
        return task
    }

    private func createTempFile(content: String, fileExtension: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + "." + fileExtension
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            XCTFail("Failed to create temp file: \(error)")
            return fileURL
        }
    }
}
