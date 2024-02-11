//
//  Three_Daily_GoalsUITests.swift
//  Three Daily GoalsUITests
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import XCTest
//@testable import Three_Daily_Goals

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
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Add Task"] .exists)
        XCTAssertTrue(app.buttons["Review"] .exists)
        XCTAssertTrue(app.buttons["Redo"] .exists)
        XCTAssertTrue(app.buttons["Undo"] .exists)
        
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testInfo() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        ensureExists(text: "Streak", inApp: app)
        #if os(macOS)
        ensureExists(text: "Next Review", inApp: app)
        #endif
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testSwipe() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.["Add Task"] .exists)
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
