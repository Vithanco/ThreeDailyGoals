//
//  Three_Daily_GoalsTests.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import XCTest
@testable import Three_Daily_Goals
import SwiftData

final class Three_Daily_GoalsTests: XCTestCase {
    
    var model : TaskManagerViewModel!
    var context : ModelContext!
    
    @MainActor override func setUpWithError() throws {
        context = sharedModelContainer(inMemory: true).mainContext
        model = TaskManagerViewModel(modelContext: context, preferences: CloudPreferences(testData: true), isTesting: true)
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
        
        let descriptor = FetchDescriptor<Comment>()
        XCTAssertTrue(model.hasUndoManager)
        XCTAssertFalse(model.canUndo)
        XCTAssertFalse(model.canRedo)
        model.beginUndoGrouping()
        let item = model.addAndSelect()
        XCTAssertEqual(item.comments!.count, 0, "No comments yet")
        XCTAssertEqual(0,try context.fetchCount(descriptor))
        model.touch(task: item)
        model.endUndoGrouping()
        XCTAssertEqual(item.comments!.count, 1, "touch leads to comment")
        XCTAssertEqual(1,try context.fetchCount(descriptor))
        
        
        XCTAssertTrue(model.canUndo)
//        XCTAssertEqual(model.canUndo, model.undo)
        XCTAssertFalse(model.canRedo)
        XCTAssertEqual(item, model.findTask(withID: item.id))
        while model.canUndo {
            model.undo()
        }
        XCTAssertFalse(model.canUndo)
        XCTAssertTrue(model.canRedo)
        XCTAssertNil(model.findTask(withID: item.id), "item was deleted")
        XCTAssertEqual(0,try context.fetchCount(descriptor))
        while model.canRedo {
            model.redo()
        }
        XCTAssertTrue(model.canUndo)
        XCTAssertFalse(model.canRedo)
        let find = model.findTask(withID: item.id)
        XCTAssertNotNil(find)
        XCTAssertEqual(item, find )
        XCTAssertEqual(find!.comments!.count, 1, "Comment should be recreated, too")
        XCTAssertEqual(1,try context.fetchCount(descriptor))
        
        //delete
        model.delete(task: item)
        XCTAssertTrue(model.canUndo)
        XCTAssertFalse(model.canRedo)
        let find2 = model.findTask(withID: item.id)
        XCTAssertNil(find2)
        XCTAssertEqual(0,try context.fetchCount(descriptor))
//        while model.canUndo {
            model.undo()
//        }
        XCTAssertTrue(model.canUndo)
        XCTAssertTrue(model.canRedo)
        
        let find3 = model.findTask(withID: item.id)        
        XCTAssertEqual(find3!, model.findTask(withID: item.id))
        XCTAssertEqual(find3!.comments!.count, 1)
        XCTAssertEqual(1,try context.fetchCount(descriptor))
    }
    
    func testTaskITemID() throws {
        let task1 = model.addAndSelect()
        let task2 = model.addAndSelect()
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
