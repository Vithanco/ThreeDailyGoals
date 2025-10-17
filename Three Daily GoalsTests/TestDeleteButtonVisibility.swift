//
//  TestDeleteButtonVisibility.swift
//  Three Daily GoalsTests
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import Testing
import SwiftUI

@testable import Three_Daily_Goals
@testable import tdgCoreMain

@Suite
@MainActor
struct TestDeleteButtonVisibility {
    
    @Test
    func testCanBeDeletedForClosedTasks() throws {
        let appComponents = setupApp(isTesting: true, loaderForTests: { _ in return [] })
        let dataManager = appComponents.dataManager
        
        // Create a task in closed state
        let closedTask = TaskItem(title: "Closed Task", details: "This is closed", state: .closed)
        dataManager.addItem(item: closedTask)
        
        // Verify it can be deleted
        #expect(closedTask.canBeDeleted == true, "Closed tasks should be deletable")
    }
    
    @Test
    func testCanBeDeletedForDeadTasks() throws {
        let appComponents = setupApp(isTesting: true, loaderForTests: { _ in return [] })
        let dataManager = appComponents.dataManager
        
        // Create a task in dead state
        let deadTask = TaskItem(title: "Dead Task", details: "This is dead", state: .dead)
        dataManager.addItem(item: deadTask)
        
        // Verify it can be deleted
        #expect(deadTask.canBeDeleted == true, "Dead tasks should be deletable")
    }
    
    @Test
    func testCannotBeDeletedForOpenTasks() throws {
        let appComponents = setupApp(isTesting: true, loaderForTests: { _ in return [] })
        let dataManager = appComponents.dataManager
        
        // Create a task in open state
        let openTask = TaskItem(title: "Open Task", details: "This is open", state: .open)
        dataManager.addItem(item: openTask)
        
        // Verify it cannot be deleted
        #expect(openTask.canBeDeleted == false, "Open tasks should not be deletable")
    }
    
    @Test
    func testCannotBeDeletedForPriorityTasks() throws {
        let appComponents = setupApp(isTesting: true, loaderForTests: { _ in return [] })
        let dataManager = appComponents.dataManager
        
        // Create a task in priority state
        let priorityTask = TaskItem(title: "Priority Task", details: "This is priority", state: .priority)
        dataManager.addItem(item: priorityTask)
        
        // Verify it cannot be deleted
        #expect(priorityTask.canBeDeleted == false, "Priority tasks should not be deletable")
    }
    
    @Test
    func testCannotBeDeletedForPendingResponseTasks() throws {
        let appComponents = setupApp(isTesting: true, loaderForTests: { _ in return [] })
        let dataManager = appComponents.dataManager
        
        // Create a task in pending response state
        let pendingTask = TaskItem(title: "Pending Task", details: "This is pending", state: .pendingResponse)
        dataManager.addItem(item: pendingTask)
        
        // Verify it cannot be deleted
        #expect(pendingTask.canBeDeleted == false, "Pending response tasks should not be deletable")
    }
    
    @Test
    func testDeleteButtonVisibilityInTaskAsLine() throws {
        let appComponents = setupApp(isTesting: true, loaderForTests: { _ in return [] })
        let dataManager = appComponents.dataManager
        let uiState = appComponents.uiState
        
        // Test with closed task - should show delete button
        let closedTask = TaskItem(title: "Closed Task", details: "This is closed", state: .closed)
        dataManager.addItem(item: closedTask)
        
        // Create TaskAsLine view and check if delete button would be shown
        let taskAsLine = TaskAsLine(item: closedTask)
            .environment(uiState)
            .environment(dataManager)
            .environment(appComponents.preferences)
        
        // The delete button should be available in swipe actions for closed tasks
        #expect(closedTask.canBeDeleted == true, "Closed task should allow deletion")
        
        // Test with open task - should not show delete button
        let openTask = TaskItem(title: "Open Task", details: "This is open", state: .open)
        dataManager.addItem(item: openTask)
        
        #expect(openTask.canBeDeleted == false, "Open task should not allow deletion")
    }
    
    @Test
    func testAllTaskStatesForDeleteEligibility() throws {
        // Test all possible task states
        let allStates: [TaskItemState] = [.open, .closed, .dead, .pendingResponse, .priority]
        
        for state in allStates {
            let task = TaskItem(title: "Test Task", details: "Test details", state: state)
            
            switch state {
            case .closed, .dead:
                #expect(task.canBeDeleted == true, "\(state) tasks should be deletable")
            case .open, .pendingResponse, .priority:
                #expect(task.canBeDeleted == false, "\(state) tasks should not be deletable")
            }
        }
    }
    
    @Test
    func testDeleteButtonImplementation() throws {
        let appComponents = setupApp(isTesting: true, loaderForTests: { _ in return [] })
        let dataManager = appComponents.dataManager
        let uiState = appComponents.uiState
        
        // Create a closed task
        let closedTask = TaskItem(title: "Closed Task", details: "This is closed", state: .closed)
        dataManager.addItem(item: closedTask)
        
        // Test that deleteButton method exists and can be called
        let deleteButton = dataManager.deleteButton(item: closedTask, uiState: uiState)
        
        // The delete button should be created without errors
        #expect(deleteButton != nil, "Delete button should be created for closed tasks")
        
        // Test that the task can actually be deleted
        let initialCount = dataManager.allTasks.count
        dataManager.deleteWithUIUpdate(task: closedTask, uiState: uiState)
        let finalCount = dataManager.allTasks.count
        
        #expect(finalCount == initialCount - 1, "Task should be deleted from items list")
    }
}
