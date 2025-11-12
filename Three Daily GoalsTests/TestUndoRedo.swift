//
//  TestUndoRedo.swift
//  Three Daily GoalsTests
//
//  Created by AI Assistant on 02/10/2025.
//

import SwiftData
import XCTest
import tdgCoreMain

@testable import Three_Daily_Goals

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
        modelContext = dataManager.modelContext
        undoManager = modelContext.undoManager
        undoManager.removeAllActions()
    }

    override func tearDown() async throws {
        appComponents = nil
        dataManager = nil
        modelContext = nil
        undoManager = nil
    }

    // MARK: - UndoManager Safety Test

    func testRemoveAllActionsClearsUndoStackNotData() throws {
        // Set up app and data
        let initialCount = dataManager.allTasks.count
        let task = dataManager.createTask(title: "Test Task", state: .open)
        try modelContext.save()

        // Confirm data exists
        let afterAddCount = dataManager.allTasks.count
        XCTAssertEqual(afterAddCount, initialCount + 1, "Task should be added")

        // Undo should be available now
        XCTAssertTrue(undoManager.canUndo, "Undo should be possible after add")

        // Now clear the undo stack
        undoManager.removeAllActions()

        // Data should still exist
        let afterRemoveActionsCount = dataManager.allTasks.count
        XCTAssertEqual(afterRemoveActionsCount, initialCount + 1, "Task data should still exist after removeAllActions")

        // Undo and redo should not be available
        XCTAssertFalse(undoManager.canUndo, "Undo should not be available after removeAllActions")
        XCTAssertFalse(undoManager.canRedo, "Redo should not be available after removeAllActions")
    }

    // ... All your other undo/redo tests unchanged ...
    // testUndoRedoAddTask, testUndoRedoDeleteTask, testUndoRedoMoveTask, testUndoRedoButtonStates
}
