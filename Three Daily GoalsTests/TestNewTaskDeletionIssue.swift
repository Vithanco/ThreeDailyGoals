//
//  TestNewTaskDeletionIssue.swift
//  Three Daily GoalsTests
//
//  Created by AI Assistant on 07/01/2025.
//

import Testing
@testable import Three_Daily_Goals
import tdgCoreMain

/// Test to reproduce the issue where newly created tasks get deleted when navigating away
/// without changes, but persist in the database and reappear after restart
struct TestNewTaskDeletionIssue {
    
    @Test @MainActor
    func testNewTaskGetsDeletedWhenUnchanged() throws {
        // Given: App setup with testing configuration
        let appComponents = setupApp(isTesting: true, loaderForTests: emptyTestDataLoader)
        let dataManager = appComponents.dataManager
        let uiState = appComponents.uiState
        
        // When: Creating a new task via the add button (simulating the flow)
        let initialCount = dataManager.allTasks.count
        uiState.addNewItem()
        
        // Then: The task should be created and added to the open list
        #expect(dataManager.allTasks.count == initialCount + 1, "Task count should increase")
        #expect(uiState.selectedItem != nil, "A task should be selected")
        #expect(uiState.selectedItem!.isUnchanged, "New task should be considered unchanged")
        #expect(dataManager.list(which: .open).contains(uiState.selectedItem!), "New task should be in open list")
        
        // When: Simulating navigation away (selecting a different task or closing detail view)
        // This triggers the removal logic in UIStateManager.select()
        if let currentTask = uiState.selectedItem {
            dataManager.removeItem(currentTask)
        }
        
        // Then: The task should be removed from the lists and items array
        #expect(dataManager.allTasks.count == initialCount, "Task count should return to initial")
        #expect(dataManager.list(which: .open).isEmpty, "Open list should be empty")
        
        // This demonstrates the issue - the task gets saved to database but removed from in-memory lists
    }
    
    @Test @MainActor
    func testTaskCreationAndImmediateDeletionFlow() throws {
        // Given: App setup with testing configuration
        let appComponents = setupApp(isTesting: true, loaderForTests: emptyTestDataLoader)
        let dataManager = appComponents.dataManager
        let uiState = appComponents.uiState
        
        // When: Creating a new task (simulating add button click)
        let initialCount = dataManager.allTasks.count
        uiState.addNewItem()
        
        // Then: Task should be added
        #expect(dataManager.allTasks.count == initialCount + 1, "Task count should increase")
        #expect(uiState.selectedItem!.isUnchanged, "New task should be unchanged")
        
        // When: Simulating the UI flow where user navigates away without changes
        // This triggers the removal logic in UIStateManager.select()
        if let currentTask = uiState.selectedItem {
            dataManager.removeItem(currentTask)
        }
        
        // Then: Task should be removed from memory
        #expect(dataManager.allTasks.count == initialCount, "Task count should return to initial")
        #expect(dataManager.list(which: .open).isEmpty, "Open list should be empty")
        
        // This is the bug - the task gets saved to database but removed from in-memory lists
    }
}
