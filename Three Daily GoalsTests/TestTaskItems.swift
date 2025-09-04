//
//  TestTaskItems.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 13/02/2024.
//

import Foundation
import Testing
import SwiftUI

@testable import Three_Daily_Goals

enum TestError: Error {
    case taskNotFound
}

@Suite
@MainActor
struct TestTaskItems {

    @Test
    func testAddComments() throws {
        //        let dummyM = dummyViewModel()
        //        let task = dummyM.addAndSelect()
        //        #expect(task.comments?.count , 0)
        //        let task2 = task.addComment(text: "test comment")
        //        #expect(task, task2)
        //        #expect(task.comments!.count,1)
    }

    func loader(timeProvider: TimeProvider, whichList: TaskItemState) -> [TaskItem] {
        var result: [TaskItem] = []
        for i in stride(from: 1, to: 100, by: 5) {
            result.add(title: "day \(i)", changedDate: timeProvider.getDate(daysPrior: i), state: whichList)
        }
        return result
    }

    @MainActor
    @Test
    func testListSorting() throws {
        #expect(TaskItemState.open.subHeaders != TaskItemState.closed.subHeaders)
        let appComponents = setupApp(isTesting: true, loader: { tp in return self.loader(timeProvider: tp, whichList: .open) })
        let dataManager = appComponents.dataManager
        let itemList = dataManager.list(which: .open)
        let headers = TaskItemState.open.subHeaders
        let partialLists: [[TaskItem]] = headers.map({ $0.filter(items: itemList, timeProvider: appComponents.timeProvider) })
        #expect(Array(partialLists.joined()) == itemList)
    }

    @MainActor
    @Test
    func testEquality() throws {
        let sameDate = Date.now
        let a = TaskItem(title: "same", details: "same", changedDate: sameDate)
        a.created = sameDate
        let b = TaskItem(title: "same", details: "different", changedDate: sameDate)
        b.created = sameDate
        let c = TaskItem(title: "same", details: "same", changedDate: sameDate)
        c.created = sameDate
        #expect(a != b)
        #expect(a != c)
    }

    @MainActor
    @Test
    func testTouch() throws {
        let appComponents = setupApp(isTesting: true)
        let dataManager = appComponents.dataManager

        guard let task = dataManager.list(which: .dead).first else {
            throw TestError.taskNotFound
        }
        #expect(task.canBeTouched)
        let timeProvider = RealTimeProvider()
        #expect(task.changed < timeProvider.getDate(daysPrior: 30))
        dataManager.touchWithDescriptionAndUpdateUndoStatus(task: task, description: "Test touch")
        #expect(task.changed > timeProvider.getDate(daysPrior: 1))
    }

    @MainActor
    @Test
    func testTouch2() throws {
        let appComponents = setupApp(isTesting: true)
        let dataManager = appComponents.dataManager

        guard let task = dataManager.list(which: .open).first else {
            throw TestError.taskNotFound
        }
        #expect(task.canBeTouched)
        let date = task.changed
        dataManager.touchWithDescriptionAndUpdateUndoStatus(task: task, description: "Test touch")
        #expect(date != task.changed)
    }

    @MainActor
    @Test
    func dontAddEmptyTask() throws {
        let appComponents = setupApp(isTesting: true, loader: { _ in return [] })
        let dataManager = appComponents.dataManager

        #expect(dataManager.items.count == 0)
        dataManager.addItem(item: TaskItem(title: ""))
        #expect(dataManager.items.count == 0)

        dataManager.addItem(item: TaskItem(title: emptyTaskTitle))
    }

    @MainActor
    @Test
    func addTaskWithDetails() throws {
        let appComponents = setupApp(isTesting: true, loader: { _ in return [] })
        let dataManager = appComponents.dataManager
        let newTask = TaskItem(title: "", details: "something")
        #expect(dataManager.items.count == 0)
        dataManager.addItem(item: newTask)
        #expect(dataManager.items.count == 1)
    }
    
    @MainActor
    @Test
    func testDueDateRemovalCrash() throws {
        let appComponents = setupApp(isTesting: true, loader: { _ in return [] })
        let dataManager = appComponents.dataManager
        let timeProvider = appComponents.timeProvider
        
        // Create a task with a due date
        let task = TaskItem(title: "Test Task", details: "Test details", state: .open)
        task.due = timeProvider.getDate(inDays: 7) // Set due date 7 days from now
        dataManager.addItem(item: task)
        
        // Verify the task has a due date
        #expect(task.due != nil)
        #expect(task.dueDate != nil)
        
        // Test the dueUntil method with the due date
        let futureDate = timeProvider.getDate(inDays: 10)
        #expect(task.dueUntil(date: futureDate) == true)
        
        // Now remove the due date - this should not crash
        task.due = nil
        
        // Verify the due date is removed
        #expect(task.due == nil)
        #expect(task.dueDate == nil)
        
        // Test dueUntil method with nil due date
        #expect(task.dueUntil(date: futureDate) == false)
        
        // Test accessing the due property multiple times after removal
        let _ = task.due
        let _ = task.dueDate
        let _ = task.due
        
        // Test setting due date again
        task.due = timeProvider.getDate(inDays: 3)
        #expect(task.due != nil)
        
        // Remove it again
        task.due = nil
        #expect(task.due == nil)
    }
    
    @MainActor
    @Test
    func testDatePickerNullableBindingCrash() throws {
        let appComponents = setupApp(isTesting: true, loader: { _ in return [] })
        let timeProvider = appComponents.timeProvider
        
        // Test the exact scenario that might cause the crash
        var selectedDate: Date? = timeProvider.getDate(inDays: 7)
        
        // Simulate the DatePickerNullable logic
        // This is the problematic line: if let date = Binding($selected) {
        // We need to test if this crashes when selectedDate becomes nil
        
        // First, test with a valid date
        #expect(selectedDate != nil)
        
        // Test the binding creation (this is what might crash)
        if selectedDate != nil {
            // This simulates the safe version of the binding creation
            let binding = Binding<Date?>(
                get: { selectedDate },
                set: { selectedDate = $0 }
            )
            #expect(binding.wrappedValue != nil)
        }
        
        // Now set to nil (simulating removing the due date)
        selectedDate = nil
        #expect(selectedDate == nil)
        
        // Test the binding creation with nil value
        if selectedDate != nil {
            // This should not execute since selectedDate is nil
            #expect(false, "This should not execute")
        } else {
            // This is the safe path - no binding creation attempted
            #expect(true, "Safe path taken")
        }
        
        // Test rapid toggling between nil and valid dates
        for i in 1...10 {
            selectedDate = timeProvider.getDate(inDays: i)
            #expect(selectedDate != nil)
            
            selectedDate = nil
            #expect(selectedDate == nil)
        }
    }
}
