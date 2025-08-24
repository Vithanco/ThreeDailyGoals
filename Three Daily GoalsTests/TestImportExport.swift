//
//  TestImportExport.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 19/02/2024.
//

import Foundation
import Testing

@testable import Three_Daily_Goals

@Suite
struct TestImportExport {

    @Test
    func testDateEncoding() throws {
        let encoder = JSONEncoder()
        let original = Date.now
        let encoded = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Date.self, from: encoded)
        #expect(original == decoded)
    }

    @Test
    func testTaskItemEncoding() throws {
        let encoder = JSONEncoder()
        let original = TaskItem(title: "test")
        let id = original.id
        let encoded = try encoder.encode(original)
        debugPrint(encoded)

        let decoder = JSONDecoder()
        let decoded: TaskItem = try decoder.decode(TaskItem.self, from: encoded)
        #expect(original == decoded)
        #expect(original.title == decoded.title)
        #expect(original.id == decoded.id)
        #expect(original.created == decoded.created)

        #expect(original.changed == decoded.changed)

        #expect(original.details == decoded.details)
        #expect(original.dueDate == decoded.dueDate)
        #expect(original.comments == decoded.comments)
        #expect(original.state == decoded.state)
        #expect(original.url == decoded.url)
        #expect(original.id == id)
    }

    @MainActor
    @Test
    func testFile() throws {
        let model = dummyViewModel()
        let count = model.dataManager.items.count
        #expect(count > 0)
        let url = getDocumentsDirectory().appendingPathComponent("taskItems-test.json")
        model.exportTasks(url: url)
        #expect(model.dataManager.items.count == count)
        guard let first = model.dataManager.items.first else {
            #expect(false); return
        }
        #expect(first == model.findTask(withID: first.id))
        let newModel = dummyViewModel(loader: { return [] })
        #expect(0 == newModel.dataManager.items.count)
        newModel.importTasks(url: url)

        #expect(first == newModel.findTask(withID: first.id))
        #expect(model.dataManager.items.count == newModel.dataManager.items.count)
        #expect(178 == newModel.dataManager.items.count)
        for item in model.dataManager.items {
            debugPrint(item)
            #expect(model.findTask(withID: item.id) != nil)
            guard let newItem = newModel.findTask(withID: item.id) else {
                #expect (false)
                return
            }
            #expect(item == newItem)
            #expect(item.title == newItem.title)
            #expect(item.id == newItem.id)
            #expect(item.created == newItem.created)
            #expect(item.details == newItem.details)
            if let comments = item.comments {
                #expect(item.comments!.count == newItem.comments!.count)
                for comment in comments {
                    let newComment = newItem.comments!.first(where: { $0.id == comment.id })!
                    #expect(comment.text == newComment.text)
                    #expect(comment.created == newComment.created)
                }

            }
        }
    }

}
