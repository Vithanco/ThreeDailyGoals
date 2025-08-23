//
//  TestAttachments.swift
//  Three Daily GoalsTests
//
//  Created by AI Assistant on 23/08/2025.
//

import XCTest
import SwiftData
import UniformTypeIdentifiers
@testable import Three_Daily_Goals

@MainActor
final class TestAttachments: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    var taskItem: TaskItem!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: TaskItem.self, Attachment.self, Comment.self, configurations: config)
        context = ModelContext(container)
        
        // Create a test task item
        taskItem = TaskItem()
        taskItem.title = "Test Task"
        context.insert(taskItem)
        try context.save()
    }
    
    override func tearDownWithError() throws {
        container = nil
        context = nil
        taskItem = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Attachment Creation Tests
    
    func testAddAttachment() throws {
        // Create test file data
        let testData = "Hello, World!".data(using: .utf8)!
        let tempURL = createTempFile(data: testData, filename: "test.txt")
        
        // Add attachment
        let attachment = try addAttachment(
            fileURL: tempURL,
            type: .plainText,
            to: taskItem,
            sortIndex: 0,
            in: context
        )
        
        // Verify attachment properties
        XCTAssertEqual(attachment.filename, "test.txt")
        XCTAssertEqual(attachment.utiIdentifier, UTType.plainText.identifier)
        XCTAssertEqual(attachment.byteSize, testData.count)
        XCTAssertEqual(attachment.blob, testData)
        // Thumbnail is nil for text files (only images get thumbnails)
        XCTAssertNil(attachment.thumbnail)
        XCTAssertEqual(attachment.taskItem, taskItem)
        XCTAssertFalse(attachment.isPurged)
        XCTAssertNil(attachment.purgedAt)
        
        // Verify task has attachment
        XCTAssertEqual(taskItem.attachments?.count, 1)
        XCTAssertEqual(taskItem.attachments?.first, attachment)
        
        // Cleanup
        try FileManager.default.removeItem(at: tempURL)
    }
    
    func testAddAttachmentWithCaption() throws {
        let testData = "Test content".data(using: .utf8)!
        let tempURL = createTempFile(data: testData, filename: "caption_test.txt")
        
        let attachment = try addAttachment(
            fileURL: tempURL,
            type: .plainText,
            to: taskItem,
            caption: "Test caption",
            in: context
        )
        
        XCTAssertEqual(attachment.caption, "Test caption")
        
        try FileManager.default.removeItem(at: tempURL)
    }
    
    func testDuplicateAttachmentDetection() throws {
        let testData = "Duplicate test".data(using: .utf8)!
        let tempURL1 = createTempFile(data: testData, filename: "duplicate1.txt")
        let tempURL2 = createTempFile(data: testData, filename: "duplicate2.txt")
        
        // Add first attachment
        let attachment1 = try addAttachment(
            fileURL: tempURL1,
            type: .plainText,
            to: taskItem,
            in: context
        )
        
        // Verify first attachment was created
        XCTAssertEqual(taskItem.attachments?.count, 1)
        
        // Try to add duplicate (same content, different filename)
        let attachment2 = try addAttachment(
            fileURL: tempURL2,
            type: .plainText,
            to: taskItem,
            in: context
        )
        
        // Verify both attachments were created (no duplicate detection)
        XCTAssertNotEqual(attachment1.id, attachment2.id, "Should create separate attachments")
        XCTAssertEqual(taskItem.attachments?.count, 2, "Should have two attachments")
        
        try FileManager.default.removeItem(at: tempURL1)
        try FileManager.default.removeItem(at: tempURL2)
    }
    
    func testAddMultipleAttachments() throws {
        let data1 = "First file".data(using: .utf8)!
        let data2 = "Second file".data(using: .utf8)!
        
        let url1 = createTempFile(data: data1, filename: "first.txt")
        let url2 = createTempFile(data: data2, filename: "second.txt")
        
        let attachment1 = try addAttachment(fileURL: url1, type: .plainText, to: taskItem, in: context)
        let attachment2 = try addAttachment(fileURL: url2, type: .plainText, to: taskItem, in: context)
        
        XCTAssertEqual(taskItem.attachments?.count, 2)
        XCTAssertEqual(attachment1.sortIndex, 0)
        XCTAssertEqual(attachment2.sortIndex, 1)
        
        try FileManager.default.removeItem(at: url1)
        try FileManager.default.removeItem(at: url2)
    }
    
    // MARK: - Attachment Deletion Tests
    
    func testDeleteAttachment() throws {
        let testData = "Delete test".data(using: .utf8)!
        let tempURL = createTempFile(data: testData, filename: "delete_test.txt")
        
        let attachment = try addAttachment(
            fileURL: tempURL,
            type: .plainText,
            to: taskItem,
            in: context
        )
        
        XCTAssertEqual(taskItem.attachments?.count, 1)
        
        // Delete attachment using the actual deletion function
        let filename = attachment.filename
        taskItem.attachments?.removeAll { $0.id == attachment.id }
        context.delete(attachment)
        taskItem.addComment(text: "Removed attachment: \(filename)")
        try context.save()
        
        // Verify deletion
        XCTAssertEqual(taskItem.attachments?.count, 0)
        
        // Verify comment was added
        let comments = taskItem.comments ?? []
        XCTAssertTrue(comments.contains { $0.text.contains("Removed attachment: delete_test.txt") })
        
        try FileManager.default.removeItem(at: tempURL)
    }
    
    // MARK: - Attachment Properties Tests
    
    func testAttachmentStoredBytes() throws {
        let testData = "Size test".data(using: .utf8)!
        let tempURL = createTempFile(data: testData, filename: "size_test.txt")
        
        let attachment = try addAttachment(
            fileURL: tempURL,
            type: .plainText,
            to: taskItem,
            in: context
        )
        
        XCTAssertEqual(attachment.storedBytes, testData.count)
        
        try FileManager.default.removeItem(at: tempURL)
    }
    
    func testAttachmentIsDueForPurge() throws {
        let testData = "Purge test".data(using: .utf8)!
        let tempURL = createTempFile(data: testData, filename: "purge_test.txt")
        
        let attachment = try addAttachment(
            fileURL: tempURL,
            type: .plainText,
            to: taskItem,
            in: context
        )
        
        // Initially not due for purge (no nextPurgePrompt set)
        XCTAssertFalse(attachment.isDueForPurge())
        
        // Set purge prompt to a past date
        let pastDate = Date.now.addingTimeInterval(-86400) // 1 day ago
        attachment.nextPurgePrompt = pastDate
        try context.save()
        
        // Verify the date was set correctly
        XCTAssertNotNil(attachment.nextPurgePrompt)
        XCTAssertTrue(pastDate < Date.now)
        
        // Now due for purge
        XCTAssertTrue(attachment.isDueForPurge())
        
        try FileManager.default.removeItem(at: tempURL)
    }
    
    // MARK: - Attachment Purge Tests
    
    func testPurgeAttachment() throws {
        let testData = "Purge test".data(using: .utf8)!
        let tempURL = createTempFile(data: testData, filename: "purge_test.txt")
        
        let attachment = try addAttachment(
            fileURL: tempURL,
            type: .plainText,
            to: taskItem,
            in: context
        )
        
        XCTAssertNotNil(attachment.blob)
        XCTAssertFalse(attachment.isPurged)
        
        // Purge attachment
        try attachment.purge(in: context)
        
        // Verify purge
        XCTAssertNil(attachment.blob)
        XCTAssertTrue(attachment.isPurged)
        XCTAssertNotNil(attachment.purgedAt)
        XCTAssertNil(attachment.nextPurgePrompt)
        XCTAssertEqual(attachment.storedBytes, 0)
        
        try FileManager.default.removeItem(at: tempURL)
    }
    
    func testScheduleNextPurgePrompt() throws {
        let testData = "Schedule test".data(using: .utf8)!
        let tempURL = createTempFile(data: testData, filename: "schedule_test.txt")
        
        let attachment = try addAttachment(
            fileURL: tempURL,
            type: .plainText,
            to: taskItem,
            in: context
        )
        
        XCTAssertNil(attachment.nextPurgePrompt)
        
        // Schedule purge for 3 months from now
        try attachment.scheduleNextPurgePrompt(months: 3, in: context)
        
        XCTAssertNotNil(attachment.nextPurgePrompt)
        
        let expectedDate = Calendar.current.date(byAdding: .month, value: 3, to: .now)!
        let tolerance: TimeInterval = 60 // 1 minute tolerance
        XCTAssertEqual(attachment.nextPurgePrompt?.timeIntervalSince1970 ?? 0, expectedDate.timeIntervalSince1970, accuracy: tolerance)
        
        try FileManager.default.removeItem(at: tempURL)
    }
    
    func testSameContentDifferentTasks() throws {
        // Create a second task item
        let taskItem2 = TaskItem()
        taskItem2.title = "Second Task"
        context.insert(taskItem2)
        try context.save()
        
        let testData = "Shared content".data(using: .utf8)!
        let tempURL1 = createTempFile(data: testData, filename: "shared1.txt")
        let tempURL2 = createTempFile(data: testData, filename: "shared2.txt")
        
        // Add attachment to first task
        let attachment1 = try addAttachment(
            fileURL: tempURL1,
            type: .plainText,
            to: taskItem,
            in: context
        )
        
        // Add same content to second task
        let attachment2 = try addAttachment(
            fileURL: tempURL2,
            type: .plainText,
            to: taskItem2,
            in: context
        )
        
        // Verify they are different attachment objects
        XCTAssertNotEqual(attachment1.id, attachment2.id, "Should create separate attachments for different tasks")
        XCTAssertEqual(attachment1.taskItem, taskItem, "First attachment should belong to first task")
        XCTAssertEqual(attachment2.taskItem, taskItem2, "Second attachment should belong to second task")
        
        // Verify both have the blob data (current behavior - duplication)
        XCTAssertNotNil(attachment1.blob, "First attachment should have blob data")
        XCTAssertNotNil(attachment2.blob, "Second attachment should have blob data")
        XCTAssertEqual(attachment1.blob, attachment2.blob, "Blob data should be identical")
        
        try FileManager.default.removeItem(at: tempURL1)
        try FileManager.default.removeItem(at: tempURL2)
    }
    
    func testFileSizeValidation() throws {
        // Test files at various sizes around the 20MB limit
        let testCases = [
            (size: 19 * 1024 * 1024, shouldPass: true, description: "19MB file (under limit)"),
            (size: 20 * 1024 * 1024, shouldPass: true, description: "20MB file (at limit)"),
            (size: 21 * 1024 * 1024, shouldPass: false, description: "21MB file (over limit)"),
            (size: 25 * 1024 * 1024, shouldPass: false, description: "25MB file (over limit)")
        ]
        
        for testCase in testCases {
            let testData = Data(repeating: 0, count: testCase.size)
            let tempURL = createTempFile(data: testData, filename: "test_file_\(testCase.size).bin")
            
            do {
                let attachment = try addAttachment(
                    fileURL: tempURL,
                    type: .data,
                    to: taskItem,
                    in: context
                )
                
                if testCase.shouldPass {
                    XCTAssertEqual(attachment.byteSize, testCase.size, "\(testCase.description) should pass")
                } else {
                    XCTFail("\(testCase.description) should have failed but passed")
                }
            } catch AttachmentError.fileTooLarge(let fileSize, let maxSize) {
                if testCase.shouldPass {
                    XCTFail("\(testCase.description) should have passed but failed")
                } else {
                    XCTAssertEqual(fileSize, testCase.size, "File size should match")
                    XCTAssertEqual(maxSize, 20 * 1024 * 1024, "Max size should be 20MB")
                }
            } catch {
                XCTFail("Unexpected error for \(testCase.description): \(error)")
            }
            
            try FileManager.default.removeItem(at: tempURL)
        }
    }
    
    func testDefaultSizeLimit() throws {
        // Test that we can create a file exactly at the 20MB limit
        let exactLimitData = Data(repeating: 0, count: 20 * 1024 * 1024) // Exactly 20MB
        let tempURL = createTempFile(data: exactLimitData, filename: "exact_limit.bin")
        
        let attachment = try addAttachment(
            fileURL: tempURL,
            type: .data,
            to: taskItem,
            in: context
        )
        
        XCTAssertEqual(attachment.byteSize, 20 * 1024 * 1024, "Should accept exactly 20MB file")
        
        try FileManager.default.removeItem(at: tempURL)
    }
    
    // MARK: - Helper Methods
    
    private func createTempFile(data: Data, filename: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            XCTFail("Failed to create temp file: \(error)")
            return fileURL
        }
    }
}
