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
