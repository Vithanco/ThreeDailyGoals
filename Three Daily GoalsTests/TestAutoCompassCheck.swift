//
//  TestAutoCompassCheck.swift
//  Three Daily GoalsTests
//

import Foundation
import Testing

@testable import Three_Daily_Goals
@testable import tdgCoreMain

@Suite
@MainActor
struct TestAutoCompassCheck {

    @Test
    func testAutoCompassCheckEnabled_DefaultIsTrue() {
        let appComponents = setupApp(isTesting: true, timeProvider: MockTimeProvider(fixedNow: Date()))
        #expect(appComponents.preferences.autoCompassCheckEnabled == true)
    }

    @Test
    func testAutoCompassCheckEnabled_PersistsSetting() {
        let appComponents = setupApp(isTesting: true, timeProvider: MockTimeProvider(fixedNow: Date()))
        let preferences = appComponents.preferences

        preferences.autoCompassCheckEnabled = false
        #expect(preferences.autoCompassCheckEnabled == false)

        preferences.autoCompassCheckEnabled = true
        #expect(preferences.autoCompassCheckEnabled == true)
    }

    @Test
    func testSetupCompassCheckNotification_WhenAutoDisabled_DoesNotScheduleTimer() {
        let timeProvider = MockTimeProvider(fixedNow: Date())
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider)
        let preferences = appComponents.preferences
        let compassCheckManager = appComponents.compassCheckManager

        // Ensure compass check is pending so timer would otherwise be scheduled
        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)
        #expect(!preferences.didCompassCheckToday)

        preferences.autoCompassCheckEnabled = false
        compassCheckManager.setupCompassCheckNotification()

        #expect(compassCheckManager.timer.timer == nil, "Timer must not be scheduled when auto compass check is disabled")
    }

    @Test
    func testSetupCompassCheckNotification_WhenAutoDisabled_CancelsExistingTimer() {
        let timeProvider = MockTimeProvider(fixedNow: Date())
        let appComponents = setupApp(isTesting: true, timeProvider: timeProvider)
        let preferences = appComponents.preferences
        let compassCheckManager = appComponents.compassCheckManager

        let currentInterval = timeProvider.getCompassCheckInterval()
        preferences.lastCompassCheck = currentInterval.start.addingTimeInterval(-3600)

        // Pretend a timer was already installed
        compassCheckManager.timer.setTimer(forWhen: Date().addingTimeInterval(3600)) {}
        #expect(compassCheckManager.timer.timer != nil)

        preferences.autoCompassCheckEnabled = false
        compassCheckManager.setupCompassCheckNotification()

        #expect(compassCheckManager.timer.timer == nil, "Existing timer must be cancelled when auto compass check is disabled")
    }
}
