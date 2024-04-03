//
//  AppLauncher.swift
//  Three Daily GoalsUITests
//
//  Created by Klaus Kneupner on 11/02/2024.
//

import XCTest

func launchTestApp() -> XCUIApplication{
    let app = XCUIApplication()
    app.launchArguments = ["enable-testing"]
    app.launch()
    return app
}


extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        // workaround for apple bug
        if let placeholderString = self.placeholderValue, placeholderString == stringValue {
            return
        }

        var deleteString = String()
        for _ in stringValue {
            deleteString += XCUIKeyboardKey.delete.rawValue
        }
        typeText(deleteString)
    }
}
