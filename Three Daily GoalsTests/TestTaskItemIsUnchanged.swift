//
//  TestTaskItemIsUnchanged.swift
//  Three Daily GoalsTests
//
//  Created by AI Assistant on 23/08/2025.
//

import Foundation
import SwiftData
import Testing

@testable import Three_Daily_Goals
@testable import tdgCoreMain

@Suite
@MainActor
struct TestTaskItemIsUnchanged {
    
    var container: ModelContainer!
    var context: ModelContext!
    
    init() throws {
        // Create in-memory container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: TaskItem.self, Attachment.self, Comment.self, configurations: config)
        context = ModelContext(container)
    }
    
    // MARK: - Test Empty Task (should be unchanged)
    
    @Test
    func testIsUnchanged_EmptyTask_ReturnsTrue() throws {
        // Given: A completely empty task
        let task = TaskItem()
        context.insert(task)
        try context.save()
        
        // Then: Should be considered unchanged
        #expect(task.isUnchanged, "Empty task should be considered unchanged")
        #expect(task.isTitleEmpty, "Empty task should have empty title")
        #expect(task.isDetailsEmpty, "Empty task should have empty details")
        #expect(!task.hasAttachments, "Empty task should have no attachments")
    }
    
    @Test
    func testIsUnchanged_EmptyTaskWithDefaultValues_ReturnsTrue() throws {
        // Given: A task with default empty values
        let task = TaskItem()
        task.title = emptyTaskTitle
        task.details = emptyTaskDetails
        context.insert(task)
        try context.save()
        
        // Then: Should be considered unchanged
        #expect(task.isUnchanged, "Task with default empty values should be considered unchanged")
        #expect(task.isTitleEmpty, "Task with emptyTaskTitle should have empty title")
        #expect(task.isDetailsEmpty, "Task with emptyTaskDetails should have empty details")
    }
    
    // MARK: - Test Tasks with Content (should not be unchanged)
    
    @Test
    func testIsUnchanged_WithTitle_ReturnsFalse() throws {
        // Given: A task with only a title
        let task = TaskItem()
        task.title = "Test Title"
        context.insert(task)
        try context.save()
        
        // Then: Should not be considered unchanged
        #expect(!task.isUnchanged, "Task with title should not be considered unchanged")
        #expect(!task.isTitleEmpty, "Task with title should not have empty title")
        #expect(task.isDetailsEmpty, "Task with only title should have empty details")
    }
    
    @Test
    func testIsUnchanged_WithDetails_ReturnsFalse() throws {
        // Given: A task with only details
        let task = TaskItem()
        task.details = "Test Details"
        context.insert(task)
        try context.save()
        
        // Then: Should not be considered unchanged
        #expect(!task.isUnchanged, "Task with details should not be considered unchanged")
        #expect(task.isTitleEmpty, "Task with only details should have empty title")
        #expect(!task.isDetailsEmpty, "Task with details should not have empty details")
    }
    
    @Test
    func testIsUnchanged_WithURL_ReturnsFalse() throws {
        // Given: A task with only a URL
        let task = TaskItem()
        task.url = "https://example.com"
        context.insert(task)
        try context.save()
        
        // Then: Should not be considered unchanged
        #expect(!task.isUnchanged, "Task with URL should not be considered unchanged")
        #expect(task.isTitleEmpty, "Task with only URL should have empty title")
        #expect(task.isDetailsEmpty, "Task with only URL should have empty details")
    }
    
    @Test
    func testIsUnchanged_WithTitleAndDetails_ReturnsFalse() throws {
        // Given: A task with title and details
        let task = TaskItem()
        task.title = "Test Title"
        task.details = "Test Details"
        context.insert(task)
        try context.save()
        
        // Then: Should not be considered unchanged
        #expect(!task.isUnchanged, "Task with title and details should not be considered unchanged")
        #expect(!task.isTitleEmpty, "Task with title should not have empty title")
        #expect(!task.isDetailsEmpty, "Task with details should not have empty details")
    }
    
    @Test
    func testIsUnchanged_WithAllContent_ReturnsFalse() throws {
        // Given: A task with all content fields
        let task = TaskItem()
        task.title = "Test Title"
        task.details = "Test Details"
        task.url = "https://example.com"
        context.insert(task)
        try context.save()
        
        // Then: Should not be considered unchanged
        #expect(!task.isUnchanged, "Task with all content should not be considered unchanged")
        #expect(!task.isTitleEmpty, "Task with title should not have empty title")
        #expect(!task.isDetailsEmpty, "Task with details should not have empty details")
    }
    
    // MARK: - Test Edge Cases
    
    @Test
    func testIsUnchanged_WithWhitespaceOnlyTitle_ReturnsFalse() throws {
        // Given: A task with whitespace-only title
        let task = TaskItem()
        task.title = "   \n\t   "
        context.insert(task)
        try context.save()
        
        // Then: Should NOT be considered unchanged (whitespace is NOT treated as empty)
        #expect(!task.isUnchanged, "Task with whitespace-only title should NOT be considered unchanged")
        #expect(!task.isTitleEmpty, "Task with whitespace-only title should NOT have empty title")
    }
    
    @Test
    func testIsUnchanged_WithWhitespaceOnlyDetails_ReturnsFalse() throws {
        // Given: A task with whitespace-only details
        let task = TaskItem()
        task.details = "   \n\t   "
        context.insert(task)
        try context.save()
        
        // Then: Should NOT be considered unchanged (whitespace is NOT treated as empty)
        #expect(!task.isUnchanged, "Task with whitespace-only details should NOT be considered unchanged")
        #expect(!task.isDetailsEmpty, "Task with whitespace-only details should NOT have empty details")
    }
    
    @Test
    func testIsUnchanged_WithEmptyStringURL_ReturnsTrue() throws {
        // Given: A task with empty string URL
        let task = TaskItem()
        task.url = ""
        context.insert(task)
        try context.save()
        
        // Then: Should be considered unchanged
        #expect(task.isUnchanged, "Task with empty URL should be considered unchanged")
    }
    
    // MARK: - Test Component Properties
    
    @Test
    func testIsTitleEmpty_VariousScenarios() throws {
        // Test empty title
        let task1 = TaskItem()
        #expect(task1.isTitleEmpty, "Default task should have empty title")
        
        // Test with emptyTaskTitle
        let task2 = TaskItem()
        task2.title = emptyTaskTitle
        #expect(task2.isTitleEmpty, "Task with emptyTaskTitle should have empty title")
        
        // Test with actual content
        let task3 = TaskItem()
        task3.title = "Real Title"
        #expect(!task3.isTitleEmpty, "Task with real title should not have empty title")
    }
    
    @Test
    func testIsDetailsEmpty_VariousScenarios() throws {
        // Test empty details
        let task1 = TaskItem()
        #expect(task1.isDetailsEmpty, "Default task should have empty details")
        
        // Test with emptyTaskDetails
        let task2 = TaskItem()
        task2.details = emptyTaskDetails
        #expect(task2.isDetailsEmpty, "Task with emptyTaskDetails should have empty details")
        
        // Test with actual content
        let task3 = TaskItem()
        task3.details = "Real Details"
        #expect(!task3.isDetailsEmpty, "Task with real details should not have empty details")
    }
    
    @Test
    func testHasAttachments_VariousScenarios() throws {
        // Test task without attachments
        let task1 = TaskItem()
        #expect(!task1.hasAttachments, "Default task should have no attachments")
        
        // Test task with nil attachments
        let task2 = TaskItem()
        task2.attachments = nil
        #expect(!task2.hasAttachments, "Task with nil attachments should have no attachments")
        
        // Test task with empty attachments array
        let task3 = TaskItem()
        task3.attachments = []
        #expect(!task3.hasAttachments, "Task with empty attachments array should have no attachments")
    }
    
    // MARK: - Test State Changes
    
    @Test
    func testIsUnchanged_AfterStateChanges() throws {
        // Given: An empty task
        let task = TaskItem()
        context.insert(task)
        try context.save()
        
        // Initially should be unchanged
        #expect(task.isUnchanged, "Empty task should initially be unchanged")
        
        // When: Adding content
        task.title = "New Title"
        
        // Then: Should no longer be unchanged
        #expect(!task.isUnchanged, "Task should not be unchanged after adding title")
        
        // When: Clearing content back to empty
        task.title = emptyTaskTitle
        
        // Then: Should be unchanged again
        #expect(task.isUnchanged, "Task should be unchanged after clearing title")
    }
}
