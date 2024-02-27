//
//  TestTaskItems.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 13/02/2024.
//

import XCTest
@testable import Three_Daily_Goals

final class TestTaskItems: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAddComments() throws {
        let dummyM = dummyViewModel()
        let task = dummyM.addAndSelect()
        XCTAssertEqual(task.comments?.count , 0)
        let task2 = task.addComment(text: "test comment")
        XCTAssertEqual(task, task2)
        XCTAssertEqual(task.comments!.count,1)
    }
    
    func loader(whichList: TaskItemState) -> [TaskItem] {
        var result : [TaskItem] = []
        for i in stride(from: 1, to: 100, by: 5) {
            result.add(title: "day \(i)", changedDate: getDate(daysPrior: i), state: whichList)
        }
        return result
    }
    
    func testListSorting() throws {
        XCTAssertNotEqual(TaskItemState.open.subHeaders, TaskItemState.closed.subHeaders)
        let dummyM = dummyViewModel(loader: {return self.loader(whichList: .open)})
        let itemList = dummyM.list(which: .open)
        let headers = TaskItemState.open.subHeaders
        let partialLists : [[TaskItem]] = headers.map({$0.filter(items: itemList)})
        XCTAssertEqual(Array(partialLists.joined()), itemList)
    }
    
    func testEquality() throws {
        let sameDate = Date.now
        let a = TaskItem(title: "same",details: "same",changedDate: sameDate)
        a.created = sameDate
        let b = TaskItem(title: "same",details: "different",changedDate: sameDate)
        b.created = sameDate
        let c = TaskItem(title: "same",details: "same",changedDate: sameDate)
        c.created = sameDate
        XCTAssertNotEqual(a,b)
        XCTAssertEqual(a,c)
    }
}
