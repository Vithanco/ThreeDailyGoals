//
//  Three_Daily_GoalsTests.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import XCTest
@testable import Three_Daily_Goals

final class Three_Daily_GoalsTests: XCTestCase {
    
    var model : TaskManagerViewModel!
    
    @MainActor override func setUpWithError() throws {
        model = TaskManagerViewModel(modelContext: sharedModelContainer(inMemory: true).mainContext)
    }
    
    override func tearDownWithError() throws {
        model = nil
    }
    
    func testDoubleStringConversation () throws {
        let double = Date.now.timeIntervalSince1970
        let string = double.description
        let again = Double(string)
        XCTAssertEqual(double, again)
    }
    
    func testTaskUndo() async throws {
        while !model.hasUndoManager {
            await Task.yield()
        }
        XCTAssertTrue(model.hasUndoManager)
        XCTAssertFalse(model.canUndo)
        XCTAssertFalse(model.canRedo)
        model.beginUndoGrouping()
        let item = model.addItem()
        XCTAssertEqual(item.comments!.count, 0, "No comments yet")
        item.touch()
        model.endUndoGrouping()
        XCTAssertEqual(item.comments!.count, 1, "touch leads to comment")
        XCTAssertTrue(model.canUndo)
        XCTAssertFalse(model.canRedo)
        XCTAssertEqual(item, model.findTask(withID: item.id))
        model.undo()
        XCTAssertFalse(model.canUndo)
        XCTAssertTrue(model.canRedo)
        XCTAssertNil(model.findTask(withID: item.id), "item was deleted")
        model.redo()
        model.redo()
        XCTAssertTrue(model.canUndo)
        XCTAssertFalse(model.canRedo)
        let find = model.findTask(withID: item.id)
        XCTAssertNotNil(find)
        XCTAssertEqual(item, find )
        XCTAssertEqual(find!.comments!.count, 1, "Comment should be recreated, too")
        
        //delete
        model.delete(task: item)
        XCTAssertTrue(model.canUndo)
        XCTAssertFalse(model.canRedo)
        let find2 = model.findTask(withID: item.id)
        XCTAssertNil(find2)
        model.undo()
        XCTAssertTrue(model.canUndo)
        XCTAssertTrue(model.canRedo)
        
        let find3 = model.findTask(withID: item.id)
        XCTAssertEqual(find3!, model.findTask(withID: item.id))
        XCTAssertEqual(find3!.comments!.count, 1)
    }
    
    func testTaskITemID() throws {
        let task1 = model.addItem()
        let task2 = model.addItem()
        XCTAssertNotEqual(task1.id,task2.id)
        
        let id1 = task1.id
        let id2 = task2.id
        
        XCTAssertEqual(task1, model.findTask(withID: id1))
        XCTAssertEqual(task2, model.findTask(withID: id2))
        XCTAssertNil(model.findTask(withID: "2834"))
    }
    
    
    //    func testPerformanceExample() throws {
    //        // This is an example of a performance test case.
    //        measure {
    //            // Put the code you want to measure the time of here.
    //        }
    //    }
    
}
