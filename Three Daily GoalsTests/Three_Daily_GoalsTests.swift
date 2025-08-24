//
//  Three_Daily_GoalsTests.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import Foundation
import SwiftData
import XCTest

@testable import Three_Daily_Goals

//@Suite
@MainActor
struct Three_Daily_GoalsTests {

    var model: TaskManagerViewModel!
    var context: ModelContext!

    init() {
        context = sharedModelContainer(inMemory: true, withCloud: false).mainContext
        model = TaskManagerViewModel(
            modelContext: context, 
            preferences: CloudPreferences(testData: true), 
            uiState: UIStateManager(),
            isTesting: true)
    }

    // @Test
    func testDoubleStringConversation() throws {
        let double = Date.now.timeIntervalSince1970
        let string = double.description
        let again = Double(string)
        XCTAssertTrue(double == again)
    }

    //  @Test
    func testTaskUndo() async throws {
        while !model.dataManager.hasUndoManager {
            await Task.yield()
        }

        //        let descriptor = FetchDescriptor<Comment>()
        XCTAssertTrue(model.dataManager.hasUndoManager)
        XCTAssertTrue(!model.canUndo)
        XCTAssertTrue(!model.canRedo)
        model.dataManager.beginUndoGrouping()
        let item = model.addAndSelect()
        //        #expect(item.comments!.count, 0, "No comments yet")
        //        #expect(0,try context.fetchCount(descriptor))
        model.touch(task: item)
        model.dataManager.endUndoGrouping()
        //        #expect(item.comments!.count, 1, "touch leads to comment")
        //        #expect(1,try context.fetchCount(descriptor))

        XCTAssertTrue(model.canUndo)
        //        #expect(model.canUndo, model.undo)
        XCTAssertTrue(!model.canRedo)
        XCTAssertTrue(item == model.dataManager.findTask(withUuidString: item.id))
        while model.canUndo {
            model.dataManager.undo()
        }
        XCTAssertTrue(!model.canUndo)
        XCTAssertTrue(model.canRedo)
        XCTAssertTrue(model.dataManager.findTask(withUuidString: item.id) == nil, "item was deleted")
        //        #expect(0,try context.fetchCount(descriptor))
        while model.canRedo {
            model.dataManager.redo()
        }
        XCTAssertTrue(model.canUndo)
        XCTAssertTrue(!model.canRedo)
        let find = model.dataManager.findTask(withUuidString: item.id)
        XCTAssertTrue(find != nil)
        XCTAssertTrue(item == find)
        //        #expect(find!.comments!.count, 1, "Comment should be recreated, too")
        //        #expect(1,try context.fetchCount(descriptor))

        //delete
        model.delete(task: item)
        XCTAssertTrue(model.canUndo)
        XCTAssertTrue(!model.canRedo)
        let find2 = model.dataManager.findTask(withUuidString: item.id)
        XCTAssertTrue(find2 == nil)
        //        #expect(0,try context.fetchCount(descriptor))
        //        while model.canUndo {
        model.dataManager.undo()
        //        }
        XCTAssertTrue(model.canUndo)
        XCTAssertTrue(model.canRedo)

        let find3 = model.dataManager.findTask(withUuidString: item.id)
        XCTAssertTrue(find3 == model.dataManager.findTask(withUuidString: item.id))
        //        #expect(find3!.comments!.count, 1)
        //        #expect(1,try context.fetchCount(descriptor))
    }

    //  @Test
    func testTaskITemID() throws {
        let task1 = model.addAndSelect()
        let task2 = model.addAndSelect()
        XCTAssertTrue(task1.id != task2.id)

        let id1 = task1.id
        let id2 = task2.id

        XCTAssertTrue(task1 == model.dataManager.findTask(withUuidString: id1))
        XCTAssertTrue(task2 == model.dataManager.findTask(withUuidString: id2))
        XCTAssertTrue(model.dataManager.findTask(withUuidString: UUID().uuidString) == nil)
    }

    //    func testPerformanceExample() throws {
    //        // This is an example of a performance test case.
    //        measure {
    //            // Put the code you want to measure the time of here.
    //        }
    //    }

}
