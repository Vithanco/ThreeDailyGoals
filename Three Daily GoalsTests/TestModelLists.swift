//
//  TestModelLists.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 10/01/2024.
//

import Testing
@testable import Three_Daily_Goals
import Foundation

extension Dictionary where Value : Numeric {
    var total: Value {
        var result = Value.zero
        for key in keys {
            result += self[key] ?? .zero
        }
        return result
    }
}

@Suite
struct TestModelLists {

    @MainActor
    @Test
    func testNewItem () throws {
        let model = dummyViewModel()
        let new = model.addAndSelect()
        #expect(new.state == .open)
    }
    
    @MainActor
    @Test
    func testLists() throws {
        
        let model = dummyViewModel()
        #expect(178 == model.items.count)
        let item = model.items.first!
        
        
        func move(from: TaskItemState, to: TaskItemState) {
            model.move(task: item, to: to)
            #expect(item.state == to)
            #expect(model.lists[to]!.contains(item))
            #expect(!model.lists[from]!.contains(item))
        }
        
        #expect(item.state == .open)
        #expect(model.lists[.open]!.contains(item))
        
        move(from: .open, to: .closed)
        move(from: .closed, to: .pendingResponse)
        move(from: .pendingResponse, to: .dead)
        move(from: .dead, to: .priority)
        move(from: .priority, to: .open)
    }
    

    
    @MainActor
    @Test
    func testTags() throws {
        let testTag = "aTestTag34"
        let testTag2 = "aTestTag346"
        #expect(testTag != testTag2)
        
        
        let model = dummyViewModel()
        #expect(model.allTags.contains("private"))
        #expect(model.allTags.contains("work"))
        #expect(model.activeTags.contains("private"))
        #expect(model.activeTags.contains("work"))
        
        model.list(which: .open).first?.tags.append(testTag)
        #expect(model.activeTags.contains(testTag))
        #expect(model.allTags.contains(testTag))
        
        let deadTask = model.list(which: .dead).first!
        #expect(!deadTask.isActive)
        deadTask.tags.append(testTag2)
        
        let stats = model.statsForTags(tag: testTag2)
        #expect(stats.total == 1, "\(stats.debugDescription)")
        
        
        #expect(!model.activeTags.contains(testTag2))
        #expect(model.allTags.contains(testTag2))
        
        model.delete(tag: testTag2)
        
        #expect(!model.activeTags.contains(testTag2))
        #expect(!model.allTags.contains(testTag2))
        
        model.delete(tag: "private")
        
        #expect(model.allTags.contains("private"))
        #expect(model.activeTags.contains("private"))
    }
}
