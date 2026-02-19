//
//  TestSearchUI.swift
//  Three Daily GoalsUITests
//
//  Created by Claude on 19/02/2026.
//

import XCTest

/// UI tests for the search feature.
///
/// Note: These tests are designed for iOS (iPhone/iPad) simulator.
/// On macOS, the SwiftUI toolbar buttons are not accessible to the XCTest
/// framework (this is a pre-existing limitation that affects all UI tests
/// in this project on macOS).
@MainActor
final class TestSearchUI: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    /// Find the search button, trying toolbar lookup on iPad
    private func findSearchButton(in app: XCUIApplication) -> XCUIElement? {
        let direct = app.buttons["searchButton"]
        if direct.waitForExistence(timeout: 3) {
            return direct
        }
        // Try inside toolbars (iPad)
        let toolbars = app.toolbars
        for i in 0..<toolbars.count {
            let toolbar = toolbars.element(boundBy: i)
            let btn = toolbar.buttons["searchButton"]
            if btn.exists {
                return btn
            }
        }
        return nil
    }

    /// Open search using Cmd+F keyboard shortcut (works on both macOS and iPad with keyboard)
    private func openSearchViaKeyboard(in app: XCUIApplication) {
        app.typeKey("f", modifierFlags: .command)
    }

    // MARK: - Search Button Visibility

    func testSearchButtonExists() throws {
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        sleep(2)

        let searchButton = findSearchButton(in: app)
        XCTAssertNotNil(searchButton, "Search button should exist in the toolbar")
    }

    // MARK: - Search via Keyboard Shortcut

    func testCmdFOpensSearch() throws {
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        sleep(2)

        // Use Cmd+F to open search
        openSearchViaKeyboard(in: app)

        let searchField = app.textFields["Search tasks..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Search field should appear after Cmd+F")
    }

    // MARK: - Search Activation

    func testSearchOpensSearchField() throws {
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        sleep(2)

        // Try button first, fall back to keyboard shortcut
        if let searchButton = findSearchButton(in: app) {
            searchButton.tap()
        } else {
            openSearchViaKeyboard(in: app)
        }

        let searchField = app.textFields["Search tasks..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Search text field should appear after opening search")
    }

    // MARK: - Search Dismissal

    func testDoneButtonClosesSearch() throws {
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        sleep(2)

        openSearchViaKeyboard(in: app)

        let searchField = app.textFields["Search tasks..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Search field should appear")

        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3), "Done button should be visible during search")
        doneButton.tap()

        sleep(1)
        XCTAssertFalse(searchField.exists, "Search field should be dismissed after tapping Done")
    }

    // MARK: - Search Input

    func testTypingInSearchField() throws {
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        sleep(2)

        openSearchViaKeyboard(in: app)

        let searchField = app.textFields["Search tasks..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        searchField.tap()
        searchField.typeText("test")
        sleep(1)

        let fieldValue = searchField.value as? String
        XCTAssertEqual(fieldValue, "test", "Search field should contain the typed text")
    }

    // MARK: - Search Prompt

    func testEmptySearchShowsPrompt() throws {
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        sleep(2)

        openSearchViaKeyboard(in: app)

        let prompt = app.staticTexts["Type to search across all tasks"]
        XCTAssertTrue(prompt.waitForExistence(timeout: 5), "Should show search prompt when field is empty")
    }

    // MARK: - Clear Button

    func testClearButtonAppearsWhenTextEntered() throws {
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        sleep(2)

        openSearchViaKeyboard(in: app)

        let searchField = app.textFields["Search tasks..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        searchField.tap()
        searchField.typeText("query")
        sleep(1)

        let clearButton = app.buttons["Clear search text"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 3), "Clear button should appear when search text is not empty")
    }

    func testClearButtonClearsText() throws {
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        sleep(2)

        openSearchViaKeyboard(in: app)

        let searchField = app.textFields["Search tasks..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        searchField.tap()
        searchField.typeText("query")
        sleep(1)

        let clearButton = app.buttons["Clear search text"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 3))
        clearButton.tap()
        sleep(1)

        let fieldValue = searchField.value as? String
        let isEmpty = fieldValue == nil || fieldValue == "" || fieldValue == "Search tasks..."
        XCTAssertTrue(isEmpty, "Search field should be cleared, got: \(fieldValue ?? "nil")")
    }

    // MARK: - Search Results

    func testNoResultsMessageDisplayed() throws {
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        sleep(2)

        openSearchViaKeyboard(in: app)

        let searchField = app.textFields["Search tasks..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        searchField.tap()
        searchField.typeText("xyznonexistent123456")
        sleep(1)

        let noResults = app.staticTexts["No results found"]
        XCTAssertTrue(noResults.waitForExistence(timeout: 5), "Should show 'No results found' for non-matching query")
    }
}
