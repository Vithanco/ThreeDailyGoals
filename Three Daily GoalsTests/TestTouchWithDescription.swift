//
//  TestTouchWithDescription.swift
//  Three Daily GoalsTests
//
//  Created by Assistant on 31/08/2025.
//

import XCTest
@testable import Three_Daily_Goals

final class TestTouchWithDescription: XCTestCase {
    
    var dataManager: DataManager!
    
    override func setUpWithError() throws {
        dataManager = DataManager.testManager()
    }
    
    override func tearDownWithError() throws {
        dataManager = nil
    }
    
    func testTouchWithDescriptionAddsComment() throws {
        // Create a test task
        let task = TaskItem(title: "Test Task")
        dataManager.modelContext.insert(task)
        
        // Verify initial state
        XCTAssertEqual(task.comments?.count ?? 0, 0)
        
        // Test touch with description
        let description = "Completed the first phase"
        dataManager.touchWithDescriptionAndUpdateUndoStatus(task: task, description: description)
        
        // Verify comment was added
        XCTAssertEqual(task.comments?.count ?? 0, 1)
        XCTAssertEqual(task.comments?.first?.text, description)
        
        // Verify changed date was updated
        XCTAssertGreaterThan(task.changed, task.created)
    }
    
    func testTouchWithEmptyDescriptionUsesDefaultTouch() throws {
        // Create a test task
        let task = TaskItem(title: "Test Task")
        dataManager.modelContext.insert(task)
        
        // Verify initial state
        XCTAssertEqual(task.comments?.count ?? 0, 0)
        
        // Test touch with empty description
        dataManager.touchWithDescriptionAndUpdateUndoStatus(task: task, description: "")
        
        // Verify default touch comment was added
        XCTAssertEqual(task.comments?.count ?? 0, 1)
        XCTAssertEqual(task.comments?.first?.text, "You 'touched' this task.")
        
        // Verify changed date was updated
        XCTAssertGreaterThan(task.changed, task.created)
    }
    
    func testTouchWithWhitespaceOnlyDescriptionUsesDefaultTouch() throws {
        // Create a test task
        let task = TaskItem(title: "Test Task")
        dataManager.modelContext.insert(task)
        
        // Verify initial state
        XCTAssertEqual(task.comments?.count ?? 0, 0)
        
        // Test touch with whitespace-only description
        dataManager.touchWithDescriptionAndUpdateUndoStatus(task: task, description: "   \n\t  ")
        
        // Verify default touch comment was added
        XCTAssertEqual(task.comments?.count ?? 0, 1)
        XCTAssertEqual(task.comments?.first?.text, "You 'touched' this task.")
        
        // Verify changed date was updated
        XCTAssertGreaterThan(task.changed, task.created)
    }
}
