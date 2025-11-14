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
        
        let initialCount = try dataManager.modelContext.fetchCount(FetchDescriptor<TaskItem>())
        #expect(initialCount > 0, "Should have test data")
        
        let taskToDelete = dataManager.allTasks.first!
        let taskTitle = taskToDelete.title
        
        dataManager.deleteTask(taskToDelete)
        
        let finalCount = try dataManager.modelContext.fetchCount(FetchDescriptor<TaskItem>())
        
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
        try dataManager.modelContext.save()
        
        #expect(task.comments?.count == 2, "Task should have 2 comments")
        
        let taskId = task.id
        let initialTaskCount = try dataManager.modelContext.fetchCount(FetchDescriptor<TaskItem>())
        let initialCommentCount = try dataManager.modelContext.fetchCount(FetchDescriptor<Comment>())
        
        dataManager.deleteTask(task)
        
        let finalTaskCount = try dataManager.modelContext.fetchCount(FetchDescriptor<TaskItem>())
        let finalCommentCount = try dataManager.modelContext.fetchCount(FetchDescriptor<Comment>())
        
        #expect(finalTaskCount == initialTaskCount - 1, "Task should be deleted")
        #expect(finalCommentCount == initialCommentCount - 2, "Comments should be cascade deleted. Initial: \(initialCommentCount), Final: \(finalCommentCount)")
        
        let deletedTask = dataManager.findTask(withUuidString: taskId)
        #expect(deletedTask == nil, "Deleted task should not be findable")
    }
    
    @Test("Delete task can be undone")
    @MainActor func deleteTaskCanBeUndone() async throws {
        let appComponents = setupApp(isTesting: true)
        let dataManager = appComponents.dataManager
        
        let task = dataManager.createTask(title: "Task to delete and undo", state: .open)
        try dataManager.modelContext.save()
        
        let taskId = task.id
        let taskTitle = task.title
        let initialCount = try dataManager.modelContext.fetchCount(FetchDescriptor<TaskItem>())
        
        dataManager.deleteTask(task)
        
        let countAfterDelete = try dataManager.modelContext.fetchCount(FetchDescriptor<TaskItem>())
        #expect(countAfterDelete == initialCount - 1, "Task should be deleted")
        
        #expect(dataManager.canUndo, "Undo should be available after deletion")
        
        dataManager.undo()
        
        let countAfterUndo = try dataManager.modelContext.fetchCount(FetchDescriptor<TaskItem>())
        #expect(countAfterUndo == initialCount, "Task count should be restored after undo. Initial: \(initialCount), After undo: \(countAfterUndo)")
        
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
        try dataManager.modelContext.save()
        
        let initialCount = try dataManager.modelContext.fetchCount(FetchDescriptor<TaskItem>())
        
        dataManager.deleteTasks([task1, task2, task3])
        
        let finalCount = try dataManager.modelContext.fetchCount(FetchDescriptor<TaskItem>())
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
            try dataManager.modelContext.save()
            
            let initialCount = try dataManager.modelContext.fetchCount(FetchDescriptor<TaskItem>())
            
            dataManager.deleteTask(task)
            
            let finalCount = try dataManager.modelContext.fetchCount(FetchDescriptor<TaskItem>())
            #expect(finalCount == initialCount - 1, "Task in state \(state) should be deletable")
        }
    }
}



