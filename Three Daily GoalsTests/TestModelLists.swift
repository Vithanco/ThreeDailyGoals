//
//  TestModelLists.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 10/01/2024.
//

import XCTest
@testable import Three_Daily_Goals

final class TestModelLists: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLists() throws {
        
        let model = dummyViewModel()
        
        XCTAssertEqual(6, model.items.count)
        let item = model.items.first!
        XCTAssertEqual(item.state, .open)
        XCTAssertTrue(model.openTasks.contains(item))
        model.move(task: item, to: .closed)
        XCTAssertEqual(item.state, .closed)
        XCTAssertTrue(model.closedTasks.contains(item))
        XCTAssertFalse(model.openTasks.contains(item))
        model.move(task: item, to: .pendingResponse)
        XCTAssertEqual(item.state, .pendingResponse)
        XCTAssertTrue(model.pendingTasks.contains(item))
        XCTAssertFalse(model.closedTasks.contains(item))
        
        model.move(task: item, to: .dead)
        XCTAssertEqual(item.state, .dead)
        XCTAssertTrue(model.deadTasks.contains(item))
        XCTAssertFalse(model.pendingTasks.contains(item))
        
        model.move(task: item, to: .dead)
        XCTAssertEqual(item.state, .dead)
        XCTAssertTrue(model.deadTasks.contains(item))
        XCTAssertFalse(model.pendingTasks.contains(item))
        
        model.move(task: item, to: .priority)
        XCTAssertEqual(item.state, .priority)
        XCTAssertTrue(model.priorityTasks.contains(item))
        XCTAssertFalse(model.deadTasks.contains(item))
    }


}
