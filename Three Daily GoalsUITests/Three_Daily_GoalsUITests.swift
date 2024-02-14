//
//  Three_Daily_GoalsUITests.swift
//  Three Daily GoalsUITests
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import XCTest
@testable import Three_Daily_Goals

func ensureExists(text: String, inApp: XCUIApplication) {
    let predicate = NSPredicate(format: "value CONTAINS '\(text)'")
    let elementQuery = inApp.staticTexts.containing(predicate)
    XCTAssertTrue (elementQuery.count > 0, "couldn't find \(text)")
}


final class Three_Daily_GoalsUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testButtons() throws {
        // UI tests must launch the application that they test.
        let app = launchTestApp()
        XCTAssertTrue(app.buttons["Add Task"] .exists)
        XCTAssertTrue(app.buttons["Review"] .exists)
        XCTAssertTrue(app.buttons["Redo"] .exists)
        XCTAssertTrue(app.buttons["Undo"] .exists)
        
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testInfo() throws {
        // UI tests must launch the application that they test.
        let app = launchTestApp()
        ensureExists(text: "Streak", inApp: app)
        #if os(macOS)
        ensureExists(text: "Next Review", inApp: app)
        #endif
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testTaskLifeCycle() throws {
        let app = launchTestApp()
        let openList = app.staticTexts["open_LinkedList"]
        XCTAssertTrue(openList.exists)
        
        // Show all open elements by pressing on openList
        openList.tap()
         
        let addButton = app.buttons[""]
        
        // Expect list to be shown
        // Ensure app.staticTexts["open_LinkedList"] exists; it's the header to the list
        let listHeader = app.staticTexts["open_List"] // Adjust the identifier as needed
        XCTAssertTrue(listHeader.exists, "List header should be visible")
        
        // Find first task in list
        // This assumes tasks have identifiable accessibility labels or identifiers.
        let firstTask = app.staticTexts["firstTaskIdentifier"] // Use actual identifier for the first task
        XCTAssertTrue(firstTask.exists, "First task should be found")
        
        // Ensure I can swipe there
        firstTask.swipeLeft() // Or swipeRight(), depending on what you need to test
        
        // Ensure I can press a close button
        // Assuming "closeButtonIdentifier" is the accessibility identifier for the close button next to a task
        let closeButton = app.buttons["closeButtonIdentifier"]
        XCTAssertTrue(closeButton.exists, "Close button should be found")
        closeButton.tap()
        
        // Find and click on "closed_LinkedList"
        let closedList = app.staticTexts["closed_LinkedList"] // Adjust if your identifier is different
        closedList.tap()
        
        // Find previously closed task in list
        // Use a unique identifier for finding the task, which might require tracking task names or other identifiers
        let closedTask = app.staticTexts["closedTaskIdentifier"] // Use the identifier for the closed task
        XCTAssertTrue(closedTask.exists, "Closed task should be found in the list")
        
        // Swipe left on the closed task
        closedTask.swipeLeft()
        
        // Find destructive delete button
        let deleteButton = app.buttons["deleteButtonIdentifier"] // Use the actual identifier for your delete button
        XCTAssertTrue(deleteButton.exists, "Delete button should be found")
        
        // Press delete
        deleteButton.tap()
        
        // Ensure task is deleted
        XCTAssertFalse(closedTask.exists, "Task should be deleted")
    }

    
    @MainActor func testAppStartsEmpty() throws {
//        let container = sharedModelContainer(inMemory: true)
//
//        let sut = TaskManagerViewModel(modelContext: container.mainContext)
//
//        XCTAssertEqual(sut.items.count, 0, "There should be 0 movies when the app is first launched.")
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
