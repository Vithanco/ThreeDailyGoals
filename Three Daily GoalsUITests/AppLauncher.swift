//
//  AppLauncher.swift
//  Three Daily GoalsUITests
//
//  Created by Klaus Kneupner on 11/02/2024.
//

import XCTest

@MainActor
func launchTestApp() -> XCUIApplication {
    let app = XCUIApplication()

    // Ensure we run in testing mode and disable animations to speed up tests
    var args = app.launchArguments
    if !args.contains("-ui-testing") { args.append("-ui-testing") }
    if !args.contains("-ApplePersistenceIgnoreState") { args.append("-ApplePersistenceIgnoreState") }
    if !args.contains("-UITestsDisableAnimations") { args.append("-UITestsDisableAnimations") }
    app.launchArguments = args

    // Launch the app
    app.launch()

    // Wait for the process to be running and accessibility to be ready
    waitForAccessibility(in: app, timeout: 10)

    return app
}

/// Waits until the target app has loaded accessibility and is responsive.
@discardableResult
private func waitForAccessibility(in app: XCUIApplication, timeout: TimeInterval) -> Bool {
    let start = Date()

    // First, wait for the process to exist and be running
    while app.state != .runningForeground && Date().timeIntervalSince(start) < timeout {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
    }

    guard app.state == .runningForeground else { return false }

    // Next, poll for accessibility readiness by checking a stable element like the first window
    let window = app.windows.element(boundBy: 0)

    // Try both existence and hittability over a short period
    while Date().timeIntervalSince(start) < timeout {
        if window.exists { return true }
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
    }

    // As a fallback, try a brief interaction to trigger accessibility server initialization
    if !window.exists {
        app.activate()
    }

    return window.waitForExistence(timeout: max(0, timeout - Date().timeIntervalSince(start)))
}

extension XCUIElement {
    func clearText() {

        if self.value as? String == nil {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }

        // Repeatedly delete text as long as there is something in the text field.
        // This is required to clear text that does not fit in to the textfield and is partially hidden initally.
        // Important to check for placeholder value, otherwise it gets into an infinite loop.
        while let stringValue = self.value as? String, !stringValue.isEmpty,
            stringValue != self.placeholderValue
        {
            // Move the cursor to the end of the text field
            let lowerRightCorner = self.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.9))
            lowerRightCorner.tap()
            let delete = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
            self.typeText(delete)
        }

    }
}
