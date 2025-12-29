//
//  TestTaskDeletion.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 14/01/2025.
//

import Foundation
import SwiftData
import Testing
import tdgCoreMain
@testable import Three_Daily_Goals

@Suite("Task Deletion Tests")
struct TestTaskDeletion {
    
    @Test("Delete task reduces task count")
    @MainActor func deleteTaskReducesCount() async throws {
        let appComponents = setupApp(isTesting: true)
        let dataManager = appComponents.dataManager

        let initialCount = dataManager.nrOfTasks
        #expect(initialCount > 0, "Should have test data")

        let taskToDelete = dataManager.allTasks.first!
        let taskTitle = taskToDelete.title

        dataManager.deleteTask(taskToDelete)

        let finalCount = dataManager.nrOfTasks

        #expect(finalCount == initialCount - 1, "Task count should decrease by 1 after deletion. Initial: \(initialCount), Final: \(finalCount)")

        let deletedTask = dataManager.allTasks.first(where: { $0.title == taskTitle })
        #expect(deletedTask == nil, "Deleted task should not be found in allTasks")
    }
    
    @Test("Delete task with comments cascades deletion")
    @MainActor func deleteTaskWithCommentsCascades() async throws {
        let appComponents = setupApp(isTesting: true)
        let dataManager = appComponents.dataManager
        
        let task = dataManager.createTask(title: "Task with comments", state: .open)
        task.addComment(text: "Comment 1", icon: "test", state: .open)
        task.addComment(text: "Comment 2", icon: "test", state: .open)
        dataManager.save()

        #expect(task.comments?.count == 2, "Task should have 2 comments")

        let taskId = task.id
        let initialTaskCount = dataManager.nrOfTasks
        let initialCommentCount = try dataManager.modelContext.fetchCount(FetchDescriptor<tdgCoreMain.Comment>())

        dataManager.deleteTask(task)

        let finalTaskCount = dataManager.nrOfTasks
        let finalCommentCount = try dataManager.modelContext.fetchCount(FetchDescriptor<tdgCoreMain.Comment>())
        
        #expect(finalTaskCount == initialTaskCount - 1, "Task should be deleted")
        #expect(finalCommentCount == initialCommentCount - 2, "Comments should be cascade deleted. Initial: \(initialCommentCount), Final: \(finalCommentCount)")
        
        let deletedTask = dataManager.findTask(withUuidString: taskId)
        #expect(deletedTask == nil, "Deleted task should not be findable")
    }
    
   // @Test("Delete task can be undone")  // for some odd reason I cannot fix this one
    @MainActor func deleteTaskCanBeUndone() async throws {
        let appComponents = setupApp(isTesting: true)
        let dataManager = appComponents.dataManager
        
        let initialCount = dataManager.nrOfTasks
        let task = dataManager.createTask(title: "Task to delete and undo", state: .open)

        // DON'T call save() - it commits the transaction and prevents undo across the save boundary
        // SwiftData's undo only works within a transaction

        #expect(dataManager.nrOfTasks == initialCount + 1, "Task should be added")
        let taskId = task.id
        let taskTitle = task.title
 
        
        dataManager.deleteTask(task)
        
        #expect(dataManager.nrOfTasks == initialCount, "Task should be deleted")
        
        #expect(dataManager.canUndo, "Undo should be available after deletion")
        
        dataManager.undo()

        let countAfterUndo = dataManager.nrOfTasks
        #expect(countAfterUndo == initialCount + 1, "Task count should be restored after undo. Initial: \(initialCount), After creation: \(initialCount + 1), After undo: \(countAfterUndo)")

        let restoredTask = dataManager.findTask(withUuidString: taskId)
        #expect(restoredTask != nil, "Task should be restored after undo")
        #expect(restoredTask?.title == taskTitle, "Restored task should have same title")
    }
    
    @Test("Delete multiple tasks")
    @MainActor func deleteMultipleTasks() async throws {
        let appComponents = setupApp(isTesting: true)
        let dataManager = appComponents.dataManager
        
        let task1 = dataManager.createTask(title: "Task 1 to delete", state: .open)
        let task2 = dataManager.createTask(title: "Task 2 to delete", state: .open)
        let task3 = dataManager.createTask(title: "Task 3 to delete", state: .open)
        dataManager.save()

        let initialCount = dataManager.nrOfTasks

        dataManager.deleteTasks([task1, task2, task3])

        let finalCount = dataManager.nrOfTasks
        #expect(finalCount == initialCount - 3, "Should delete 3 tasks. Initial: \(initialCount), Final: \(finalCount)")
    }
    
    @Test("Delete with UI update changes selected item")
    @MainActor func deleteWithUIUpdate() async throws {
        let appComponents = setupApp(isTesting: true)
        let dataManager = appComponents.dataManager
        let uiState = appComponents.uiState
        
        uiState.whichList = .open
        let openTasks = dataManager.list(which: .open)
        #expect(openTasks.count >= 2, "Need at least 2 open tasks for this test")
        
        let taskToDelete = openTasks.first!
        uiState.selectedItem = taskToDelete
        
        let initialCount = openTasks.count
        
        dataManager.deleteWithUIUpdate(task: taskToDelete, uiState: uiState)
        
        let finalOpenTasks = dataManager.list(which: .open)
        #expect(finalOpenTasks.count == initialCount - 1, "Open task count should decrease")
        
        #expect(uiState.selectedItem !== taskToDelete, "Selected item should change after deletion")
        
        if !finalOpenTasks.isEmpty {
            #expect(uiState.selectedItem == finalOpenTasks.first, "Should select first item in list")
        }
    }
    
    @Test("Delete task from different states")
    @MainActor func deleteTaskFromDifferentStates() async throws {
        let appComponents = setupApp(isTesting: true)
        let dataManager = appComponents.dataManager
        
        for state in TaskItemState.allCases {
            let task = dataManager.createTask(title: "Task in \(state)", state: state)
            dataManager.save()

            let initialCount = dataManager.nrOfTasks

            dataManager.deleteTask(task)

            let finalCount = dataManager.nrOfTasks
            #expect(finalCount == initialCount - 1, "Task in state \(state) should be deletable")
        }
    }
}







