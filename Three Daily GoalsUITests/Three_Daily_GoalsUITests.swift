//
//  Three_Daily_GoalsUITests.swift
//  Three Daily GoalsUITests
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import XCTest
import tdgCoreTest
import tdgCoreWidget

@testable import Three_Daily_Goals

@MainActor
func ensureExists(text: String, inApp: XCUIApplication) {
    let predicate = NSPredicate(format: "value CONTAINS %@", text)
    let elementQuery = inApp.staticTexts.containing(predicate)
    XCTAssertTrue(elementQuery.count > 0, "couldn’t find \(text)")
}

@MainActor final class Three_Daily_GoalsUITests: UITestBase {

    @MainActor
    func testButtons() async throws {
        let app = launchTestApp()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))

        // Check for add task button - it should be visible in the main toolbar
        let addTaskButton = app.buttons["addTaskButton"]
        if !addTaskButton.exists {
            // If not found as a standalone button, try looking in the toolbar
            let toolbar = app.toolbars.firstMatch
            if toolbar.exists {
                let toolbarButton = toolbar.buttons["addTaskButton"]
                XCTAssertTrue(toolbarButton.exists, "Add Task button should be visible in toolbar")
            } else {
                XCTAssertTrue(addTaskButton.exists, "Add Task button should be visible")
            }
        }

        // Check for compass check button - it should be visible in the main toolbar
        let compassCheckButton = app.buttons["compassCheckButton"]
        XCTAssertTrue(compassCheckButton.exists, "Compass Check button should be visible")

        #if os(iOS)
            let undoButton = app.buttons["undoButton"]
            let redoButton = app.buttons["redoButton"]
            XCTAssertTrue(undoButton.exists, "Undo button should be visible (may be disabled)")
            XCTAssertTrue(redoButton.exists, "Redo button should be visible (may be disabled)")
        #endif
        #if os(macOS)
            XCTAssertTrue(app.menuItems["Redo"].exists)
            XCTAssertTrue(app.menuItems["Undo"].exists)
        #endif
    }

    func testInfo() throws {
        let app = launchTestApp()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))

        if isLargeDevice {
            // Look for "Today:" text which is actually displayed in the streak view
            ensureExists(text: "Today:", inApp: app)
        }
        #if os(macOS)
            ensureExists(text: "Today:", inApp: app)
        #endif
    }

    @MainActor
    func testScrolling() async throws {
        let app = launchTestApp()
        navigateToList(named: "Open", in: app)

        let openList = app.descendants(matching: .any).matching(identifier: "scrollView_open_List").firstMatch
        XCTAssertTrue(openList.waitForExistence(timeout: shortTimeout))
        openList.swipeUp()
    }

    @MainActor
    func testTaskLifeCycle() async throws {
        let testString = "test title 45#"
        let app = launchTestApp()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))

        navigateToList(named: "Open", in: app)

        let addButton = app.buttons["addTaskButton"].firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: shortTimeout))
        addButton.tap()

        let title = app.textFields["titleField"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: defaultTimeout))
        title.doubleTap()
        title.clearText()
        title.typeText(testString)

        // Adding a new task resets the navigation path to root on iOS,
        // so tapping Back returns to the home screen (not the Open list).
        #if os(iOS)
            let back = app.buttons["Back"].firstMatch
            XCTAssertTrue(back.waitForExistence(timeout: shortTimeout))
            back.tap()
        #endif

        // Navigate back to the Open list
        navigateToList(named: "Open", in: app)

        let openList = app.descendants(matching: .any).matching(identifier: "scrollView_open_List").firstMatch
        XCTAssertTrue(openList.waitForExistence(timeout: defaultTimeout), "Open list should be visible")

        // The created task has a recent date, so it may be at the bottom of the list
        let taskElement = scrollToFindByLabel(testString, in: app)
        XCTAssertTrue(
            taskElement.waitForExistence(timeout: shortTimeout),
            "Created task '\(testString)' should appear in Open list")
    }

    @MainActor
    func testEnsureButtonsVisible() async throws {
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))

        // --- Main screen: standard toolbar buttons ---
        XCTAssertTrue(
            app.buttons["addTaskButton"].waitForExistence(timeout: shortTimeout),
            "Add Task button should be visible in toolbar")
        XCTAssertTrue(
            app.buttons["compassCheckButton"].waitForExistence(timeout: shortTimeout),
            "Compass Check button should be visible in toolbar")
        XCTAssertTrue(
            app.buttons["searchButton"].waitForExistence(timeout: shortTimeout),
            "Search button should be visible in toolbar")
        XCTAssertTrue(
            app.buttons["undoButton"].waitForExistence(timeout: shortTimeout),
            "Undo button should be visible in toolbar")
        XCTAssertTrue(
            app.buttons["redoButton"].waitForExistence(timeout: shortTimeout),
            "Redo button should be visible in toolbar")

        // --- Task detail view: item toolbar buttons ---
        // Navigate to Open list, then open a known task
        navigateToList(named: "Open", in: app)

        // Task NavigationLinks use a UUID accessibilityIdentifier, so match by label.
        // "Tax Declaration" may be off-screen in the long list.
        let taskText = scrollToFindByLabel("Tax Declaration", in: app)
        XCTAssertTrue(taskText.waitForExistence(timeout: shortTimeout), "Tax Declaration should be in Open list")
        taskText.tap()

        // An open task should have close and pending-response buttons in its toolbar
        XCTAssertTrue(
            app.buttons["closeButton"].waitForExistence(timeout: shortTimeout),
            "Close button should be visible in task detail toolbar")
        XCTAssertTrue(
            app.buttons["pendingResponseButton"].waitForExistence(timeout: shortTimeout),
            "Pending Response button should be visible in task detail toolbar")
    }
}
