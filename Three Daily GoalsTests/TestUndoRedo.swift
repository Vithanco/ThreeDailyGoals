//
//  TestUndoRedo.swift
//  Three Daily GoalsTests
//
//  Created by AI Assistant on 02/10/2025.
//

import XCTest
import SwiftData
@testable import Three_Daily_Goals
import tdgCoreMain

@MainActor
final class TestUndoRedo: XCTestCase {
    
    var appComponents: AppComponents!
    var dataManager: DataManager!
    var modelContext: ModelContext!
    var undoManager: UndoManager!
    
    override func setUp() async throws {
        // Set up app components with test data
        appComponents = setupApp(isTesting: true, timeProvider: MockTimeProvider(fixedNow: Date.now))
        dataManager = appComponents.dataManager
        
        // Get the model context (need to cast from Storage protocol)
        if let ctx = dataManager.modelContext as? ModelContext {
            modelContext = ctx
            undoManager = ctx.undoManager
        } else {
            XCTFail("Model context is not a ModelContext")
        }
    }
    
    override func tearDown() async throws {
        appComponents = nil
        dataManager = nil
        modelContext = nil
        undoManager = nil
    }
    
    // MARK: - Basic Undo/Redo Tests
    
    func testUndoRedoAddTask() throws {
        // Given: Initial state
        let initialCount = dataManager.allTasks.count
        XCTAssertFalse(dataManager.canUndo, "Should not be able to undo initially")
        
        // When: Add a task
        let task = dataManager.createTask(title: "Test Task", state: .open)
        try modelContext.save()
        
        // Then: Can undo
        XCTAssertTrue(dataManager.canUndo, "Should be able to undo after adding task")
        XCTAssertFalse(dataManager.canRedo, "Should not be able to redo yet")
        XCTAssertEqual(dataManager.allTasks.count, initialCount + 1, "Task should be added")
        
        // When: Undo
        dataManager.undo()
        
        // Then: Task should be removed and can redo
        XCTAssertFalse(dataManager.canUndo, "Should not be able to undo after undoing last action")
        XCTAssertTrue(dataManager.canRedo, "Should be able to redo after undo")
        
        // Fetch fresh data to verify
        let descriptor = FetchDescriptor<TaskItem>()
        let tasks = try modelContext.fetch(descriptor)
        XCTAssertEqual(tasks.count, initialCount, "Task should be removed after undo")
        
        // When: Redo
        dataManager.redo()
        
        // Then: Task should be back
        XCTAssertTrue(dataManager.canUndo, "Should be able to undo after redo")
        XCTAssertFalse(dataManager.canRedo, "Should not be able to redo after redo")
        
        let tasksAfterRedo = try modelContext.fetch(descriptor)
        XCTAssertEqual(tasksAfterRedo.count, initialCount + 1, "Task should be back after redo")
    }
    
    func testUndoRedoDeleteTask() throws {
        // Given: Create a task
        let task = dataManager.createTask(title: "Task to Delete", state: .open)
        try modelContext.save()
        undoManager?.removeAllActions() // Clear undo stack
        
        let countBeforeDelete = dataManager.allTasks.count
        
        // When: Delete the task
        dataManager.deleteTask(task)
        try modelContext.save()
        
        // Then: Can undo
        XCTAssertTrue(dataManager.canUndo, "Should be able to undo after delete")
        
        // Fetch fresh data
        let descriptor = FetchDescriptor<TaskItem>()
        let tasksAfterDelete = try modelContext.fetch(descriptor)
        XCTAssertEqual(tasksAfterDelete.count, countBeforeDelete - 1, "Task should be deleted")
        
        // When: Undo
        dataManager.undo()
        
        // Then: Task should be back
        let tasksAfterUndo = try modelContext.fetch(descriptor)
        XCTAssertEqual(tasksAfterUndo.count, countBeforeDelete, "Task should be restored after undo")
        XCTAssertTrue(dataManager.canRedo, "Should be able to redo after undo")
    }
    
    func testUndoRedoMoveTask() throws {
        // Given: Create a task in open state
        let task = dataManager.createTask(title: "Task to Move", state: .open)
        try modelContext.save()
        undoManager?.removeAllActions() // Clear undo stack
        
        XCTAssertEqual(task.state, .open, "Task should start in open state")
        
        // When: Move task to closed
        dataManager.move(task: task, to: .closed)
        try modelContext.save()
        
        // Then: Task is closed and can undo
        XCTAssertEqual(task.state, .closed, "Task should be closed")
        XCTAssertTrue(dataManager.canUndo, "Should be able to undo after move")
        
        // When: Undo
        dataManager.undo()
        
        // Then: Task should be back to open
        XCTAssertEqual(task.state, .open, "Task should be back to open after undo")
        XCTAssertTrue(dataManager.canRedo, "Should be able to redo after undo")
        
        // When: Redo
        dataManager.redo()
        
        // Then: Task should be closed again
        XCTAssertEqual(task.state, .closed, "Task should be closed again after redo")
    }
    
    func testUndoRedoButtonStates() throws {
        // Given: Initial state
        XCTAssertFalse(dataManager.undoAvailable, "Undo should not be available initially")
        XCTAssertFalse(dataManager.redoAvailable, "Redo should not be available initially")
        
        // When: Add a task
        _ = dataManager.createTask(title: "Test", state: .open)
        try modelContext.save()
        
        // Wait a bit for notifications
        let expectation = expectation(description: "Undo state updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then: Undo should be available
        XCTAssertTrue(dataManager.undoAvailable, "Undo should be available after add")
        XCTAssertFalse(dataManager.redoAvailable, "Redo should not be available")
        
        // When: Undo
        dataManager.undo()
        
        // Wait for notifications
        let expectation2 = self.expectation(description: "Undo state updated after undo")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)
        
        // Then: Redo should be available
        XCTAssertFalse(dataManager.undoAvailable, "Undo should not be available after undo")
        XCTAssertTrue(dataManager.redoAvailable, "Redo should be available after undo")
    }
}

