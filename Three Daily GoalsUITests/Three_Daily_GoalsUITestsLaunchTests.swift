//
//  Three_Daily_GoalsUITestsLaunchTests.swift
//  Three Daily GoalsUITests
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import XCTest

final class Three_Daily_GoalsUITestsLaunchTests: UITestBase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    @MainActor
    func testLaunch() throws {
        let app = launchTestApp()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
