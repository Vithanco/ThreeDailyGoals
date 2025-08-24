//
//  TestModelLists.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 10/01/2024.
//

import Foundation
import Testing

@testable import Three_Daily_Goals

extension Dictionary where Value: Numeric {
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
    func testNewItem() throws {
        let model = dummyViewModel()
        let new = model.addAndSelect()
        #expect(new.state == .open)
    }

    @MainActor
    @Test
    func testLists() throws {

        let model = dummyViewModel()
        #expect(178 == model.dataManager.items.count)
        let item = model.dataManager.items.first!

        func move(from: TaskItemState, to: TaskItemState) {
            model.move(task: item, to: to)
            #expect(item.state == to)
                    #expect(model.dataManager.list(which: to).contains(item))
        #expect(!model.dataManager.list(which: from).contains(item))
        }

        #expect(item.state == TaskItemState.open)
        #expect(model.dataManager.list(which: .open).contains(item))

        move(from: .open, to: .closed)
        move(from: .closed, to: .pendingResponse)
        move(from: .pendingResponse, to: .dead)
        move(from: .dead, to: .priority)
        move(from: .priority, to: .open)
    }

    @MainActor
    @Test
    func testTags() async throws {
        let testTag = "aTestTag34"
        let testTag2 = "aTestTag346"
        #expect(testTag != testTag2)

        let model = dummyViewModel()
        #expect(model.dataManager.items.count == 178)
        #expect(model.dataManager.allTags.contains("private"))
        #expect(model.dataManager.allTags.contains("work"))
        #expect(model.dataManager.activeTags.contains("private"))
        #expect(model.dataManager.activeTags.contains("work"))

        #expect(model.dataManager.list(which: .open).first != nil)
        if let first = model.dataManager.list(which: .open).first {
            #expect(model.dataManager.list(which: .open).contains(first))
            #expect(model.dataManager.items.contains(first))
            first.addTag(testTag)
            #expect(first.tags.contains(testTag))
            #expect(first.isActive)
            #expect(first.state == .open)
        }
        #expect(model.dataManager.list(which: .open).tags.contains(testTag))
        #expect(model.dataManager.list(which: .open).activeTags.contains(testTag))

        #expect(model.dataManager.activeTags.contains(testTag))
        #expect(model.dataManager.allTags.contains(testTag))

        let deadTask = model.dataManager.list(which: .dead).first!
        #expect(!deadTask.isActive)
        deadTask.addTag(testTag2)

        let stats = model.dataManager.statsForTags(tag: testTag2)
        #expect(stats.total == 1, "\(stats.debugDescription)")

        #expect(!model.dataManager.activeTags.contains(testTag2))
        #expect(model.dataManager.allTags.contains(testTag2))

        model.dataManager.delete(tag: testTag2)

        #expect(!model.dataManager.activeTags.contains(testTag2))
        #expect(!model.dataManager.allTags.contains(testTag2))

        model.dataManager.delete(tag: "private")

        #expect(model.dataManager.allTags.contains("private"))
        #expect(model.dataManager.activeTags.contains("private"))
    }

    @MainActor
    @Test
    func testDueDate() async throws {
        let model = dummyViewModel(loader: {
            var result: [TaskItem] = []
            let theGoal = result.add(
                title: "Read 'The Goal' by Goldratt",
                changedDate: Date.now.addingTimeInterval(-1 * Seconds.fiveMin))
            theGoal.details =
                "It is the book that introduced the fundamentals for 'Theory of Constraints'"
            theGoal.url = "https://www.goodreads.com/book/show/113934.The_Goal"
            theGoal.dueDate = getDate(inDays: 2)
            return result
        })

        #expect(model.dueDateSoon.count == 1)
        #expect(model.dueDateSoon[0].title == "Read 'The Goal' by Goldratt")

        model.moveStateForward()
        #expect(model.dueDateSoon.count == 1)

        model.moveStateForward()
        #expect(model.stateOfCompassCheck == .review)
        #expect(model.dueDateSoon.count == 1)
        model.moveStateForward()
        #expect(model.dueDateSoon.count == 1)
        model.moveStateForward()
        #expect(model.dueDateSoon.count == 1)

    }
}
