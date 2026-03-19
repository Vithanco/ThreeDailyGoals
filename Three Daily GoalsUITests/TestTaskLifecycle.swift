//
//  TestTaskLifecycle.swift
//  Three Daily GoalsUITests
//
//  Created by Claude on 21/02/2026.
//

import XCTest
import tdgCoreWidget

/// UI tests covering task visibility, navigation, creation, and state transitions.
///
/// Test data is deterministic: each run launches with the same in-memory store
/// (see `createDefaultTestData()`), so we can reliably look up known task titles.
///
/// Known test data:
/// - Priority:         "Try out Concept Maps"
/// - Open:             "Read 'The Goal' by Goldratt", "Read about Systems Thinking",
///                     "Transfer tasks from old task manager into this one",
///                     "Read about Structured Visual Thinking", "Tax Declaration"
/// - Pending Response: "Contact Vithanco Author regarding new map style",
///                     "Request Parking Permission"
/// - Dead:             "Read this", "Read this about Agile vs Waterfall"
@MainActor
final class TestTaskLifecycle: UITestBase {

    // MARK: - Default Test Data

    /// The priority task from test data should be visible on the home screen.
    func testDefaultPriorityTaskVisible() throws {
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))

        let task = findByLabel("Try out Concept Maps", in: app)
        XCTAssertTrue(
            task.waitForExistence(timeout: defaultTimeout),
            "Default priority task 'Try out Concept Maps' should be visible on home screen")
    }

    // MARK: - List Navigation

    /// Navigating to the Open list should show multiple expected tasks from test data.
    func testOpenListContainsExpectedTasks() throws {
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))

        navigateToList(named: "Open", in: app)

        // These tasks may be off-screen in the long list, so scroll to find them
        // "Tax Declaration" may be off-screen in the long list
        let task = scrollToFindByLabel("Tax Declaration", in: app)
        XCTAssertTrue(task.waitForExistence(timeout: shortTimeout))

        // "Tax Declaration" may be off-screen in the long list
        let task2 = scrollToFindByLabel("Read 'The Goal' by Goldratt", in: app)
        XCTAssertTrue(task2.waitForExistence(timeout: shortTimeout))

    }

    // MARK: - Task Detail View

    /// Tapping an open task should show its detail view with title field and action toolbar buttons.
    func testOpenTaskShowsDetailAndActionButtons() throws {
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))

        navigateToList(named: "Open", in: app)

        // "Tax Declaration" may be off-screen in the long list
        let task = scrollToFindByLabel("Tax Declaration", in: app)
        XCTAssertTrue(task.waitForExistence(timeout: shortTimeout))
        task.tap()

        // Title field should be visible and editable
        XCTAssertTrue(
            app.textFields["titleField"].waitForExistence(timeout: defaultTimeout),
            "Title field should be visible in task detail view")

        // Action buttons for an open task
        XCTAssertTrue(
            app.buttons["closeButton"].waitForExistence(timeout: shortTimeout),
            "Close button should be in task detail toolbar")
        XCTAssertTrue(
            app.buttons["pendingResponseButton"].waitForExistence(timeout: shortTimeout),
            "Pending Response button should be in task detail toolbar")
    }

    // MARK: - Task Creation

    /// Creating a new task should add it to the Open list with the entered title.
    func testCreateTaskAppearsInOpenList() throws {
        let uniqueTitle = "UITest_NewTask_\(Int.random(in: 10000...99999))"
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))

        navigateToList(named: "Open", in: app)

        let addButton = app.buttons["addTaskButton"].firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: shortTimeout))
        addButton.tap()

        // Clear the default title and type a unique one
        let titleField = app.textFields["titleField"].firstMatch
        XCTAssertTrue(titleField.waitForExistence(timeout: defaultTimeout))
        titleField.doubleTap()
        titleField.clearText()
        titleField.typeText(uniqueTitle)

        // On iOS, adding a task resets the navigation path; Back returns to the home screen.
        #if os(iOS)
            let backButton = app.buttons["Back"].firstMatch
            XCTAssertTrue(backButton.waitForExistence(timeout: shortTimeout))
            backButton.tap()
        #endif

        // Navigate back to the Open list
        navigateToList(named: "Open", in: app)

        // Newly created task has a recent changed date, placing it at the end of the list
        XCTAssertTrue(
            scrollToFindByLabel(uniqueTitle, in: app).waitForExistence(timeout: shortTimeout),
            "Newly created task '\(uniqueTitle)' should appear in Open list")
    }

    // MARK: - Task State Transitions

    /// Closing an open task should remove it from the Open list.
    /// Uses swipe actions on iOS, context menu on macOS.
    func testCloseRemovesFromOpenList() throws {
        let taskTitle = "Read about Systems Thinking"
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))

        navigateToList(named: "Open", in: app)

        let taskRow = scrollToFindByLabel(taskTitle, in: app)
        XCTAssertTrue(taskRow.waitForExistence(timeout: defaultTimeout), "'\(taskTitle)' should be in Open list")

        #if os(macOS)
            // Right-click to open context menu, then click Close
            taskRow.rightClick()
            let closeMenuItem = app.menuItems["Close"].firstMatch
            XCTAssertTrue(
                closeMenuItem.waitForExistence(timeout: shortTimeout), "Close menu item should appear in context menu")
            closeMenuItem.click()
        #else
            // Swipe left to reveal trailing swipe actions (Close, Kill, etc.)
            taskRow.swipeLeft()

            let closeButton = app.buttons["closeButton"].firstMatch
            XCTAssertTrue(
                closeButton.waitForExistence(timeout: shortTimeout), "Close button should appear after swipe-left")
            closeButton.tap()
        #endif

        // Verify the task is no longer in the Open list
        XCTAssertFalse(
            findByLabel(taskTitle, in: app).waitForExistence(timeout: shortTimeout),
            "'\(taskTitle)' should no longer appear in Open list after closing")
    }

    /// Prioritising an open task should move it to the priority list on the home screen.
    /// Uses swipe actions on iOS, context menu on macOS.
    func testPrioritiseMakesTaskAppearOnHomeScreen() throws {
        let taskTitle = "Read about Structured Visual Thinking"
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))

        navigateToList(named: "Open", in: app)

        let taskRow = scrollToFindByLabel(taskTitle, in: app)
        XCTAssertTrue(taskRow.waitForExistence(timeout: defaultTimeout), "'\(taskTitle)' should be in Open list")

        #if os(macOS)
            // Right-click to open context menu, then click Priority
            taskRow.rightClick()
            let priorityMenuItem = app.menuItems["Priority"].firstMatch
            XCTAssertTrue(
                priorityMenuItem.waitForExistence(timeout: shortTimeout),
                "Priority menu item should appear in context menu")
            priorityMenuItem.click()
        #else
            // Swipe right to reveal leading swipe actions (Prioritise).
            taskRow.swipeRight()

            let prioritiseButton = app.buttons["prioritiseButton"].firstMatch
            XCTAssertTrue(
                prioritiseButton.waitForExistence(timeout: shortTimeout),
                "Prioritise button should appear after swipe-right")
            prioritiseButton.tap()
        #endif

        // Navigate back to the home screen to verify the task appears in the priority list.
        // On iOS, tap Back to return to the home screen.
        // On macOS, the sidebar (with the priority list) is always visible.
        #if os(iOS)
            let backButton = app.buttons["Back"].firstMatch
            if backButton.waitForExistence(timeout: shortTimeout) {
                backButton.tap()
            }
        #endif

        XCTAssertTrue(
            findByLabel(taskTitle, in: app).waitForExistence(timeout: defaultTimeout),
            "Prioritised task should be visible on the home screen priority list")
    }
}
