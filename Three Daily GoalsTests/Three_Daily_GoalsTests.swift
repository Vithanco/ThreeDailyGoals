//
//  Three_Daily_GoalsTests.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import Testing
@testable import Three_Daily_Goals
import SwiftData
import Foundation

@Suite
@MainActor
struct Three_Daily_GoalsTests {
    
    var model : TaskManagerViewModel!
    var context : ModelContext!
    
    
    init(){
        context = sharedModelContainer(inMemory: true).mainContext
        model = TaskManagerViewModel(modelContext: context, preferences: CloudPreferences(testData: true), isTesting: true)
    }
    
    @Test
    func testDoubleStringConversation () throws {
        let double = Date.now.timeIntervalSince1970
        let string = double.description
        let again = Double(string)
        #expect(double == again)
    }
    
    @Test
    func testTaskUndo() async throws {
        while !model.hasUndoManager {
            await Task.yield()
        }
        
//        let descriptor = FetchDescriptor<Comment>()
        #expect(model.hasUndoManager)
        #expect(!model.canUndo)
        #expect(!model.canRedo)
        model.beginUndoGrouping()
        let item = model.addAndSelect()
//        #expect(item.comments!.count, 0, "No comments yet")
//        #expect(0,try context.fetchCount(descriptor))
        model.touch(task: item)
        model.endUndoGrouping()
//        #expect(item.comments!.count, 1, "touch leads to comment")
//        #expect(1,try context.fetchCount(descriptor))
        
        
        #expect(model.canUndo)
//        #expect(model.canUndo, model.undo)
        #expect(!model.canRedo)
        #expect(item == model.findTask(withID: item.id))
        while model.canUndo {
            model.undo()
        }
        #expect(!model.canUndo)
        #expect(model.canRedo)
        #expect(model.findTask(withID: item.id) == nil, "item was deleted")
//        #expect(0,try context.fetchCount(descriptor))
        while model.canRedo {
            model.redo()
        }
        #expect(model.canUndo)
        #expect(!model.canRedo)
        let find = model.findTask(withID: item.id)
        #expect(find != nil)
        #expect(item == find )
//        #expect(find!.comments!.count, 1, "Comment should be recreated, too")
//        #expect(1,try context.fetchCount(descriptor))
        
        //delete
        model.delete(task: item)
        #expect(model.canUndo)
        #expect(!model.canRedo)
        let find2 = model.findTask(withID: item.id)
        #expect(find2 == nil)
//        #expect(0,try context.fetchCount(descriptor))
//        while model.canUndo {
            model.undo()
//        }
        #expect(model.canUndo)
        #expect(model.canRedo)
        
        let find3 = model.findTask(withID: item.id)        
        #expect(find3 == model.findTask(withID: item.id))
//        #expect(find3!.comments!.count, 1)
//        #expect(1,try context.fetchCount(descriptor))
    }
    
    @Test
    func testTaskITemID() throws {
        let task1 = model.addAndSelect()
        let task2 = model.addAndSelect()
        #expect(task1.id != task2.id)
        
        let id1 = task1.id
        let id2 = task2.id
        
        #expect(task1 == model.findTask(withID: id1))
        #expect(task2 ==  model.findTask(withID: id2))
        #expect(model.findTask(withUuidString: UUID().uuidString) == nil)
    }
    
    
    //    func testPerformanceExample() throws {
    //        // This is an example of a performance test case.
    //        measure {
    //            // Put the code you want to measure the time of here.
    //        }
    //    }
    
}
