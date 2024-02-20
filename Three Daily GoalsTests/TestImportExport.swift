//
//  TestImportExport.swift
//  Three Daily GoalsTests
//
//  Created by Klaus Kneupner on 19/02/2024.
//

import XCTest
@testable import Three_Daily_Goals

final class TestImportExport: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testDateEncoding () throws {
        let encoder = JSONEncoder()
        let original = Date.now
        let encoded = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Date.self, from: encoded)
        XCTAssertEqual(original, decoded)
    }
    
    
    func testTaskItemEncoding () throws {
        let encoder = JSONEncoder()
        let original = TaskItem(title: "test")
        let id = original.id
        let encoded = try encoder.encode(original)
        debugPrint(encoded)
        sleep(1)
        let decoder = JSONDecoder()
        let decoded: TaskItem = try decoder.decode(TaskItem.self, from: encoded)
        XCTAssertEqual(original, decoded)
        XCTAssertEqual(original.title, decoded.title)
        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.created, decoded.created)
        
        XCTAssertEqual(original.changed, decoded.changed)
        
        XCTAssertEqual(original.details, decoded.details)
        XCTAssertEqual(original.dueDate, decoded.dueDate)
        XCTAssertEqual(original.comments, decoded.comments)
        XCTAssertEqual(original.state, decoded.state)
        XCTAssertEqual(original.url, decoded.url)
        XCTAssertEqual(original.id, id)
    }
    
    func testFile() throws {
        let model = dummyViewModel()
        let url = getDocumentsDirectory().appendingPathComponent("taskItems.json")
        model.exportTasks(url: url)
        let first = model.items.first!
        XCTAssertEqual(first, model.findTask(withID: first.id))
        let newModel = dummyViewModel(loader: {return []})
        XCTAssertEqual(0, newModel.items.count)
        newModel.importTasks(url: url)
        
        XCTAssertEqual(first, newModel.findTask(withID: first.id))
        XCTAssertEqual(model.items.count, newModel.items.count)
        XCTAssertEqual(8, newModel.items.count)
        for item in model.items {
            debugPrint(item)
            XCTAssertNotNil(model.findTask(withID: item.id))
            let newItem = newModel.findTask(withID: item.id)!
            XCTAssertEqual(item, newItem)
            XCTAssertEqual(item.title, newItem.title)
            XCTAssertEqual(item.id, newItem.id)
            XCTAssertEqual(item.created, newItem.created)
            XCTAssertEqual(item.details, newItem.details)
            if let comments = item.comments {
                XCTAssertEqual(item.comments!.count, newItem.comments!.count)
                for comment in comments {
                    let newComment = newItem.comments!.first(where: {$0.id == comment.id})!
                    XCTAssertEqual(comment.text, newComment.text)
                    XCTAssertEqual(comment.created, newComment.created)
                }
                
            }
        }
    }
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

