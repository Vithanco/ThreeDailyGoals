//
//  Three_Daily_GoalsUITests.swift
//  Three Daily GoalsUITests
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import XCTest

@testable import Three_Daily_Goals

// this is not working for some reason see https://stackoverflow.com/questions/33755019/linker-error-when-accessing-application-module-in-ui-tests-in-xcode-7-1
//@testable import Three_Daily_Goals

func ensureExists(text: String, inApp: XCUIApplication) {
    let predicate = NSPredicate(format: "value CONTAINS '\(text)'")
    let elementQuery = inApp.staticTexts.containing(predicate)
    XCTAssertTrue(elementQuery.count > 0, "couldn't find \(text)")
}

@MainActor final class Three_Daily_GoalsUITests: XCTestCase {

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
        XCTAssertTrue(app.buttons["Add Task"].exists)
        XCTAssertTrue(app.buttons["compassCheckButton"].exists)
        #if os(iOS)
            XCTAssertTrue(app.buttons["Redo"].exists)
            XCTAssertTrue(app.buttons["Undo"].exists)
        #endif
        #if os(macOS)
            XCTAssertTrue(app.menuItems["Redo"].exists)
            XCTAssertTrue(app.menuItems["Undo"].exists)
        #endif
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testInfo() throws {
        // UI tests must launch the application that they test.
        let app = launchTestApp()
        if isLargeDevice {
            ensureExists(text: "Streak", inApp: app)
        }
        #if os(macOS)
            ensureExists(text: "today", inApp: app)
        #endif
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func findFirst(string: String, whereToLook: XCUIElementQuery) -> XCUIElement {
        let list = whereToLook.matching(identifier: string)
        XCTAssertTrue(list.count > 0, "couldn't find \(string)")
        return list.element(boundBy: 0)
    }

    @MainActor
    func testScrolling() async throws {
        let app = launchTestApp()
        let listOpenButton = findFirst(string: "open_LinkedList", whereToLook: app.staticTexts)
        listOpenButton.tap()
        let openList = findFirst(string:"scrollView_open_List", whereToLook: app.descendants(matching: .any))
       // openList.tap()
        openList.swipeUp()
    }

    @MainActor
    func testTaskLifeCycle() async throws {
        let testString = "test title 45#"
        //
        let app = launchTestApp()
        let listOpenButton = findFirst(string: "open_LinkedList", whereToLook: app.staticTexts)
        listOpenButton.tap()

        let addButton = findFirst(string: "addTaskButton", whereToLook: app.buttons)
        addButton.tap()

        let title = findFirst(string: "titleField", whereToLook: app.textFields)
        XCTAssertNotNil(title)
        title.doubleTap()
        title.clearText()
        title.typeText(testString)
        let submit = findFirst(string: "addTaskWithTitleButton", whereToLook: app.buttons)
        submit.tap()

        #if os(iOS)
            let back = findFirst(string: "Back", whereToLook: app.buttons)
            back.tap()
        #endif
        listOpenButton.tap()

        let openList = findFirst(string:"scrollView_open_List", whereToLook: app.descendants(matching: .any))
        XCTAssertNotNil(openList)
        openList.swipeUp()

        let testTask = findFirst(string: testString, whereToLook: app.staticTexts)
        XCTAssertTrue(testTask.exists, "First task should be found")

        testTask.tap()

        let closeButton = findFirst(string: "closeButton", whereToLook: app.buttons)
        XCTAssertTrue(closeButton.exists, "Close button should be found")
        closeButton.tap()
        #if os(iOS)
            back.tap()
            back.tap()
        #endif
        let listClosed = app.staticTexts["closed_LinkedList"]
        listClosed.tap()
        let closedTask = findFirst(string: testString, whereToLook: app.staticTexts)
        XCTAssertNotNil(closedTask)
        #if os(macOS)
       closedTask.tap()
        #endif
        closedTask.swipeLeft()

        let deleteButton = app.buttons["deleteButton"]
        XCTAssertTrue(deleteButton.exists, "Delete button should be found")
        deleteButton.tap()

        XCTAssertTrue(!closedTask.exists, "Task should be deleted")
        //
    }

    @MainActor func testAppStartsEmpty() throws {
        //        let container = sharedModelContainer(inMemory: true)
        //
        //        let sut = TaskManagerViewModel(modelContext: container.mainContext)
        //
        //        XCTAssertTrue(sut.items.count, 0, "There should be 0 movies when the app is first launched.")
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                let _ = launchTestApp()
            }
        }
    }
}
