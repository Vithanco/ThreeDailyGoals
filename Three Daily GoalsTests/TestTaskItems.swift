//
//  TestTaskItems.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 13/02/2024.
//

import Foundation
import Testing

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
        #expect(task.changed < getDate(daysPrior: 30))
        dataManager.touchWithDescriptionAndUpdateUndoStatus(task: task, description: "Test touch")
        #expect(task.changed > getDate(daysPrior: 1))
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
}
