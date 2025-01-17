//
//  TestModelLists.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 10/01/2024.
//

import XCTest
@testable import Three_Daily_Goals

extension Dictionary where Value : Numeric {
    var total: Value {
        var result = Value.zero
        for key in keys {
            result += self[key] ?? .zero
        }
        return result
    }
}

final class TestModelLists: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testNewItem () throws {
        let model = dummyViewModel()
        let new = model.addAndSelect()
        XCTAssertEqual(new.state, .open)
    }
    
    @MainActor
    func testLists() throws {
        
        let model = dummyViewModel()
        XCTAssertEqual(180, model.items.count)
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
    

    
    @MainActor
    func testTags() throws {
        let testTag = "aTestTag34"
        let testTag2 = "aTestTag346"
        XCTAssertNotEqual(testTag, testTag2)
        
        
        let model = dummyViewModel()
        XCTAssertTrue(model.allTags.contains("private"))
        XCTAssertTrue(model.allTags.contains("work"))
        XCTAssertTrue(model.activeTags.contains("private"))
        XCTAssertTrue(model.activeTags.contains("work"))
        
        model.list(which: .open).first?.tags.append(testTag)
        XCTAssertTrue(model.activeTags.contains(testTag))
        XCTAssertTrue(model.allTags.contains(testTag))
        
        let deadTask = model.list(which: .dead).first!
        XCTAssertFalse(deadTask.isActive)
        deadTask.tags.append(testTag2)
        
        let stats = model.statsForTags(tag: testTag2)
        XCTAssertEqual(stats.total, 1, stats.debugDescription)
        
        
        XCTAssertFalse(model.activeTags.contains(testTag2))
        XCTAssertTrue(model.allTags.contains(testTag2))
        
        model.delete(tag: testTag2)
        
        XCTAssertFalse(model.activeTags.contains(testTag2))
        XCTAssertFalse(model.allTags.contains(testTag2))
        
        model.delete(tag: "private")
        
        XCTAssertTrue(model.allTags.contains("private"))
        XCTAssertTrue(model.activeTags.contains("private"))
    }
}
