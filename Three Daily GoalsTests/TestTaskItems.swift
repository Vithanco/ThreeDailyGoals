//
//  TestTaskItems.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 13/02/2024.
//

import Testing
@testable import Three_Daily_Goals
import Foundation

enum TestError: Error {
    case taskNotFound
}

@Suite
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
    
    func loader(whichList: TaskItemState) -> [TaskItem] {
        var result : [TaskItem] = []
        for i in stride(from: 1, to: 100, by: 5) {
            result.add(title: "day \(i)", changedDate: getDate(daysPrior: i), state: whichList)
        }
        return result
    }
    
    @MainActor
    @Test
    func testListSorting() throws {
        #expect(TaskItemState.open.subHeaders != TaskItemState.closed.subHeaders)
        let dummyM = dummyViewModel(loader: {return self.loader(whichList: .open)})
        let itemList = dummyM.list(which: .open)
        let headers = TaskItemState.open.subHeaders
        let partialLists : [[TaskItem]] = headers.map({$0.filter(items: itemList)})
        #expect(Array(partialLists.joined()) == itemList)
    }
    
    @MainActor
    @Test
    func testEquality() throws {
        let sameDate = Date.now
        let a = TaskItem(title: "same",details: "same",changedDate: sameDate)
        a.created = sameDate
        let b = TaskItem(title: "same",details: "different",changedDate: sameDate)
        b.created = sameDate
        let c = TaskItem(title: "same",details: "same",changedDate: sameDate)
        c.created = sameDate
        #expect(a != b)
        #expect(a != c)
    }
    
    @MainActor
    @Test
    func testTouch() throws {
        let store = TestPreferences()
        let pref = CloudPreferences(store: store)
        let model = dummyViewModel( preferences:  pref)
        
        guard let task = model.list(which: .dead).first else {
            throw TestError.taskNotFound
        }
        #expect(task.canBeTouched)
        #expect(task.changed < getDate(daysPrior: 30))
        model.touch(task: task)
        #expect(task.changed > getDate(daysPrior: 1))
    }
    
    @MainActor
    @Test
    func testTouch2() throws {
        let store = TestPreferences()
        let pref = CloudPreferences(store: store)
        let model = dummyViewModel( preferences:  pref)
        
        guard let task = model.list(which: .open).first else {
            throw TestError.taskNotFound
        }
        #expect(task.canBeTouched)
        let date = task.changed
        model.touch(task: task)
        #expect(date != task.changed)
    }
}
