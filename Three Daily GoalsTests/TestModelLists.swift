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

    func testNewItem () throws {
        let model = dummyViewModel()
        let new = model.addItem()
        XCTAssertEqual(new.state, .open)
    }
    
    func testLists() throws {
        
        let model = dummyViewModel()
        XCTAssertEqual(8, model.items.count)
        let item = model.items.first!
        
        
        func move(from: TaskItemState, to: TaskItemState) {
            model.move(task: item, to: to)
            XCTAssertEqual(item.state, to)
            XCTAssertTrue(model.lists[to]!.contains(item))
            XCTAssertFalse(model.lists[from]!.contains(item))
        }
        
        XCTAssertEqual(item.state, .open)
        XCTAssertTrue(model.lists[.open]!.contains(item))
        
        move(from: .open, to: .closed)
        move(from: .closed, to: .pendingResponse)
        move(from: .pendingResponse, to: .dead)
        move(from: .dead, to: .priority)
        move(from: .priority, to: .open)
    }

  
}
