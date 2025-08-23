//
//  AttachmentUITests.swift
//  Three Daily GoalsUITests
//
//  Created by AI Assistant on 23/08/2025.
//

import XCTest

@MainActor
final class AttachmentUITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    override func tearDownWithError() throws {
        // Clean up any test files
    }
    
    // MARK: - Attachment UI Workflow Tests
    
    func testAttachmentWorkflow() async throws {
        let app = launchTestApp()
        
        // Create a test task
        let testTaskTitle = "Attachment Test Task"
        try await createTestTask(app: app, title: testTaskTitle)
        
        // Open the task
        let taskElement = findFirst(string: testTaskTitle, whereToLook: app.staticTexts)
        taskElement.tap()
        
        // Verify attachment section exists
        let attachmentSection = app.staticTexts["Attachments"]
        XCTAssertTrue(attachmentSection.exists, "Attachment section should be visible")
        
        // Verify "No attachments yet" message is shown initially
        let noAttachmentsMessage = app.staticTexts["No attachments yet"]
        XCTAssertTrue(noAttachmentsMessage.exists, "Should show 'No attachments yet' message")
        
        // Note: File picker interaction is limited in UI tests
        // We can't actually trigger the file picker, but we can verify the UI elements exist
        
        // Verify "Add Attachment" button exists in GroupBox
        let addAttachmentButton = app.buttons["Add Attachment"]
        XCTAssertTrue(addAttachmentButton.exists, "Add Attachment button should be visible")
        
        // Verify "Add Attachment" button exists in toolbar
        let toolbarAddButton = app.toolbars.buttons["Add Attachment"]
        XCTAssertTrue(toolbarAddButton.exists, "Add Attachment button should be in toolbar")
    }
    
    func testAttachmentDisplayWithExistingAttachment() async throws {
        let app = launchTestApp()
        
        // Create a test task with an attachment (this would require programmatic setup)
        let testTaskTitle = "Task With Attachment"
        try await createTestTask(app: app, title: testTaskTitle)
        
        // Open the task
        let taskElement = findFirst(string: testTaskTitle, whereToLook: app.staticTexts)
        taskElement.tap()
        
        // Verify attachment section exists
        let attachmentSection = app.staticTexts["Attachments"]
        XCTAssertTrue(attachmentSection.exists, "Attachment section should be visible")
        
        // Note: To test with actual attachments, we'd need to programmatically create them
        // This would require additional setup in the test environment
    }
    
    func testAttachmentButtonsVisibility() async throws {
        let app = launchTestApp()
        
        // Create and open a test task
        let testTaskTitle = "Attachment Buttons Test"
        try await createTestTask(app: app, title: testTaskTitle)
        
        let taskElement = findFirst(string: testTaskTitle, whereToLook: app.staticTexts)
        taskElement.tap()
        
        // Verify attachment-related buttons exist
        let addAttachmentButton = app.buttons["Add Attachment"]
        XCTAssertTrue(addAttachmentButton.exists, "Add Attachment button should be visible")
        
        // Verify help text exists
        let helpText = app.staticTexts["Add file attachment to this task"]
        XCTAssertTrue(helpText.exists, "Help text should be visible")
    }
    
    func testAttachmentSectionInTaskView() async throws {
        let app = launchTestApp()
        
        // Create and open a test task
        let testTaskTitle = "Attachment Section Test"
        try await createTestTask(app: app, title: testTaskTitle)
        
        let taskElement = findFirst(string: testTaskTitle, whereToLook: app.staticTexts)
        taskElement.tap()
        
        // Verify the entire attachment section structure
        let attachmentsGroupBox = app.groupBoxes["Attachments"]
        XCTAssertTrue(attachmentsGroupBox.exists, "Attachments GroupBox should exist")
        
        // Verify header elements
        let attachmentsHeader = app.staticTexts["Attachments"]
        XCTAssertTrue(attachmentsHeader.exists, "Attachments header should be visible")
        
        // Verify initial state
        let noAttachmentsMessage = app.staticTexts["No attachments yet"]
        XCTAssertTrue(noAttachmentsMessage.exists, "Should show no attachments message initially")
    }
    
    func testAttachmentWorkflowInShareExtension() async throws {
        // This test would verify that attachments work correctly in share extension context
        // Note: Share extension testing requires additional setup and may not be possible
        // in standard UI tests without special configuration
        
        let app = launchTestApp()
        
        // Create a test task
        let testTaskTitle = "Share Extension Test"
        try await createTestTask(app: app, title: testTaskTitle)
        
        let taskElement = findFirst(string: testTaskTitle, whereToLook: app.staticTexts)
        taskElement.tap()
        
        // Verify attachment functionality is available in main app
        let addAttachmentButton = app.buttons["Add Attachment"]
        XCTAssertTrue(addAttachmentButton.exists, "Add Attachment button should be available")
    }
    
    // MARK: - Helper Methods
    
    private func createTestTask(app: XCUIApplication, title: String) async throws {
        let listOpenButton = findFirst(string: "open_LinkedList", whereToLook: app.staticTexts)
        listOpenButton.tap()
        
        let addButton = findFirst(string: "addTaskButton", whereToLook: app.buttons)
        addButton.tap()
        
        let titleField = findFirst(string: "titleField", whereToLook: app.textFields)
        titleField.doubleTap()
        titleField.clearText()
        titleField.typeText(title)
        
        let submit = findFirst(string: "addTaskWithTitleButton", whereToLook: app.buttons)
        submit.tap()
        
        #if os(iOS)
        let back = findFirst(string: "Back", whereToLook: app.buttons)
        back.tap()
        #endif
        
        listOpenButton.tap()
    }
    
    private func findFirst(string: String, whereToLook: XCUIElementQuery) -> XCUIElement {
        let list = whereToLook.matching(identifier: string)
        XCTAssertTrue(list.count > 0, "couldn't find \(string)")
        return list.element(boundBy: 0)
    }
    
    // MARK: - Test Data Creation
    
    private func createTestFile(filename: String, content: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            XCTFail("Failed to create test file: \(error)")
            return fileURL
        }
    }
    
    private func cleanupTestFile(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            // Ignore cleanup errors in tests
        }
    }
}
