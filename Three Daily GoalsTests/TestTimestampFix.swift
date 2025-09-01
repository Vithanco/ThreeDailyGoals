//
//  TestTimestampFix.swift
//  Three Daily GoalsTests
//
//  Created by Assistant on 31/08/2025.
//

import XCTest
@testable import Three_Daily_Goals

final class TestTimestampFix: XCTestCase {
    
    var dataManager: DataManager!
    
    override func setUpWithError() throws {
        dataManager = DataManager.testManager()
    }
    
    override func tearDownWithError() throws {
        dataManager = nil
    }
    
    func testTaskSelectionDoesNotUpdateTimestamp() throws {
        // Create a test task
        let task = TaskItem(title: "Test Task", details: "Test details", state: .open)
        dataManager.modelContext.insert(task)
        
        // Record initial timestamp
        let initialTimestamp = task.changed
        
        // Simulate what happens during task selection - accessing properties
        // This simulates SwiftUI bindings accessing the properties
        let _ = task.title
        let _ = task.details
        let _ = task.url
        let _ = task.due
        let _ = task.state
        let _ = task.color
        
        // Verify timestamp hasn't changed
        XCTAssertEqual(task.changed, initialTimestamp, "Task selection should not update timestamp")
    }
    
    func testSettingSameValuesDoesNotUpdateTimestamp() throws {
        // Create a test task
        let task = TaskItem(title: "Test Task", details: "Test details", state: .open)
        dataManager.modelContext.insert(task)
        
        // Record initial timestamp
        let initialTimestamp = task.changed
        
        // Simulate SwiftUI binding behavior - setting same values
        task.title = "Test Task"  // Same value
        task.details = "Test details"  // Same value
        task.url = ""  // Same value
        task.due = nil  // Same value
        task.state = .open  // Same value
        
        // Verify timestamp hasn't changed
        XCTAssertEqual(task.changed, initialTimestamp, "Setting same values should not update timestamp")
    }
    
    func testActualChangesDoUpdateTimestamp() throws {
        // Create a test task
        let task = TaskItem(title: "Test Task", details: "Test details", state: .open)
        dataManager.modelContext.insert(task)
        
        // Record initial timestamp
        let initialTimestamp = task.changed
        
        // Make actual changes
        task.title = "Modified Task"
        task.details = "Modified details"
        task.url = "https://example.com"
        task.due = Date()
        task.state = .closed
        
        // Verify timestamp has been updated
        XCTAssertGreaterThan(task.changed, initialTimestamp, "Actual changes should update timestamp")
    }
    
    func testColorPropertyAccessDoesNotUpdateTimestamp() throws {
        // Create a test task
        let task = TaskItem(title: "Test Task", state: .open)
        dataManager.modelContext.insert(task)
        
        // Record initial timestamp
        let initialTimestamp = task.changed
        
        // Access color property multiple times
        let _ = task.color
        let _ = task.color
        let _ = task.color
        
        // Verify timestamp hasn't changed
        XCTAssertEqual(task.changed, initialTimestamp, "Accessing color property should not update timestamp")
    }
    
    func testStateChangeWithSameValueDoesNotUpdateTimestamp() throws {
        // Create a test task
        let task = TaskItem(title: "Test Task", state: .open)
        dataManager.modelContext.insert(task)
        
        // Record initial timestamp
        let initialTimestamp = task.changed
        
        // Try to set the same state
        task.state = .open  // Same value
        
        // Verify timestamp hasn't changed
        XCTAssertEqual(task.changed, initialTimestamp, "Setting same state should not update timestamp")
    }
    
    func testTagsChangeWithSameValueDoesNotUpdateTimestamp() throws {
        // Create a test task with tags
        let task = TaskItem(title: "Test Task", state: .open)
        task.tags = ["work", "important"]
        dataManager.modelContext.insert(task)
        
        // Record initial timestamp
        let initialTimestamp = task.changed
        
        // Try to set the same tags
        task.tags = ["work", "important"]  // Same values
        
        // Verify timestamp hasn't changed
        XCTAssertEqual(task.changed, initialTimestamp, "Setting same tags should not update timestamp")
    }
    
    func testCommentWithIconAndState() throws {
        // Create a test task
        let task = TaskItem(title: "Test Task", state: .open)
        dataManager.modelContext.insert(task)
        
        // Add a comment with icon and state
        task.addComment(text: "Test comment with icon", icon: imgTouch, state: .open)
        
        // Verify the comment was added with correct properties
        XCTAssertEqual(task.comments?.count, 1, "Comment should be added")
        
        if let comment = task.comments?.first {
            XCTAssertEqual(comment.text, "Test comment with icon", "Comment text should match")
            XCTAssertEqual(comment.icon, imgTouch, "Comment icon should match")
            XCTAssertEqual(comment.state, .open, "Comment state should match")
        }
    }
    
    func testCommentWithoutIconAndState() throws {
        // Create a test task
        let task = TaskItem(title: "Test Task", state: .open)
        dataManager.modelContext.insert(task)
        
        // Add a comment without icon and state
        task.addComment(text: "Test comment without icon")
        
        // Verify the comment was added with nil properties
        XCTAssertEqual(task.comments?.count, 1, "Comment should be added")
        
        if let comment = task.comments?.first {
            XCTAssertEqual(comment.text, "Test comment without icon", "Comment text should match")
            XCTAssertNil(comment.icon, "Comment icon should be nil")
            XCTAssertNil(comment.state, "Comment state should be nil")
        }
    }
}
