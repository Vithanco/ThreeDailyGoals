//
//  AppLauncher.swift
//  Three Daily GoalsUITests
//
//  Created by Klaus Kneupner on 11/02/2024.
//

import XCTest

var app: XCUIApplication!

func launchTestApp() -> XCUIApplication {
    app = XCUIApplication()
    app.launchArguments = ["enable-testing"]
    app.launch()
    return app
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
