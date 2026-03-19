//
//  UITestBase.swift
//  Three Daily GoalsUITests
//
//  Created by Claude on 22/02/2026.
//

import XCTest
import tdgCoreWidget

/// Shared base class for all UI tests with common helpers, timeouts, and utilities.
@MainActor
class UITestBase: XCTestCase {

    // MARK: - Timeout Constants

    /// Default timeout for waiting on UI elements (5 seconds).
    let defaultTimeout: TimeInterval = 5.0

    /// Short timeout for elements that should appear quickly (2 seconds).
    let shortTimeout: TimeInterval = 2.0

    /// Long timeout for slow operations like app launch (5 seconds).
    let launchTimeout: TimeInterval = 5.0

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Element Finders

    /// Find an element by its displayed text/label (for items with UUID accessibilityIdentifier).
    ///
    /// Use this for task titles: their `NavigationLink` container has a UUID as
    /// `accessibilityIdentifier`, so subscript lookups like `app.staticTexts["Title"]`
    /// won't find them. Matching on `label` works because SwiftUI sets the label from
    /// the visible text content.
    /// Find an element whose accessibility label starts with `label`.
    ///
    /// SwiftUI combines all visible text in a view into the element's accessibility label.
    /// Tasks that show a due-date string (e.g. "Tax Declaration 2 days") won't match an
    /// exact `==` predicate, so we use `BEGINSWITH` to match the title prefix reliably.
    func findByLabel(_ label: String, in app: XCUIApplication) -> XCUIElement {
        let predicate = NSPredicate(format: "label BEGINSWITH %@", label)
        return app.descendants(matching: .any).matching(predicate).firstMatch
    }

    /// Find element by accessibility identifier (standard approach).
    func findFirst(identifier: String, in query: XCUIElementQuery) -> XCUIElement {
        let element = query.matching(identifier: identifier).firstMatch
        XCTAssertTrue(element.exists, "Could not find '\(identifier)'")
        return element
    }

    // MARK: - Navigation Helpers

    /// Navigate to a list by tapping its name on the home screen.
    func navigateToList(named name: String, in app: XCUIApplication) {
        // Try direct staticText match first (with wait for UI to render)
        let link = app.staticTexts[name].firstMatch
        if link.waitForExistence(timeout: defaultTimeout) {
            link.tap()
            return
        }

        // Try by accessibility identifier on the ListLabel
        let identifierMap: [String: String] = [
            "Open": "open_LinkedList",
            "Pending Response": "pending_LinkedList",
            "Closed": "closed_LinkedList",
            "Graveyard": "graveyard_LinkedList",
        ]
        if let identifier = identifierMap[name] {
            let element = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
            if element.waitForExistence(timeout: shortTimeout) {
                element.tap()
                return
            }
        }

        // Last resort: label predicate on any element
        let predicate = NSPredicate(format: "label CONTAINS %@", name)
        let matches = app.descendants(matching: .any).matching(predicate)
        if matches.firstMatch.waitForExistence(timeout: shortTimeout) {
            matches.firstMatch.tap()
            return
        }

        XCTFail("Could not find '\(name)' navigation link")
    }

    /// Scroll within a list to find an element that might be off-screen.
    ///
    /// SwiftUI `List` lazily loads cells, so off-screen elements don't exist in the
    /// accessibility hierarchy until scrolled into view. On iOS 16+ the backing view is
    /// a `UICollectionView`, which XCTest surfaces as a `collectionView` — NOT a `table`.
    /// This helper tries every scrollable container type before giving up.
    func scrollToFindByLabel(_ label: String, in app: XCUIApplication, maxScrolls: Int = 5) -> XCUIElement {
        let element = findByLabel(label, in: app)
        if element.waitForExistence(timeout: shortTimeout) {
            return element
        }

        // SwiftUI List renders as collectionView on iOS 16+, as table on older versions.
        // Try each container type; fall back to swiping the app window.
        let scrollTarget: XCUIElement = {
            if app.collectionViews.firstMatch.exists { return app.collectionViews.firstMatch }
            if app.tables.firstMatch.exists          { return app.tables.firstMatch }
            if app.scrollViews.firstMatch.exists     { return app.scrollViews.firstMatch }
            return app
        }()

        for _ in 0..<maxScrolls {
            scrollTarget.swipeUp()
            if element.waitForExistence(timeout: 1) {
                return element
            }
        }
        return element
    }

    /// Open search via the search button (preferred) or Cmd+F keyboard shortcut fallback.
    func openSearch(in app: XCUIApplication) {
        if let searchButton = findSearchButton(in: app) {
            searchButton.tap()
        } else {
            app.typeKey("f", modifierFlags: .command)
        }
    }

    /// Find the search button in the toolbar (handles both iPhone and iPad layouts).
    /// On macOS, toolbar buttons are not accessible to XCTest, so this returns nil.
    private func findSearchButton(in app: XCUIApplication) -> XCUIElement? {
        #if os(macOS)
        return nil
        #else
        let direct = app.buttons["searchButton"]
        if direct.waitForExistence(timeout: 1) {
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
        #endif
    }

    // MARK: - App Launcher

    /// Launch the app in test mode with deterministic test data.
    func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["enable-testing"]
        app.launch()
        return app
    }
}
