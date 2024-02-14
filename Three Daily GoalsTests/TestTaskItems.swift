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
        let task = dummyM.addItem()
        XCTAssertEqual(task.comments?.count , 0)
        let task2 = task.addComment(text: "test comment")
        XCTAssertEqual(task, task2)
        XCTAssertEqual(task.comments!.count,1)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
