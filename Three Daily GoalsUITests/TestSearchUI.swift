//
//  TestSearchUI.swift
//  Three Daily GoalsUITests
//
//  Created by Claude on 19/02/2026.
//

import XCTest
import tdgCoreWidget

/// UI tests for the search feature.
///
/// Note: These tests are designed for iOS (iPhone/iPad) simulator.
/// On macOS, the SwiftUI toolbar buttons are not accessible to the XCTest
/// framework (this is a pre-existing limitation that affects all UI tests
/// in this project on macOS).
@MainActor
final class TestSearchUI: UITestBase {

    // MARK: - Search Button Visibility

    func testSearchButtonExists() throws {
        #if os(macOS)
        throw XCTSkip("Search button not accessible in macOS UI tests")
        #endif
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))

        let searchButton = app.buttons["searchButton"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: shortTimeout), "Search button should exist in the toolbar")
    }

    // MARK: - Search via Keyboard Shortcut (iPad/macOS only)

    func testCmdFOpensSearch() throws {
        try XCTSkipIf(!isLargeDevice, "Cmd+F keyboard shortcut only supported on iPad/macOS")

        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))

        app.typeKey("f", modifierFlags: .command)

        let searchField = app.textFields["Search tasks..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: defaultTimeout), "Search field should appear after Cmd+F")
    }

    // MARK: - Search Activation

    func testSearchOpensSearchField() throws {
        #if os(macOS)
        throw XCTSkip("Search UI not fully testable in macOS UI tests (toolbar buttons not accessible)")
        #endif
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))

        openSearch(in: app)

        let searchField = app.textFields["Search tasks..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: defaultTimeout), "Search text field should appear after opening search")
    }

    // MARK: - Search Dismissal

    func testDoneButtonClosesSearch() throws {
        #if os(macOS)
        throw XCTSkip("Search UI not fully testable in macOS UI tests (toolbar buttons not accessible)")
        #endif
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))

        openSearch(in: app)

        let searchField = app.textFields["Search tasks..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: defaultTimeout), "Search field should appear")

        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: shortTimeout), "Done button should be visible during search")
        doneButton.tap()

        // Wait for navigation pop animation to complete
        XCTAssertFalse(searchField.waitForExistence(timeout: defaultTimeout), "Search field should be dismissed after tapping Done")
    }

    // MARK: - Search Input

    func testTypingInSearchField() throws {
        #if os(macOS)
        throw XCTSkip("Search UI not fully testable in macOS UI tests (toolbar buttons not accessible)")
        #endif
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))

        openSearch(in: app)

        let searchField = app.textFields["Search tasks..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: defaultTimeout))

        searchField.tap()
        searchField.typeText("test")

        let fieldValue = searchField.value as? String
        XCTAssertEqual(fieldValue, "test", "Search field should contain the typed text")
    }

    // MARK: - Search Prompt

    func testEmptySearchShowsPrompt() throws {
        #if os(macOS)
        throw XCTSkip("Search UI not fully testable in macOS UI tests (toolbar buttons not accessible)")
        #endif
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))

        openSearch(in: app)

        // The search field must appear before the prompt is shown
        let searchField = app.textFields["Search tasks..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: defaultTimeout), "Search field should appear")

        let prompt = app.staticTexts["Type to search across all tasks"]
        XCTAssertTrue(prompt.waitForExistence(timeout: defaultTimeout), "Should show search prompt when field is empty")
    }

    // MARK: - Clear Button

    func testClearButtonAppearsWhenTextEntered() throws {
        #if os(macOS)
        throw XCTSkip("Search UI not fully testable in macOS UI tests (toolbar buttons not accessible)")
        #endif
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))

        openSearch(in: app)

        let searchField = app.textFields["Search tasks..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: defaultTimeout))

        searchField.tap()
        searchField.typeText("query")

        let clearButton = app.buttons["Clear search text"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: shortTimeout), "Clear button should appear when search text is not empty")
    }

    func testClearButtonClearsText() throws {
        #if os(macOS)
        throw XCTSkip("Search UI not fully testable in macOS UI tests (toolbar buttons not accessible)")
        #endif
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))

        openSearch(in: app)

        let searchField = app.textFields["Search tasks..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: defaultTimeout))

        searchField.tap()
        searchField.typeText("query")

        let clearButton = app.buttons["Clear search text"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: shortTimeout))
        clearButton.tap()

        // After clearing, the empty-search prompt should reappear (indicating text was cleared)
        let emptyPrompt = app.staticTexts["Type to search across all tasks"]
        XCTAssertTrue(
            emptyPrompt.waitForExistence(timeout: defaultTimeout),
            "Empty search prompt should reappear after clearing text")
    }

    // MARK: - Search Results

    func testNoResultsMessageDisplayed() throws {
        #if os(macOS)
        throw XCTSkip("Search UI not fully testable in macOS UI tests (toolbar buttons not accessible)")
        #endif
        let app = launchTestApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: launchTimeout))

        openSearch(in: app)

        let searchField = app.textFields["Search tasks..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: defaultTimeout))

        searchField.tap()
        searchField.typeText("xyznonexistent123456")

        let noResults = app.staticTexts["No results found"]
        XCTAssertTrue(noResults.waitForExistence(timeout: defaultTimeout), "Should show 'No results found' for non-matching query")
    }
}
